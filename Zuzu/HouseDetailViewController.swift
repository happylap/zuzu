//
//  HouseDetailViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftyJSON
import MessageUI
import MWPhotoBrowser
import MarqueeLabel

class HouseDetailViewController: UIViewController {
    
    struct ViewTransConst {
        static let displayHouseOnMap:String = "displayHouseOnMap"
        static let displayHouseSource:String = "displayHouseSource"
    }
    
    @IBOutlet weak var contactBarView: HouseDetailContactBarView!
    @IBOutlet weak var tableView: UITableView!
    
    let houseTypeLabelMaker = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
    var photos = [MWPhoto]()
    
    var houseItem:HouseItem?
    
    ///The full house detail in AnyObject
    var houseItemDetail: AnyObject?
    
    struct Const {
        static let SECTION_NUM:Int = 1
    }
    
    enum CellIdentifier: String {
        case HouseDetailTitleCell = "houseDetailTitleCell"
        case RightDetailCell = "rightDetailCell"
        case AddressCell = "addressCell"
        case ExpandableHeaderCell = "expandableHeaderCell"
        case ExpandableContentCell = "expandableContentCell"
        case EmptyCell = "emptyCell"
    }
    
    
    struct CellInfo {
        let cellIdentifier:CellIdentifier
        var hidden:Bool
        var cellHeight:CGFloat
        let handler: (UITableViewCell) -> ()
    }
    
    let cellIdentifier = "houseDetailTitleCell"
    
    var tableRows:[Int: CellInfo]!
    
    private func fetchHouseDetail(houseItem: HouseItem) {
        
        LoadingSpinnerOverlay.shared.showOverlayOnView(self.view)
        
        HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
            
            LoadingSpinnerOverlay.shared.hideOverlayView()
            
            if let error = error {
                NSLog("Cannot get remote data %@", error.localizedDescription)
                return
            }
            
            if let result = result {
                self.houseItemDetail = result
                
                ///Reload Table View
                self.tableView.reloadData()
                
                ///Configure Views On Data Loaded
                self.configureViewsOnDataLoaded()
            }
        }
    }
    
    private func setupTableCells() {
        
        tableRows = [
            0:CellInfo(cellIdentifier: .HouseDetailTitleCell, hidden: false, cellHeight: 213, handler: { (cell : UITableViewCell) -> () in
                if let cell = cell as? HouseDetailTitleViewCell {
                    
                    cell.houseTitleLabel.text = self.houseItem?.title
                    
                    let placeholderImg = UIImage(named: "house_img")
                    
                    if let imgString = self.houseItem?.imgList?.first,
                        let imgUrl = NSURL(string: imgString){
                            
                            cell.titleImage.af_setImageWithURL(imgUrl, placeholderImage: placeholderImg, filter: nil, imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                                NSLog("Img loading done, status = \(response)")
                            }
                            
                    }
                }
            }),
            1:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                        cell.leftInfoText.text = "\(houseItem.price) 月/元"
                        cell.rightInfoText.text = "\(houseItem.size) 坪"
                    }
                }
            }),
            2:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                        let houseType = self.houseTypeLabelMaker!.fromCodeForField("house_type", code: houseItem.houseType,defaultValue: "")
                        let purposeType = self.houseTypeLabelMaker!.fromCodeForField("purpose_type", code: houseItem.purposeType, defaultValue: "")
                        
                        cell.rightInfoText.text = "\(houseType) / \(purposeType)"
                    }
                    
                    if let houseDetail = self.houseItemDetail {
                        cell.leftInfoText.text = "隔間:" + (houseDetail.valueForKey("wall_mtl") as? String ?? "—")
                    }
                }
            }),
            3:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        let floor = (houseDetail.valueForKey("floor") as? [Int] ?? [0]).first
                        let total_floor = houseDetail.valueForKey("total_floor") as? Int ?? 0
                        
                        cell.leftInfoText.text = "樓層: \(floor!)/\(total_floor)"
                        
                        let room = houseDetail.valueForKey("num_bedroom") as? Int ?? 0
                        let ting = houseDetail.valueForKey("num_ting") as? Int ?? 0
                        
                        if(room != 0 || ting != 0) {
                            cell.rightInfoText.text = "\(room)房\(ting)廳"
                        } else {
                            cell.rightInfoText.text = ""
                        }
                    }
                }
            }),
            4:CellInfo(cellIdentifier: .AddressCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailAddressCell {
                    if let houseItem = self.houseItem {
                        cell.addressLabel.text = houseItem.addr
                        //                        cell.mapIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onMapButtonTouched:")))
                    }
                }
            }),
            5:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "提供物品"
                }
            }),
            6:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: true, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString:String = ""
                        
                        if let furnitureList = houseDetail.valueForKey("furniture") as? [Int]  {
                            
                            let furnitureStringList = furnitureList.map { (code) -> String in
                                self.houseTypeLabelMaker!.fromCodeForField("furniture", code: code, defaultValue: "—")
                            }
                            
                            resultString += furnitureStringList.joinWithSeparator("; ") + "\n"
                        }
                        
                        if let facilityList = houseDetail.valueForKey("facility") as? [Int]  {
                            let facilityStringList = facilityList.map { (code) -> String in
                                self.houseTypeLabelMaker!.fromCodeForField("facility", code: code, defaultValue: "—")
                            }
                            
                            resultString += facilityStringList.joinWithSeparator("; ")
                        }
                        
                        cell.contentLabel.text = resultString
                    }
                    
                }
            }),
            7:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "生活機能"
                }
            }),
            8:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: true, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString:String = ""
                        
                        if let surroundingList = houseDetail.valueForKey("surrounding") as? [Int]  {
                            
                            let surroundingStringList = surroundingList.map { (code) -> String in
                                self.houseTypeLabelMaker!.fromCodeForField("surrounding", code: code, defaultValue: "—")
                            }
                            
                            resultString += surroundingStringList.joinWithSeparator("; ") + "\n\n"
                        }
                        
                        var transportationList = [String]()
                        
                        if let bus = houseDetail.valueForKey("nearby_bus") as? [String] {
                            transportationList.appendContentsOf(bus)
                        }
                        
                        if let train = houseDetail.valueForKey("nearby_train") as? [String] {
                            transportationList.appendContentsOf(train)
                        }
                        
                        if let mrt = houseDetail.valueForKey("nearby_mrt") as? [String] {
                            transportationList.appendContentsOf(mrt)
                        }
                        
                        if let thsr = houseDetail.valueForKey("nearby_thsr") as? [String] {
                            transportationList.appendContentsOf(thsr)
                        }
                        
                        resultString += transportationList.joinWithSeparator("; ")
                        
                        cell.contentLabel.text = resultString
                    }
                    
                }
            }),
            9:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "租屋限制"
                }
            }),
            10:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: true, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        var resultString:String = ""
                        
                        //Profile
                        if let profiles = houseDetail.valueForKey("restr_profile") as? [String] {
                            
                            let profilesStringList = profiles.map { (code) -> String in
                                self.houseTypeLabelMaker!.fromCodeForField("restr_profile", code: Int(code)!, defaultValue: "—")
                            }
                            
                            resultString += profilesStringList.joinWithSeparator("; ") + "\n"
                        }
                        
                        var restrictionList = [String]()
                        //Sex
                        if let sex = houseDetail.valueForKey("restr_sex") as? Int {
                            if let sexString = self.houseTypeLabelMaker!.fromCodeForField("restr_sex", code: sex) {
                                restrictionList.append("限\(sexString)性")
                            }
                        }
                        
                        //Allow Pet
                        if let allow_pet = houseDetail.valueForKey("allow_pet") as? Bool {
                            
                            restrictionList.append( (allow_pet ? "可養寵物" : "不可養寵物"))
                        }
                        
                        //Allow Cooking
                        if let allow_cooking = houseDetail.valueForKey("allow_cooking") as? Bool {
                            
                            restrictionList.append( (allow_cooking ? "可開伙" : "不可養開伙"))
                        }
                        
                        resultString += restrictionList.joinWithSeparator("; ") + "\n"
                        
                        //Shortest Lease
                        if let lease_period = houseDetail.valueForKey("shortest_lease") as? Int {
                            resultString += "最短租期: \(lease_period)天"
                        }
                        
                        cell.contentLabel.text = resultString
                    }
                }
            }),
            11:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "其他資訊"
                }
            }),
            12:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: true, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    cell.contentLabel.adjustsFontSizeToFitWidth = false
                    //cell.contentLabel.numberOfLines = 0
                    
                    if let houseDetail = self.houseItemDetail {
                        var resultString:String = ""
                        
                        cell.contentLabel.preferredMaxLayoutWidth = cell.contentView.frame.width - 2 * 8
                        
                        //Desc
                        if let desc = houseDetail.valueForKey("desc") as? String {
                            
                            resultString += desc
                        }
                        NSLog("Desc Set: %@", resultString)
                        cell.contentLabel.text = resultString
                        cell.contentLabel.sizeToFit()
                        
                        NSLog("Frame Height: %f", cell.contentLabel.frame.height)
                    }
                }
            })
        ]
    }
    
    private func alertMailAppNotReady() {
        // Initialize Alert View
        let alertView = UIAlertView(
            title: "找不到預設的郵件應用",
            message: "找不到預設的郵件應用，請到 [設定] > [郵件、聯絡資訊、行事曆] > 帳號，確認您的郵件帳號已經設置完成",
            delegate: self,
            cancelButtonTitle: "知道了")
        
        // Show Alert View
        alertView.show()
    }
    
    private func configureViewsOnDataLoaded() {
        
        ///Configure Contact Bar View
        self.configureContactBarView()
    }
    
    private func configureTableView() {
        
        //Configure cell height
        tableView.estimatedRowHeight = 213//tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        tableView.dataSource = self
        tableView.delegate = self
        
        self.tableView.setNeedsLayout()
        self.tableView.layoutIfNeeded()
        
        //Remove extra cells with some padding height
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 165))
    }
    
    private func configureNavigationBarItems() {
        
        ///Prepare custom UIButton for UIBarButtonItem
        let gotoSourceButton: UIButton = UIButton(type: UIButtonType.Custom)
        gotoSourceButton.setImage(UIImage(named: "web_n"), forState: UIControlState.Normal)
        gotoSourceButton.addTarget(self, action: "gotoSourceButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
        gotoSourceButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let shareButton: UIButton = UIButton(type: UIButtonType.Custom)
        shareButton.setImage(UIImage(named: "share_n"), forState: UIControlState.Normal)
        shareButton.addTarget(self, action: "shareButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
        shareButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let collectButton: UIButton = UIButton(type: UIButtonType.Custom)
        collectButton.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
        collectButton.addTarget(self, action: "collectButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
        collectButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        /// From right to left
        self.navigationItem.setRightBarButtonItems(
            [
                UIBarButtonItem(customView: collectButton),
                UIBarButtonItem(customView: shareButton),
                UIBarButtonItem(customView: gotoSourceButton)
            ],
            animated: false)
    }
    
    private func initContactBarView() {
        contactBarView.contactName.text = "———"
        
        contactBarView.contactByMailButton.hidden = true
        
        contactBarView.contactByPhoneButton.hidden = true
    }
    
    private func configureContactBarView() {
        if let houseDetail = self.houseItemDetail {
            contactBarView.contactName.text = houseDetail.valueForKey("agent") as? String ?? "———"
            
            contactBarView.contactByMailButton
                .addTarget(self, action: "contactByMailButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
            contactBarView.contactByMailButton.hidden = false
            
            if let _ = houseDetail.valueForKey("phone") as? [String] {
                contactBarView.contactByPhoneButton
                    .addTarget(self, action: "contactByPhoneButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                contactBarView.contactByPhoneButton.hidden = false
            }
        }
    }
    
    ///Action Handlers
    
    func contactByMailButtonTouched(sender: UIButton) {
        
        /* Another way to allow sending mail by lauching default mail App
        * Our app will be suspended, and the user woulden't have a way to return to our App
        if let url = NSURL(string: "mailto:jon.doe@mail.com") {
        UIApplication.sharedApplication().openURL(url)
        }
        */
        
        let emailTitle = "租屋物件詢問: " + (self.houseItem?.title ?? self.houseItem?.addr ?? "")
        
        var messageBody = "房東您好! 我最近從豬豬快租查詢到您在網路上刊登的租屋物件：\n\n"
        
        if let houseItemDetail = self.houseItemDetail {
            if let sourceLink = houseItemDetail.valueForKey("mobile_link") as? String {
                messageBody += "租屋物件網址: \(sourceLink) \n\n"
            }
        }
        messageBody += "我對於這個物件很感興趣，想跟您約時間看屋。\n" +
        "再麻煩您回覆方便的時間！\n"
        
        let toRecipents = ["pikapai@gmail.com"]
        
        if MFMailComposeViewController.canSendMail() {
            if let mc: MFMailComposeViewController = MFMailComposeViewController() {
                ///Change Bar Item Color
                mc.navigationBar.tintColor = UIColor.whiteColor()
                
                mc.mailComposeDelegate = self
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBody, isHTML: false)
                mc.setToRecipients(toRecipents)
                self.presentViewController(mc, animated: true, completion: nil)
                //self.navigationController?.pushViewController(mc, animated: true)
                
            }
        } else {
            alertMailAppNotReady()
        }
        
    }
    
    func contactByPhoneButtonTouched(sender: UIButton) {
        if let houseDetail = self.houseItemDetail {
            
            var message = "確認聯絡"
            if let contactName = houseDetail.valueForKey("agent") as? String {
                
                let toIndex: String.Index = contactName.startIndex
                    .advancedBy(9, limit: contactName.endIndex)
                
                message += contactName.substringToIndex(toIndex)
            }
            
            if let agentType = houseDetail.valueForKey("agent_type") as? Int {
                message += "(\(agentType))"
            }
            
            let optionMenu = UIAlertController(title: nil, message: message , preferredStyle: .ActionSheet)
            
            
            if let phoneNumbers = houseDetail.valueForKey("phone") as? [String] {
                
                ///Add only first 3 numbers
                for phoneNumber in phoneNumbers.prefix(3) {
                    let numberAction = UIAlertAction(title: String(phoneNumber), style: .Default, handler: {
                        (alert: UIAlertAction!) -> Void in
                        
                        if let phoneStr = alert.title, let url = NSURL(string: "tel://\(phoneStr)") {
                            UIApplication.sharedApplication().openURL(url)
                        }
                        
                    })
                    
                    optionMenu.addAction(numberAction)
                }
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    func gotoSourceButtonTouched(sender: UIButton) {
        
        self.performSegueWithIdentifier("displayHouseSource", sender: self)
        
    }
    
    //    func onMapButtonTouched(sender: UITapGestureRecognizer) {
    //        self.performSegueWithIdentifier(ViewTransConst.displayHouseOnMap, sender: self)
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///Init Contact Bar View
        initContactBarView()
        
        ///Configure navigation bar items
        configureNavigationBarItems()
        
        ///Get remote data
        if let houseItem = self.houseItem {
            fetchHouseDetail(houseItem)
        }
        
        setupTableCells()
        
        configureTableView()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ///Hide tab bar
        self.tabBarController!.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        LoadingSpinnerOverlay.shared.hideOverlayView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@", identifier)
            
            switch identifier{
                
            case ViewTransConst.displayHouseOnMap:
                
                if let mvc = segue.destinationViewController as? MapViewController {
                    if let houseItemDetail = self.houseItemDetail {
                        let coordinateStr = houseItemDetail.valueForKey("coordinate") as? String
                        
                        let coordinateArray = coordinateStr?.componentsSeparatedByString(",").map({ (element) -> CLLocationDegrees in
                            let coordinateElement = element.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                            
                            if let elementNumber = Double(coordinateElement) {
                                return elementNumber
                            } else {
                                return -1
                            }
                        })
                        
                        NSLog("Coordinate: %@", coordinateArray!)
                        
                        if let coordinate = coordinateArray {
                            
                            if(coordinate.count == 2) {
                                if(coordinate[0] > 0 && coordinate[1]>0) {
                                    mvc.coordinate = (coordinate[0], coordinate[1])
                                }
                                
                            }
                        }
                        
                        mvc.houseTitle = self.houseItem?.title
                    }
                }
                
            case ViewTransConst.displayHouseSource:
                if let bvc = segue.destinationViewController as? BrowserViewController {
                    if let houseItemDetail = self.houseItemDetail {
                        bvc.sourceLink = houseItemDetail.valueForKey("mobile_link") as? String
                    }
                }
            default: break
            }
        }
    }
    
}

extension HouseDetailViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        switch result {
        case MFMailComposeResultCancelled:
            print("Mail cancelled")
        case MFMailComposeResultSaved:
            print("Mail saved")
        case MFMailComposeResultSent:
            print("Mail sent")
        case MFMailComposeResultFailed:
            print("Mail sent failure: %@", error?.localizedDescription)
        default:
            break
        }
        //self.navigationController?.popViewControllerAnimated(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension HouseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableRows.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if var cellInfo = tableRows[indexPath.row] {
            NSLog("heightForRowAtIndexPath> Height: %f for Row: %d", cellInfo.cellHeight, indexPath.row)
            
            if(cellInfo.hidden) {
                return 0
            } else {
                if(indexPath.row == 12) {
                    return cellInfo.cellHeight + 2 * 8
                } else {
                    return cellInfo.cellHeight
                }
            }
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.cellIdentifier.rawValue, forIndexPath: indexPath)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            cellInfo.handler(cell)
            
            
            if let cell = cell as? HouseDetailExpandableContentCell {
                
                cell.layoutIfNeeded()
                
                let testheight = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
                
                NSLog("Layout Height: %f", testheight)
                
                cellInfo.cellHeight = max(cellInfo.cellHeight, testheight)
                    //= max(cellInfo.cellHeight, cell.contentLabel.intrinsicContentSize().height)
                
                tableRows[indexPath.row] = cellInfo
                
                NSLog("IntrinsicContentSize Height: %f for Row: %d", cell.contentLabel.intrinsicContentSize().height, indexPath.row)
                
                NSLog("Updated Cell Height: %f for Row: %d", cellInfo.cellHeight, indexPath.row)
            }
            
            //           tableRows[indexPath.row] = cellInfo
            
            //            if let cell = cell as? HouseDetailTitleViewCell {
            //                cellInfo.cellHeight = cell.titleImage.frame.height
            //
            //                NSLog("Cell Size: %f, %f", cell.titleImage.frame.size.width, cell.titleImage.frame.size.height)
            //            }
            
            //           tableRows[indexPath.row] = cellInfo
            
            NSLog("- Cell Instance [%p] Prepare Cell For Row[%d]", cell, indexPath.row)
            
            return cell
        }
        
        assert(false)
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = cell as? HouseDetailTitleViewCell {
            NSLog("willDisplayCell %@", cell)
            let label:MarqueeLabel =  cell.houseTitleLabel as! MarqueeLabel
            label.restartLabel()
        }
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            switch(cellInfo.cellIdentifier) {
            case .AddressCell:
                LoadingSpinnerOverlay.shared.showOverlayOnView(self.view)
                
                ///It takes time to load the map, leave some time to display loading spinner makes the flow look smoother
                self.runOnMainThreadAfter(0.1){
                    self.performSegueWithIdentifier(ViewTransConst.displayHouseOnMap, sender: self)
                }
            case .HouseDetailTitleCell:
                let browser = MWPhotoBrowser(delegate: self)
                
                browser.displayActionButton = true // Show action button to allow sharing, copying, etc (defaults to YES)
                browser.displayNavArrows = true // Whether to display left and right nav arrows on toolbar (defaults to NO)
                browser.displaySelectionButtons = false // Whether selection buttons are shown on each image (defaults to NO)
                browser.zoomPhotosToFill = true // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
                browser.alwaysShowControls = false // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
                browser.enableGrid = true; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
                browser.startOnGrid = false // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
                browser.autoPlayOnAppear = false; // Auto-play first video
                
                browser.setCurrentPhotoIndex(0)
                
                self.navigationController?.pushViewController(browser, animated: true)
                
            case .ExpandableHeaderCell:
                let nextRow = indexPath.row + 1
                var nextCellInfo = tableRows[nextRow]
                
                
                if nextCellInfo?.hidden == true {
                    NSLog("Set Show for Row %d", nextRow)
                    nextCellInfo?.hidden = false
                } else {
                    NSLog("Set Hide for Row %d", nextRow)
                    nextCellInfo?.hidden = true
                }
                tableRows[nextRow] = nextCellInfo
                
                ///Fix disappering seperator issue
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: nextRow, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                //                tableView.beginUpdates()
                //                tableView.endUpdates()
                
                ///Scroll to the header row
                //                if(nextCellInfo?.cellHeight > 0) {
                //                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
                //                }
                
            default: break
            }
        }
    }
    
    
}


extension HouseDetailViewController: MWPhotoBrowserDelegate {
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        
        if let houseItem = self.houseItem, let imgList = houseItem.imgList {
            return UInt(imgList.count)
        } else {
            return 0
        }
    }
    
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        
        let photoIndex: Int = Int(index)
        
        if let houseItem = self.houseItem, let imgList = houseItem.imgList {
            
            if (photoIndex < imgList.endIndex) {
                return  MWPhoto(URL:NSURL(string: imgList[photoIndex]))
            } else {
                return nil
            }
            
        } else {
            return nil
        }
    }
}
