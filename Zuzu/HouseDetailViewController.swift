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
import AwesomeCache
import SCLAlertView
import GoogleMobileAds
import FBAudienceNetwork

private let Log = Logger.defaultLogger

@objc protocol HouseDetailViewDelegate {
    
    optional func onHouseItemStateChanged()
    
    optional func onHouseItemLoaded(result: Bool)
    
}

class HouseDetailViewController: UIViewController {
    
    // MARK: - Private Fields
    private var bannerView: GADBannerView = ADFactory.sharedInstance.getHouseDetailBanner()
    
    private static var alertViewResponder: SCLAlertViewResponder?
    private var networkErrorAlertView:SCLAlertView? = SCLAlertView()
    
    private let PhoneExtensionChar = ","
    private let DisplayPhoneExtensionChar = "轉"
    
    private var phoneNumberDic = [String:String]() /// display string : original number
    
    private let cacheName = "houseDetailCache"
    private let cacheTime:Double = 3 * 60 * 60 //3 hours
    
    private let houseTypeLabelMaker:LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
    private let cellIdentifier = "houseDetailTitleCell"
    private var tableRows:[Int: CellInfo]!
    
    private var photos = [MWPhoto]()
    
    // MARK: - Public Fields
    
    /// @Controller Input Params
    var houseItem:HouseItem?
    
    ///The full house detail returned from remote server
    var houseItemDetail: AnyObject?
    
    var delegate:HouseDetailViewDelegate?
    
    enum CellIdentifier: String {
        case HouseDetailTitleCell = "houseDetailTitleCell"
        case PriceSizeCell = "priceSizeCell"
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
    
    /// Wrapping classes for sharing
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
    
    struct TableConst {
        static let sectionNum:Int = 1
    }
    
    struct ViewTransConst {
        static let displayHouseOnMap:String = "displayHouseOnMap"
        static let displayHouseSource:String = "displayHouseSource"
    }
    
    @IBOutlet weak var contactBarView: HouseDetailContactBarView!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private Utils
    
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
                    
                    Log.debug("Hit Cache for item: Id: \(houseItem.id), Title: \(houseItem.title)")
                    
                    hitCache = true
                    
                    LoadingSpinner.shared.stop()
                    
                    self.delegate?.onHouseItemLoaded?(true)
                    handleHouseDetailResponse(result)
            }
            
        } catch _ {
            Log.debug("Something went wrong with the cache")
        }
        
        
        if(!hitCache) {
            
            HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
                
                LoadingSpinner.shared.stop()
                
                
                if let error = error {
                    Log.debug("Cannot get remote data \(error.localizedDescription)")
                    
                    if let alertView = self.networkErrorAlertView {
                        let subTitle = "您目前可能處於飛航模式或是無網路狀態，暫時無法檢視詳細資訊。"
                        alertView.showCloseButton = true
                        alertView.showInfo("網路無法連線", subTitle: subTitle, closeButtonTitle: "知道了",colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                    }
                    
                    self.delegate?.onHouseItemLoaded?(false)
                    
                    return
                }
                
                if let result = result {
                    
                    ///Try to cache the house detail response
                    do {
                        let cache = try Cache<NSData>(name: self.cacheName)
                        let cachedData = NSKeyedArchiver.archivedDataWithRootObject(result)
                        cache.setObject(cachedData, forKey: houseItem.id, expires: CacheExpiry.Seconds(self.cacheTime))
                        
                    } catch _ {
                        Log.debug("Something went wrong with the cache")
                    }
                    
                    self.delegate?.onHouseItemLoaded?(true)
                    self.handleHouseDetailResponse(result)
                }
            }
            
        }
    }
    
    private func setupTableCells() {
        
        tableRows = [
            0:CellInfo(cellIdentifier: .HouseDetailTitleCell, hidden: false, cellHeight: 213, handler: { (cell : UITableViewCell) -> () in
                if let cell = cell as? HouseDetailTitleViewCell {
                    
                    if let houseItemDetail = self.houseItemDetail {
                        var data = JSON(houseItemDetail)
                        let imgList = data["img"].arrayObject as? [String] ?? [String]()
                        
                        cell.carouselView.imageUrls = imgList
                        cell.carouselView.tapHandler = { () -> Void in
                            Log.debug("carouselView.tapHandler")
                            
                            let rowToSelect:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0);  //slecting 0th row with 0th section
                            //self.tableView.selectRowAtIndexPath(rowToSelect, animated: true, scrollPosition: UITableViewScrollPosition.None);
                            self.tableView(self.tableView, didSelectRowAtIndexPath: rowToSelect);
                        }
                        
                        cell.carouselView.setNeedsLayout()
                    }
                    
                    if let houseDetail = self.houseItemDetail {
                        cell.houseTitleLabel.text = houseDetail.valueForKey("title") as? String
                    } else {
                        cell.houseTitleLabel.text = ""
                    }
                }
            }),
            1:CellInfo(cellIdentifier: .PriceSizeCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailPriceSizeCell {
                    
                    var priceDetail:String?
                    if let houseItemDetail = self.houseItemDetail {
                        
                        let attributes = [
                            NSBackgroundColorAttributeName: UIColor.colorWithRGB(0xFFFFFF),
                            NSForegroundColorAttributeName: UIColor.colorWithRGB(0xFF6666),
                            NSFontAttributeName: UIFont.systemFontOfSize(15)
                        ]
                        
                        /// Show previous price
                        if let prevPrice = houseItemDetail.valueForKey("previous_price") as? Int {
                            
                            let myMutableString = NSMutableAttributedString(string: "\(prevPrice)↯", attributes: attributes)
                            
                            myMutableString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSRange(location:0,length:myMutableString.string.characters.count-1))
                            
                            cell.previousPriceLabel.attributedText = myMutableString
                            
                        }
                        
                        /// Show price detailed info
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
                            cell.priceDetailLabel.text = "( \(priceDetail) )"
                        } else {
                            cell.priceDetailLabel.text = " " //To reserve the height
                        }
                        cell.priceDetailLabel.hidden = false
                        
                        if let price = houseItemDetail.valueForKey("price") as? Int {
                            
                            cell.priceLabel.font = UIFont.boldSystemFontOfSize(cell.priceLabel.font.pointSize)
                            cell.priceLabel.text = "\(price) 月/元"
                        }
                        
                        if let size = houseItemDetail.valueForKey("size") as? Float {
                            cell.sizeLabel.font = UIFont.boldSystemFontOfSize(cell.sizeLabel.font.pointSize)
                            
                            /// Round the size to the second place
                            let multiplier:Float = pow(10.0, 2)
                            cell.sizeLabel.text = "\(round(size * multiplier)/multiplier) 坪"
                        }
                    } else {
                        ///Before data is loaded
                        cell.priceDetailLabel.text = " " //To reserve the height
                        cell.priceDetailLabel.hidden = false
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
                    
                    if let houseDetail = self.houseItemDetail {
                        cell.addressLabel.text = houseDetail.valueForKey("addr") as? String
                    } else {
                        cell.addressLabel.text = " " //To reserve the height
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
                        Log.debug("Desc Set: \(resultString)")
                        
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = "\(resultString)\n"
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                        
                        //cell.contentLabel.sizeToFit()
                        //cell.setNeedsLayout()
                        // cell.layoutIfNeeded()
                        
                        Log.debug("Frame Height: \(cell.contentLabel.frame.height)")
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
            
            NSNotificationCenter.defaultCenter().postNotificationName("switchToTab", object: self, userInfo: ["targetTab" : 1])
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
    
    private func getAdBannerFooterView() -> UIView {
        self.bannerView.rootViewController = self
        self.bannerView.adSize = kGADAdSizeBanner
        self.bannerView.delegate = self
        
        let request = GADRequest()
        request.testDevices = ADFactory.testDevice
        self.bannerView.loadRequest(request)
        
        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 120))
        footerView.addSubview(self.bannerView)
        self.bannerView.center.x = footerView.center.x
        self.bannerView.center.y = self.bannerView.center.y + 8.0
        
        return footerView
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
        
        
        if(ADFactory.shouldDisplayADs()) {
            
            tableView.tableFooterView = self.getAdBannerFooterView()
            
        } else {
            
            //Remove extra cells with some padding height
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 165))
        }
        
    }
    
    private func configureNavigationBarItems() {
        
        ///Prepare custom UIButton for UIBarButtonItem
        let gotoSourceButton: UIButton = UIButton(type: UIButtonType.Custom)
        gotoSourceButton.setImage(UIImage(named: "web_n"), forState: UIControlState.Normal)
        gotoSourceButton.addTarget(self, action: #selector(HouseDetailViewController.gotoSourceButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        gotoSourceButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let shareButton: UIButton = UIButton(type: UIButtonType.Custom)
        shareButton.setImage(UIImage(named: "share_n"), forState: UIControlState.Normal)
        shareButton.addTarget(self, action: #selector(HouseDetailViewController.shareButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        shareButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let collectButton: UIButton = UIButton(type: UIButtonType.Custom)
        
        if let houseItem = self.houseItem {
            if(CollectionItemService.sharedInstance.isExist(houseItem.id)) {
                
                collectButton.setImage(UIImage(named: "heart_pink"), forState: UIControlState.Normal)
                
            } else {
                
                collectButton.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
                
            }
        }
        
        collectButton.addTarget(self, action: #selector(HouseDetailViewController.collectButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
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
                    .addTarget(self, action: #selector(HouseDetailViewController.contactByMailButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                contactBarView.contactByMailButton.enabled = true
            }
            
            if let _ = houseDetail.valueForKey("phone") as? [String] {
                
                let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(HouseDetailViewController.contactNameTouched(_:)))
                contactBarView.contactName.addGestureRecognizer(tapGuesture)
                contactBarView.contactName.enabled = true
                
                contactBarView.contactByPhoneButton
                    .addTarget(self, action: #selector(HouseDetailViewController.contactByPhoneButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                contactBarView.contactByPhoneButton.enabled = true
            }
        }
    }
    
    // MARK: - Action Handlers
    
    func contactByMailButtonTouched(sender: UIButton) {
        
        /* Another way to allow sending mail by lauching default mail App
        * Our app will be suspended, and the user woulden't have a way to return to our App
        if let url = NSURL(string: "mailto:jon.doe@mail.com") {
        UIApplication.sharedApplication().openURL(url)
        }
        */
        
        
        if let houseDetail = self.houseItemDetail {
            
            let title = houseDetail.valueForKey("title") as? String
            let addr = houseDetail.valueForKey("addr") as? String
            
            let emailTitle = "租屋物件詢問: " + (title ?? addr ?? "")
            
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
                Log.debug("No emails available")
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
                        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                            action: GAConst.Action.UIActivity.Contact,
                            label: GAConst.Label.Contact.Phone,
                            value:  UInt(success))
                        
                    })
                    
                    optionMenu.addAction(numberAction)
                }
            }
            
            let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                
                ///GA Tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                    action: GAConst.Action.UIActivity.Contact,
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
                    
                    let titleToShare = houseItemDetail.valueForKey("title") as? String ?? ""
                    let addressToShare = houseItemDetail.valueForKey("addr") as? String ?? ""
                    
                    let text = ("\n\(titleToShare)\n\(addressToShare)\n\(houseLink)\n\n\(appSlogan)\n")
                    
                    objectsToShare.append(HouseUrl(houseUrl: houseURL))
                    objectsToShare.append(HouseText(houseText: text))
                    
                    
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    
                    self.presentViewController(activityVC, animated: true, completion: { () -> Void in
                    })
                    
                    
                }
                
        } else {
            Log.debug("No data to share now")
        }
        
        ///GA Tracker
        if let houseItem = houseItem {
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                action: GAConst.Action.UIActivity.ShareItemPrice,
                label: String(houseItem.price))
            
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                action: GAConst.Action.UIActivity.ShareItemSize,
                label: String(houseItem.size))
            
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                action: GAConst.Action.UIActivity.ShareItemType,
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
                    
                    ///Notify the search result table to refresh the selected row
                    delegate?.onHouseItemStateChanged?()
                    
                } else {
                    
                    if !CollectionItemService.sharedInstance.canAdd() {
                        let subTitle = "您目前的收藏筆數已達上限\(CollectionItemService.CollectionItemConstants.MYCOLLECTION_MAX_SIZE)筆。"
                        SCLAlertView().showInfo("提醒您", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                        return
                    }
                    
                    if let barItem = barItem {
                        barItem.setImage(UIImage(named: "heart_pink"), forState: UIControlState.Normal)
                    }
                    
                    LoadingSpinner.shared.stop()
                    LoadingSpinner.shared.setImmediateAppear(false)
                    LoadingSpinner.shared.setGraceTime(1.0)
                    LoadingSpinner.shared.setOpacity(0.3)
                    LoadingSpinner.shared.startOnView(self.view)
                    Log.debug("LoadingSpinner startOnView")
                    
                    HouseDataRequester.getInstance().searchById(houseId) { (result, error) -> Void in
                        LoadingSpinner.shared.stop()
                        Log.debug("LoadingSpinner stop")
                        
                        if let error = error {
                            let alertView = SCLAlertView()
                            alertView.showCloseButton = false
                            alertView.addButton("知道了") {
                                if let barItem = barItem {
                                    barItem.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
                                }
                            }
                            let subTitle = "您目前可能處於飛航模式或是無網路狀態，請稍後再試"
                            alertView.showInfo("網路無法連線", subTitle: subTitle, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                            
                            Log.debug("Cannot get remote data \(error.localizedDescription)")
                            return
                        }
                        
                        collectionService.addItem(houseItemDetail)
                        self.alertAddingToCollectionSuccess()
                        
                        ///Notify the search result table to refresh the slected row
                        self.delegate?.onHouseItemStateChanged?()
                    }
                }
                
        }
    }
    
    func gotoSourceButtonTouched(sender: UIButton) {
        
        self.performSegueWithIdentifier(ViewTransConst.displayHouseSource, sender: self)
        
    }
    
    func onClosePhotoBrowser(sender: UIBarButtonItem) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    func onCloseMap(sender: UIBarButtonItem) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    // MARK: - View Life Cycle
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
        
        ///Disable Back Button default title
        self.title = ""
        
        ///Hide tab bar
        self.tabBarController?.tabBarHidden = true
        
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
        //                Log.debug("Completed")
        //            }
        //
        //            presentViewController(controller, animated: true, completion: nil)
        //
        //        }else{
        //            Log.debug("The Twitter service is not available")
        //        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        ///Display tab bar
        self.tabBarController?.tabBarHidden = false
        
        ///Do not need to display alert once the view controller is not in the foreground
        self.networkErrorAlertView = nil
        
        LoadingSpinner.shared.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Controller Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
                
            case ViewTransConst.displayHouseOnMap:
                
                if let mvc = segue.destinationViewController as? MapViewController {
                    
                    // Config navigation left bar
                    mvc.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"cancel"), style: .Plain, target: self, action: #selector(HouseDetailViewController.onCloseMap(_:)))
                    
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
                        
                        Log.debug("Coordinate: \(coordinateArray!)")
                        
                        if let coordinate = coordinateArray {
                            
                            if(coordinate.count == 2) {
                                if(coordinate[0] > 0 && coordinate[1]>0) {
                                    mvc.coordinate = (coordinate[0], coordinate[1])
                                }
                                
                            }
                        }
                        
                        mvc.houseTitle = houseItemDetail.valueForKey("title") as? String
                        mvc.houseAddres = houseItemDetail.valueForKey("addr") as? String
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
                            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                action: GAConst.Action.UIActivity.ViewSource,
                                label: String(houseItem.source))
                        }
                    }
                }
            default: break
            }
        }
    }
    
}

// MARK: - MFMailComposeViewControllerDelegate
// Handle Mail Sending Results
extension HouseDetailViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError?) {
        
        var success = false
        
        switch result {
        case MFMailComposeResultCancelled:
            Log.debug("Mail cancelled")
        case MFMailComposeResultSaved:
            Log.debug("Mail saved")
        case MFMailComposeResultSent:
            success = true
            Log.debug("Mail sent")
            if let houseId = self.houseItem?.id {
                CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
            }
        case MFMailComposeResultFailed:
            Log.debug("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
            action: GAConst.Action.UIActivity.Contact,
            label: GAConst.Label.Contact.Email,
            value:  UInt(success))
        
        //self.navigationController?.popViewControllerAnimated(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - Table View Data Source
extension HouseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableRows.count
    }
    
    //    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //        if var cellInfo = tableRows[indexPath.row] {
    //            Log.debug("heightForRowAtIndexPath> Height: %f for Row: %d", cellInfo.cellHeight, indexPath.row)
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
                
                Log.debug("Content Layout Height: \(contentHeight)")
                Log.debug("Label Layout Height: \(labelHeight)")
                
                cellInfo.cellHeight = max(cellInfo.cellHeight, contentHeight)
                cellInfo.cellHeight = max(cellInfo.cellHeight, cell.contentLabel.intrinsicContentSize().height)
                
                tableRows[indexPath.row] = cellInfo
                
                Log.debug("IntrinsicContentSize Height: \(cell.contentLabel.intrinsicContentSize().height) for Row: \(indexPath.row)")
                
                Log.debug("Updated Cell Height: \(cellInfo.cellHeight) for Row: \(indexPath.row)")
            }
            
            Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")
            
            return cell
            
        } else {
            assert(false, "No cellInfo for the row = \(indexPath.row)")
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let cell = cell as? HouseDetailTitleViewCell {
            
            Log.debug("willDisplayCell: \(cell)")
            
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
                
                // Config navigation left bar
                browser.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"cancel"), style: .Plain, target: self, action: #selector(HouseDetailViewController.onClosePhotoBrowser(_:)))
                
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
                    Log.debug("Set Show for Row \(nextRow)")
                    nextCellInfo?.hidden = false
                } else {
                    Log.debug("Set Hide for Row \(nextRow)")
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
    
//    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//        
//        self.bannerView.rootViewController = self
//        self.bannerView.adSize = kGADAdSizeBanner
//        //self.bannerView.delegate = self
//        
//        //FBAdSettings.addTestDevices(fbTestDevice)
//        
//        #if DEBUG
//            //Test adUnit
//            self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
//        #else
//            //Real adUnit
//            //self.bannerView.adUnitID = "ca-app-pub-7083975197863528/2369456093"
//            self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
//        #endif
//        
//        let request = GADRequest()
//        
//        self.bannerView.loadRequest(request)
//        
//        let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 120))
//        footerView.addSubview(self.bannerView)
//        
//        return footerView
//    }
//    
//    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        return 120.0
//    }

    
    
}

// MARK: - MWPhotoBrowserDelegate
// Provide photos for photo browser
extension HouseDetailViewController: MWPhotoBrowserDelegate {
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        
        if let houseItemDetail = self.houseItemDetail,
            let imgList = houseItemDetail.valueForKey("img") as? [String]{
                
                return UInt(imgList.count)
        } else {
            return 0
        }
    }
    
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        
        let photoIndex: Int = Int(index)
        
        if let houseItemDetail = self.houseItemDetail,
            let imgList = houseItemDetail.valueForKey("img") as? [String]{
                
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
        
        if let houseItemDetail = self.houseItemDetail,
            let imgList = houseItemDetail.valueForKey("img") as? [String] {
                
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

// MARK: - GADBannerViewDelegate
extension HouseDetailViewController: GADBannerViewDelegate {
    
    internal func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Log.enter()
        Log.error("Banner adapter class name: \(bannerView.adNetworkClassName)")
    }
    internal func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Log.error("\(error)")
    }
    internal func adViewWillPresentScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewDidDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        Log.enter()
    }
}
