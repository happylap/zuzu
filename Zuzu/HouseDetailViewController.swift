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
import Social
import MBProgressHUD
import AwesomeCache
import SCLAlertView

protocol HouseDetailViewDelegate {
    func onHouseItemStateChanged()
}

class HouseDetailViewController: UIViewController {
    
    let PhoneExtensionChar = ","
    let DisplayPhoneExtensionChar = "轉"
    
    var phoneNumberDic = [String:String]() /// display string : original number
    
    var delegate:HouseDetailViewDelegate?
    
    let cacheName = "houseDetailCache"
    let cacheTime:Double = 3 * 60 * 60 //3 hours
    
    class HouseUrl: NSObject, UIActivityItemSource{
        
        var houseUrl:NSURL
        
        init(houseUrl:NSURL) {
            self.houseUrl = houseUrl
        }
        
        func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
            return  houseUrl
        }
        
        func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
            
            return  (activityType == UIActivityTypePostToFacebook) ? houseUrl : nil
        }
    }
    
    class HouseText: NSObject, UIActivityItemSource {
        
        var houseText:String
        
        init(houseText:String) {
            self.houseText = houseText
        }
        
        func activityViewControllerPlaceholderItem(activityViewController: UIActivityViewController) -> AnyObject {
            return houseText
        }
        
        func activityViewController(activityViewController: UIActivityViewController, itemForActivityType activityType: String) -> AnyObject? {
            return houseText
        }
    }
    
    struct ViewTransConst {
        static let displayHouseOnMap:String = "displayHouseOnMap"
        static let displayHouseSource:String = "displayHouseSource"
    }
    
    @IBOutlet weak var contactBarView: HouseDetailContactBarView!
    @IBOutlet weak var tableView: UITableView!
    
    let houseTypeLabelMaker:LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
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
    }
    
    
    struct CellInfo {
        let cellIdentifier:CellIdentifier
        var hidden:Bool
        var cellHeight:CGFloat
        let handler: (UITableViewCell) -> ()
    }
    
    let cellIdentifier = "houseDetailTitleCell"
    
    var tableRows:[Int: CellInfo]!
    
    private func handleHouseDetailResponse(result: AnyObject) {
        
        self.houseItemDetail = result
        
        ///Reload Table View
        self.tableView.reloadData()
        
        ///Configure Views On Data Loaded
        self.configureViewsOnDataLoaded()
        
        self.enableNavigationBarItems()
    }
    
    
    private func fetchHouseDetail(houseItem: HouseItem) {
        
        var hitCache = false
        
        do {
            let cache = try Cache<NSData>(name: cacheName)
            
            ///Return cached data if there is cached data
            if let cachedData = cache.objectForKey(houseItem.id),
                let result = NSKeyedUnarchiver.unarchiveObjectWithData(cachedData) {
                    
                    NSLog("Hit Cache for item: Id: %@, Title: %@", houseItem.id, houseItem.title)
                    
                    hitCache = true
                    
                    LoadingSpinner.shared.stop()
                    
                    handleHouseDetailResponse(result)
            }
            
        } catch _ {
            print("Something went wrong with the cache")
        }
        
        
        if(!hitCache) {
            
            HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
                
                LoadingSpinner.shared.stop()
                
                
                if let error = error {
                    NSLog("Cannot get remote data %@", error.localizedDescription)
                    return
                }
                
                if let result = result {
                    
                    ///Try to cache the house detail response
                    do {
                        let cache = try Cache<NSData>(name: self.cacheName)
                        let cachedData = NSKeyedArchiver.archivedDataWithRootObject(result)
                        cache.setObject(cachedData, forKey: houseItem.id, expires: CacheExpiry.Seconds(self.cacheTime))
                        
                    } catch _ {
                        print("Something went wrong with the cache")
                    }
                    
                    self.handleHouseDetailResponse(result)
                }
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
                                NSLog("Img loading done, status = \(response?.statusCode)")
                            }
                            
                    }
                }
            }),
            1:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    var priceDetail:String?
                    if let houseItemDetail = self.houseItemDetail {
                        
                        if let priceIncl = houseItemDetail.valueForKey("price_incl") as? [Int] {
                            
                            let priceStringList = priceIncl.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("price_incl", code: code, defaultValue: "—")
                            }
                            
                            priceDetail = "租金包含: \(priceStringList.joinWithSeparator("; "))"
                            
                        } else if let otherExpense = houseItemDetail.valueForKey("other_expense") as? [Int] {
                            
                            let otherExpenseStringList = otherExpense.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("other_expense", code: code, defaultValue: "—")
                            }
                            
                            priceDetail = "其他費用: \(otherExpenseStringList.joinWithSeparator("; "))"
                        }
                        
                        if let priceDetail = priceDetail {
                            cell.leftInfoSub.text = "( \(priceDetail) )"
                        } else {
                            cell.leftInfoSub.text = " " //To reserve the height
                        }
                        cell.leftInfoSub.hidden = false
                        
                        if let price = houseItemDetail.valueForKey("price") as? Int {
                            
                            cell.leftInfoText.font = UIFont.boldSystemFontOfSize(cell.leftInfoText.font.pointSize)
                            cell.leftInfoText.text = "\(price) 月/元"
                        }
                        
                        if let size = houseItemDetail.valueForKey("size") as? Float {
                            cell.rightInfoText.font = UIFont.boldSystemFontOfSize(cell.rightInfoText.font.pointSize)
                            
                            /// Round the size to the second place
                            let multiplier:Float = pow(10.0, 2)
                            cell.rightInfoText.text = "\(round(size * multiplier)/multiplier) 坪"
                        }
                    } else {
                        ///Before data is loaded
                        cell.leftInfoSub.text = " " //To reserve the height
                        cell.leftInfoSub.hidden = false
                    }
                }
            }),
            2:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var houseTypeString = String()
                        var purposeTypeString = String()
                        
                        if let houseType = houseDetail.valueForKey("house_type") as? Int{
                            houseTypeString = self.houseTypeLabelMaker.fromCodeForField("house_type", code: houseType,defaultValue: "")
                        }
                        
                        if let purposeType = houseDetail.valueForKey("purpose_type") as? Int{
                            purposeTypeString = self.houseTypeLabelMaker.fromCodeForField("purpose_type", code: purposeType, defaultValue: "")
                        }
                        
                        cell.leftInfoText.text = "\(houseTypeString) / \(purposeTypeString)"
                        
                        var parkingTypeLabel = "—"
                        
                        if let hasParking = houseDetail.valueForKey("parking_lot") as? Bool{
                            if hasParking {
                                if let parkingType = houseDetail.valueForKey("parking_type") as? Int {
                                    parkingTypeLabel = self.houseTypeLabelMaker.fromCodeForField("parking_type", code: parkingType, defaultValue: "")
                                } else {
                                    parkingTypeLabel = "有"
                                }
                            }
                        }
                        
                        cell.rightInfoText.text = "車位: \(parkingTypeLabel)"
                    }
                }
            }),
            3:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        let floor = (houseDetail.valueForKey("floor") as? [Int] ?? [0]).first
                        let total_floor = houseDetail.valueForKey("total_floor") as? Int ?? 0
                        
                        cell.leftInfoText.text = "樓層: \(floor!)/\(total_floor)"
                        
                        var layoutLabel = "—"
                        let room = houseDetail.valueForKey("num_bedroom") as? Int ?? 0
                        let ting = houseDetail.valueForKey("num_ting") as? Int ?? 0
                        
                        if(room != 0 || ting != 0) {
                            layoutLabel = "\(room)房\(ting)廳"
                        }
                        
                        cell.rightInfoText.text = "格局: \(layoutLabel)"
                    }
                }
            }),
            4:CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        let community = houseDetail.valueForKey("community") as? String ?? "—"
                        let mgmtFee = houseDetail.valueForKey("mgmt_fee") as? String ?? "—"
                        
                        cell.leftInfoText.text = "社區: \(community)"
                        
                        cell.rightInfoText.text = "管理費: \(mgmtFee)"
                    }
                }
            }),
            5:CellInfo(cellIdentifier: .AddressCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailAddressCell {
                    if let houseItem = self.houseItem {
                        cell.addressLabel.text = houseItem.addr
                    }
                }
            }),
            6:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "提供物品"
                }
            }),
            7:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString = String()
                        
                        if let furnitureList = houseDetail.valueForKey("furniture") as? [Int]  {
                            
                            let furnitureStringList = furnitureList.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("furniture", code: code, defaultValue: "—")
                            }
                            
                            resultString += furnitureStringList.joinWithSeparator("; ") + "\n"
                        }
                        
                        if let facilityList = houseDetail.valueForKey("facility") as? [Int]  {
                            let facilityStringList = facilityList.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("facility", code: code, defaultValue: "—")
                            }
                            
                            resultString += facilityStringList.joinWithSeparator("; ")
                        }
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = resultString
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                    
                }
            }),
            8:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "生活機能"
                }
            }),
            9:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString = String()
                        
                        if let surroundingList = houseDetail.valueForKey("surrounding") as? [Int]  {
                            
                            let surroundingStringList = surroundingList.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("surrounding", code: code, defaultValue: "—")
                            }
                            
                            let itemsPerRow = 4
                            var allItems = surroundingStringList
                            
                            while(allItems.count > itemsPerRow) {
                                let row = Array(allItems.prefix(itemsPerRow))
                                resultString += row.joinWithSeparator("; ") + "\n"
                                
                                let rangeToRemove = allItems.startIndex..<allItems.startIndex.advancedBy(itemsPerRow)
                                allItems.removeRange(rangeToRemove)
                            }
                            
                            resultString += allItems.joinWithSeparator("; ") + "\n\n"
                            
                            //resultString += surroundingStringList.joinWithSeparator("; ") + "\n\n"
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
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = "\(resultString)\n"
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                    
                }
            }),
            10:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "租屋限制"
                }
            }),
            11:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        var resultString = String()
                        
                        //Profile
                        if let profiles = houseDetail.valueForKey("restr_profile") as? [String] {
                            
                            let profilesStringList = profiles.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("restr_profile", code: Int(code)!, defaultValue: "—")
                            }
                            
                            resultString += profilesStringList.joinWithSeparator("; ") + "\n\n"
                        }
                        
                        var restrictionList = [String]()
                        //Sex
                        if let sex = houseDetail.valueForKey("restr_sex") as? Int {
                            if let sexString = self.houseTypeLabelMaker.fromCodeForField("restr_sex", code: sex) {
                                restrictionList.append("限\(sexString)性")
                            }
                        }
                        
                        //Allow Pet
                        if let allow_pet = houseDetail.valueForKey("allow_pet") as? Bool {
                            
                            restrictionList.append( (allow_pet ? "可養寵物" : "不可養寵物"))
                        }
                        
                        //Allow Cooking
                        if let allow_cooking = houseDetail.valueForKey("allow_cooking") as? Bool {
                            
                            restrictionList.append( (allow_cooking ? "可開伙" : "不可開伙"))
                        }
                        
                        if(restrictionList.count > 0) {
                            resultString += restrictionList.joinWithSeparator("; ") + "\n"
                        }
                        
                        let daysInMonth = 30
                        let monthInYear = 12
                        
                        //Shortest Lease
                        if let leasePeriod = houseDetail.valueForKey("shortest_lease") as? Int {
                            
                            var leasePeriodLabel = "\(leasePeriod)天"
                            
                            if(leasePeriod != 0 && leasePeriod % daysInMonth == 0) {
                                let month = leasePeriod / daysInMonth
                                leasePeriodLabel = "\(month)個月"
                                
                                if(month % monthInYear == 0) {
                                    let year = month / monthInYear
                                    leasePeriodLabel = "\(year)年"
                                }
                                
                                resultString += "最短租期: \(leasePeriodLabel)\n"
                                
                            } else {
                                resultString += "最短租期: \(leasePeriodLabel)\n"
                            }
                        }
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = resultString
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                }
            }),
            12:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "其他資訊"
                }
            }),
            13:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    var otherInfoList = [String]()
                    if let houseDetail = self.houseItemDetail {
                        otherInfoList.append("隔間材料: \( (houseDetail.valueForKey("wall_mtl") as? String ?? "—") )")
                        
                        var orientationStr = "—"
                        if let orientation = houseDetail.valueForKey("orientation") as? Int {
                            orientationStr = self.houseTypeLabelMaker.fromCodeForField("orientation", code: orientation, defaultValue: "")
                        }
                        
                        otherInfoList.append("朝向: \(orientationStr)")
                        
                        
                        var readyDateStr = "—"
                        if let readyDate = houseDetail.valueForKey("ready_date") as? String {
                            if let dateEnd = readyDate.characters.indexOf("T") {
                                readyDateStr = String(readyDate.characters.prefixUpTo(dateEnd))
                            }
                        }
                        
                        otherInfoList.append("可遷入日: \(readyDateStr)")
                        
                        
                        if(otherInfoList.count > 0) {
                            cell.contentLabel.text = otherInfoList.joinWithSeparator("\n") + "\n"
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                        
                        
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                }
            }),
            14:CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "屋主說明"
                }
            }),
            15:CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    cell.contentLabel.adjustsFontSizeToFitWidth = false
                    cell.contentLabel.numberOfLines = 0
                    
                    if let houseDetail = self.houseItemDetail {
                        var resultString = String()
                        
                        //cell.contentLabel.preferredMaxLayoutWidth = cell.contentView.frame.width - 2 * 8
                        
                        //Desc
                        if let desc = houseDetail.valueForKey("desc") as? String {
                            
                            resultString = desc
                        }
                        NSLog("Desc Set: %@", resultString)
                        
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = "\(resultString)\n"
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                        
                        //cell.contentLabel.sizeToFit()
                        //cell.setNeedsLayout()
                        // cell.layoutIfNeeded()
                        
                        NSLog("Frame Height: %f", cell.contentLabel.frame.height)
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                }
            })
        ]
    }
    
    private func alertMailAppNotReady() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "找不到預設的郵件應用，請到 [設定] > [郵件、聯絡資訊、行事曆] > 帳號，確認您的郵件帳號已經設置完成"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("找不到預設的郵件應用", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    
    private func alertAddingToCollectionSuccess() {
        
        if(!UserDefaultsUtils.needsMyCollectionPrompt()) {
            return
        }
        
        let alertView = SCLAlertView()
        
        let subTitle = "成功加入一筆租屋到\"我的收藏\"\n現在去看看收藏項目嗎？"
        
        alertView.addButton("馬上去看看") {
            UserDefaultsUtils.disableMyCollectionPrompt()
            
            let parentViewController = self.navigationController?.popViewControllerAnimated(true)
            parentViewController?.tabBarController?.selectedIndex = 1
        }
        
        alertView.addButton("不需要") {
            UserDefaultsUtils.disableMyCollectionPrompt()
        }
        
        alertView.showCloseButton = false
        
        alertView.showTitle("新增到我的收藏", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
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
        
        if let houseItem = self.houseItem {
            if(CollectionItemService.sharedInstance.isExist(houseItem.id)) {
                
                collectButton.setImage(UIImage(named: "heart_pink"), forState: UIControlState.Normal)
                
            } else {
                
                collectButton.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
                
            }
        }
        
        collectButton.addTarget(self, action: "collectButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
        collectButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let collectItem = UIBarButtonItem(customView: collectButton)
        collectItem.enabled = false
        let shareItem = UIBarButtonItem(customView: shareButton)
        shareItem.enabled = false
        let sourceItem = UIBarButtonItem(customView: gotoSourceButton)
        sourceItem.enabled = false
        
        /// Add bar items from right to left
        var barItems = [UIBarButtonItem]()
        
        if(FeatureOption.Collection.enableMain) {
            barItems.append(collectItem)
        }
        
        barItems.append(shareItem)
        barItems.append(sourceItem)
        
        self.navigationItem.setRightBarButtonItems(barItems, animated: false)
    }
    
    
    private func enableNavigationBarItems() {
        /// From right to left
        if let items = self.navigationItem.rightBarButtonItems {
            
            for item in items {
                item.enabled = true
            }
            
        }
    }
    
    private func initContactBarView() {
        contactBarView.contactName.text = " "
        contactBarView.contactName.enabled = false
        
        contactBarView.contactByMailButton.enabled = false
        
        contactBarView.contactByPhoneButton.enabled = false
    }
    
    private func configureContactBarView() {
        
        if let houseDetail = self.houseItemDetail {
            
            var contactDisplayStr = ""
            
            if let contactName = houseDetail.valueForKey("agent") as? String {
                contactDisplayStr = contactName
            }
            
            if let agentType = houseDetail.valueForKey("agent_type") as? Int {
                let agentTypeStr = houseTypeLabelMaker.fromCodeForField("agent_type", code: agentType, defaultValue: "—")
                contactDisplayStr += " (\(agentTypeStr))"
            }
            
            contactBarView.contactName.text = contactDisplayStr
            
            if let _ = houseDetail.valueForKey("email") as? String {
                contactBarView.contactByMailButton
                    .addTarget(self, action: "contactByMailButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                contactBarView.contactByMailButton.enabled = true
            }
            
            if let _ = houseDetail.valueForKey("phone") as? [String] {
                
                let tapGuesture = UITapGestureRecognizer(target: self, action: "contactNameTouched:")
                contactBarView.contactName.addGestureRecognizer(tapGuesture)
                contactBarView.contactName.enabled = true
                
                contactBarView.contactByPhoneButton
                    .addTarget(self, action: "contactByPhoneButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                contactBarView.contactByPhoneButton.enabled = true
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
        
        
        
        if let houseDetail = self.houseItemDetail {
            
            if let email = houseDetail.valueForKey("email") as? String {
                
                var messageBody = "房東您好! 我最近從豬豬快租查詢到您在網路上刊登的租屋物件：\n\n"
                
                let toRecipents = [email]
                
                LoadingSpinner.shared.startOnView(self.view)
                
                if let sourceLink = houseDetail.valueForKey("mobile_link") as? String {
                    messageBody += "租屋物件網址: \(sourceLink) \n\n"
                }
                
                messageBody += "我對於這個物件很感興趣，想跟您約時間看屋。\n再麻煩您回覆方便的時間！\n"
                
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
                    LoadingSpinner.shared.stop()
                }
                
            } else {
                NSLog("No emails available")
            }
        }
    }
    
    private func displayPhoneNumberMenu() {
        if let houseDetail = self.houseItemDetail {
            
            var message = "確認聯絡: "
            let maxDisplayChars = 15
            
            if let contactName = houseDetail.valueForKey("agent") as? String {
                
                let toIndex: String.Index = contactName.startIndex
                    .advancedBy(maxDisplayChars, limit: contactName.endIndex)
                
                if(maxDisplayChars < contactName.characters.count) {
                    message += contactName.substringToIndex(toIndex) + "..."
                } else {
                    message += contactName.substringToIndex(toIndex)
                }
            }
            
            if let agentType = houseDetail.valueForKey("agent_type") as? Int {
                let agentTypeStr = houseTypeLabelMaker.fromCodeForField("agent_type", code: agentType, defaultValue: "—")
                message += " (\(agentTypeStr))"
            }
            
            let optionMenu = UIAlertController(title: nil, message: message , preferredStyle: .ActionSheet)
            
            
            if let phoneNumbers = houseDetail.valueForKey("phone") as? [String] {
                
                ///Add only first 3 numbers
                for phoneNumber in phoneNumbers.prefix(3) {
                    
                    var phoneDisplayString = phoneNumber
                    let phoneComponents = phoneNumber.componentsSeparatedByString(PhoneExtensionChar)
                    
                    /// Convert to human-redable display format for phone number with extension
                    if(phoneComponents.count == 2) {
                        phoneDisplayString = phoneComponents.joinWithSeparator(DisplayPhoneExtensionChar)
                    } else if (phoneComponents.count > 2){
                        assert(false, "Incorrect phone number format \(phoneNumber)")
                    }
                    
                    /// Bind phone number & display string
                    phoneNumberDic[phoneDisplayString] = phoneNumber
                    
                    let numberAction = UIAlertAction(title: phoneDisplayString, style: .Default, handler: {
                        (alert: UIAlertAction!) -> Void in
                        
                        var success = false
                        
                        if let phoneDisplayStr = alert.title {
                            
                            if let phoneStr = self.phoneNumberDic[phoneDisplayStr],
                                let url = NSURL(string: "tel://\(phoneStr)") {
                                    
                                success = UIApplication.sharedApplication().openURL(url)
                                
                                if let houseId = houseDetail.valueForKey("id") as? String {
                                    CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
                                }
                            }
                        }
                        
                        ///GA Tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.Contact,
                            label: GAConst.Label.Contact.Phone,
                            value:  UInt(success))
                        
                    })
                    
                    optionMenu.addAction(numberAction)
                }
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
                ///GA Tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                    action: GAConst.Action.Activity.Contact,
                    label: GAConst.Label.Contact.Phone,
                    value:  2)
            })
            
            optionMenu.addAction(cancelAction)
            
            self.presentViewController(optionMenu, animated: true, completion: nil)
        }
    }
    
    func contactNameTouched(sender: UITapGestureRecognizer) {
        displayPhoneNumberMenu()
    }
    
    func contactByPhoneButtonTouched(sender: UIButton) {
        displayPhoneNumberMenu()
    }
    
    func shareButtonTouched(sender: UIButton) {
        
        if let houseItemDetail = self.houseItemDetail,
            let houseLink = houseItemDetail.valueForKey("mobile_link") as? String {
                
                if let houseURL = NSURL(string: houseLink) {
                    var objectsToShare = [AnyObject]()
                    
                    let appSlogan = "想租屋就找豬豬! 本資訊透過[豬豬快租App]與您分享"
                    let titleToShare = self.houseItem?.title ?? ""
                    let addressToShare = self.houseItem?.addr ?? ""
                    
                    let text = ("\n\(titleToShare)\n\(addressToShare)\n\(houseLink)\n\n\(appSlogan)\n")
                    
                    objectsToShare.append(HouseUrl(houseUrl: houseURL))
                    objectsToShare.append(HouseText(houseText: text))
                    
                    
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    
                    self.presentViewController(activityVC, animated: true, completion: { () -> Void in
                    })
                    
                    
                }
                
        } else {
            NSLog("No data to share now")
        }
        
        ///GA Tracker
        if let houseItem = houseItem {
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.ShareItemPrice,
                label: String(houseItem.price))
            
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.ShareItemSize,
                label: String(houseItem.size))
            
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.ShareItemType,
                label: String(houseItem.purposeType))
        }
        
    }
    
    func collectButtonTouched(sender: UIButton){
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self) {
                (task: AWSTask!) -> AnyObject! in
                return nil
            }
            return
        }
        
        if let houseItemDetail = self.houseItemDetail,
            let houseId = houseItemDetail.valueForKey("id") as? String {
                
                let barItem = self.navigationItem.rightBarButtonItems?.first?.customView as? UIButton
                
                let collectionService = CollectionItemService.sharedInstance
                
                ///Determine action based on whether the house item is already in "My Collection"
                if(collectionService.isExist(houseId)) {
                    
                    collectionService.deleteItemById(houseId)
                    
                    if let barItem = barItem {
                        barItem.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
                    }
                    
                } else {
                    
                    if !CollectionItemService.sharedInstance.canAdd() {
                        let subTitle = "您目前的收藏筆數已達上限\(CollectionItemService.CollectionItemConstants.MYCOLLECTION_MAX_SIZE)筆。"
                        SCLAlertView().showWarning("提醒您", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                        return
                    }
                    
                    collectionService.addItem(houseItemDetail)
                    self.alertAddingToCollectionSuccess()
                    
                    if let barItem = barItem {
                        barItem.setImage(UIImage(named: "heart_pink"), forState: UIControlState.Normal)
                    }
                }
                
                ///Notify the search result table to refresh the slected row
                delegate?.onHouseItemStateChanged()
        }
    }
    
    func gotoSourceButtonTouched(sender: UIButton) {
        
        self.performSegueWithIdentifier(ViewTransConst.displayHouseSource, sender: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///Start Loading
        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.startOnView(view)
        
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
        self.tabBarController!.tabBarHidden = true
        
        ///Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //        let serviceType = SLServiceTypeTwitter
        //        if SLComposeViewController.isAvailableForServiceType(serviceType){
        //            let controller = SLComposeViewController(forServiceType: serviceType)
        //            controller.setInitialText("Safari is a great browser!")
        //            controller.addImage(UIImage(named: "Safari"))
        //            controller.addURL(NSURL(string: "http://www.apple.com/safari/"))
        //            controller.completionHandler = {(result: SLComposeViewControllerResult) in
        //                print("Completed")
        //            }
        //
        //            presentViewController(controller, animated: true, completion: nil)
        //
        //        }else{
        //            print("The Twitter service is not available")
        //        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        ///Display tab bar
        self.tabBarController!.tabBarHidden = false
        
        CollectionItemService.sharedInstance.resetEnterTimer()
        
        LoadingSpinner.shared.stop()
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
                        mvc.houseAddres = self.houseItem?.addr
                    }
                }
                
            case ViewTransConst.displayHouseSource:
                if let bvc = segue.destinationViewController as? BrowserViewController {
                    if let houseItemDetail = self.houseItemDetail {
                        
                        let sourceLink = houseItemDetail.valueForKey("mobile_link") as? String
                        
                        bvc.sourceLink = sourceLink
                        bvc.viewTitle = "原始房源網頁"
                        
                        ///GA Tracker
                        if let houseItem = houseItem {
                            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                                action: GAConst.Action.Activity.ViewSource,
                                label: String(houseItem.source))
                        }
                    }
                }
            default: break
            }
        }
    }
    
}

extension HouseDetailViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        
        var success = false
        
        switch result {
        case MFMailComposeResultCancelled:
            print("Mail cancelled")
        case MFMailComposeResultSaved:
            print("Mail saved")
        case MFMailComposeResultSent:
            success = true
            print("Mail sent")
            if let houseId = self.houseItem?.id {
                CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
            }
        case MFMailComposeResultFailed:
            print("Mail sent failure: %@", error?.localizedDescription)
        default:
            break
        }
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
            action: GAConst.Action.Activity.Contact,
            label: GAConst.Label.Contact.Email,
            value:  UInt(success))
        
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
    
    //    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //        if var cellInfo = tableRows[indexPath.row] {
    //            NSLog("heightForRowAtIndexPath> Height: %f for Row: %d", cellInfo.cellHeight, indexPath.row)
    //
    //            if(cellInfo.hidden) {
    //                return 0
    //            } else {
    //                if(indexPath.row == 12) {
    //                    return cellInfo.cellHeight + 2 * 8
    //                } else {
    //                    return cellInfo.cellHeight
    //                }
    //            }
    //        } else {
    //            return 0
    //        }
    //    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.cellIdentifier.rawValue, forIndexPath: indexPath)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            cellInfo.handler(cell)
            
            
            if let cell = cell as? HouseDetailExpandableContentCell {
                
                let contentHeight = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
                let labelHeight = cell.contentLabel.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
                
                NSLog("Content Layout Height: %f", contentHeight)
                NSLog("Label Layout Height: %f", labelHeight)
                
                cellInfo.cellHeight = max(cellInfo.cellHeight, contentHeight)
                cellInfo.cellHeight = max(cellInfo.cellHeight, cell.contentLabel.intrinsicContentSize().height)
                
                tableRows[indexPath.row] = cellInfo
                
                NSLog("IntrinsicContentSize Height: %f for Row: %d", cell.contentLabel.intrinsicContentSize().height, indexPath.row)
                
                NSLog("Updated Cell Height: %f for Row: %d", cellInfo.cellHeight, indexPath.row)
            }
            
            NSLog("- Cell Instance [%p] Prepare Cell For Row[%d]", cell, indexPath.row)
            
            return cell
            
        } else {
            assert(false, "No cellInfo for the row = \(indexPath.row)")
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = cell as? HouseDetailTitleViewCell {
            NSLog("willDisplayCell %@", cell)
            let label:MarqueeLabel =  cell.houseTitleLabel as! MarqueeLabel
            label.restartLabel()
        }
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cellInfo = tableRows[indexPath.row] {
            
            switch(cellInfo.cellIdentifier) {
            case .AddressCell:
                LoadingSpinner.shared.startOnView(self.view)
                
                ///It takes time to load the map, leave some time to display loading spinner makes the flow look smoother
                self.runOnMainThreadAfter(0.1){
                    self.performSegueWithIdentifier(ViewTransConst.displayHouseOnMap, sender: self)
                }
            case .HouseDetailTitleCell:
                
                LoadingSpinner.shared.startOnView(self.view)
                
                let browser = MWPhotoBrowser(delegate: self)
                
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
                
                // Action button to allow sharing, copying, etc (default: true)
                browser.displayActionButton = true
                
                // Whether to display nav arrows on toolbar (default: false)
                browser.displayNavArrows = true
                
                // Whether selection buttons are shown on each image (default: true)
                browser.displaySelectionButtons = false
                
                // Images that almost fill the screen will be initially zoomed to fill (default: true)
                browser.zoomPhotosToFill = true
                
                // Whether the bars and controls are always visible or not (default: false)
                browser.alwaysShowControls = false
                
                // Whether to allow the grid view (default: true)
                browser.enableGrid = true;
                
                // Whether to start on the grid view (default: false)
                browser.startOnGrid = false
                
                // Auto-play first video
                browser.autoPlayOnAppear = false;
                
                browser.setCurrentPhotoIndex(0)
                
                self.navigationController?.pushViewController(browser, animated: true)
                
                self.trackScreenWithTitle("View: Image Viewer")
                
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
    
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, thumbPhotoAtIndex index: UInt) -> MWPhotoProtocol! {
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
