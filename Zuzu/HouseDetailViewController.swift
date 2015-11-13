//
//  HouseDetailViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftyJSON

class HouseDetailViewController: UIViewController {
    
    struct ViewTransConst {
        static let displayHouseOnMap:String = "displayHouseOnMap"
        static let displayHouseSource:String = "displayHouseSource"
    }
    
    var houseItem:HouseItem?
    
    var houseItemDetail: AnyObject?
    
    @IBOutlet weak var tableView: UITableView!
    
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
            }
        }
    }
    
    private func configureTableView() {
        //Configure cell height
        tableView.estimatedRowHeight = 213//tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        tableView.dataSource = self
        tableView.delegate = self
        
        //Remove extra cells when the table height is smaller than the screen
        tableView.tableFooterView = UIView(frame: CGRectZero)
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
    
    func gotoSourceButtonTouched(sender: UIButton) {
        
        self.performSegueWithIdentifier("displayHouseSource", sender: self)
        
    }
    
    //    func onMapButtonTouched(sender: UITapGestureRecognizer) {
    //        self.performSegueWithIdentifier(ViewTransConst.displayHouseOnMap, sender: self)
    //    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///Configure navigation bar items
        configureNavigationBarItems()
        
        ///Get remote data
        if let houseItem = self.houseItem {
            fetchHouseDetail(houseItem)
        }
        
        tableRows = [
            0:CellInfo(cellIdentifier: .HouseDetailTitleCell,cellHeight: 213, handler: { (cell : UITableViewCell) -> () in
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
            1:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                        cell.leftInfoText.text = "\(houseItem.price) 月/元"
                        cell.rightInfoText.text = "\(houseItem.size) 坪"
                    }
                }
            }),
            2:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                        cell.leftInfoText.text = "西門鋼骨"
                        cell.rightInfoText.text = "\(houseItem.houseType) / \(houseItem.purposeType)"
                    }
                }
            }),
            3:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    cell.leftInfoText.text = "樓層: 2/15"
                    cell.rightInfoText.text = "3房2廳"
                }
            }),
            4:CellInfo(cellIdentifier: .AddressCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailAddressCell {
                    if let houseItem = self.houseItem {
                        cell.addressLabel.text = houseItem.addr
                        //                        cell.mapIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onMapButtonTouched:")))
                    }
                }
            }),
            5:CellInfo(cellIdentifier: .ExpandableHeaderCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    
                }
            }),
            6:CellInfo(cellIdentifier: .ExpandableContentCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                }
            })
        ]
        
        configureTableView()
        
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


extension HouseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableRows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.cellIdentifier.rawValue, forIndexPath: indexPath)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            cellInfo.handler(cell)
            
            //            if let cell = cell as? HouseDetailTitleViewCell {
            //                cellInfo.cellHeight = cell.titleImage.frame.height
            //
            //                NSLog("Cell Size: %f, %f", cell.titleImage.frame.size.width, cell.titleImage.frame.size.height)
            //            }
            
            //           tableRows[indexPath.row] = cellInfo
            
            NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
            
            return cell
        }
        
        assert(false)
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            if (cellInfo.cellIdentifier == .AddressCell) {
                self.performSegueWithIdentifier(ViewTransConst.displayHouseOnMap, sender: self)
            }
        }
    }
    
    
}
