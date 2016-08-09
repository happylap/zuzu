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
import SafariServices
import Alamofire
import JKNotificationPanel
//import CWStatusBarNotification

private let Log = Logger.defaultLogger

@objc protocol HouseDetailViewDelegate {
    
    optional func onHouseItemStateChanged()
    
    optional func onHouseItemLoaded(result: Bool)
    
}

class HouseDetailViewController: UIViewController {
    
    // MARK: - Private Fields
    private static var alertViewResponder: SCLAlertViewResponder?
    private var networkErrorAlertView: SCLAlertView? = SCLAlertView()
    
    private var phoneNumberDic = [String:String]() /// display string : original number
    
    private struct HouseDetailCache {
        static let cacheName = "houseDetailCache"
        static let cacheTime: Double = 3 * 60 * 60 //3 hours
    }
    
    private struct SourceCheckCache {
        static let cacheName = "sourceCheckCache"
        static let cacheTime: Double = 0.5 * 60 * 60 //1 hours
    }
    
    private let houseTypeLabelMaker: LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
    private let cellIdentifier = "houseDetailTitleCell"
    private var tableRows: [CellInfo]!
    
    private var experimentData = TagUtils.getMoverExperiment()
    
    private var photos = [MWPhoto]()
    
    //private let houseItemNotification = CWStatusBarNotification()
    
    @IBOutlet weak var cacheNoticeLabel: UILabel!
    
    private let notificationBar = JKNotificationPanel()
    
    private static var alamoFireManager: Alamofire.Manager = {
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36"
        ]
        
        configuration.timeoutIntervalForRequest = 4 // seconds
        configuration.timeoutIntervalForResource = 8
        return Alamofire.Manager(configuration: configuration)
        
    }()
    
    private var alamoFireRequest: Alamofire.Request?
    
    // MARK: - Public Fields
    
    /// @Controller Input Params
    var houseItem: HouseItem?
    
    ///The full house detail returned from remote server
    var houseItemDetail: AnyObject?
    
    var delegate: HouseDetailViewDelegate?
    
    enum CellIdentifier: String {
        case HouseDetailTitleCell = "houseDetailTitleCell"
        case PriceSizeCell = "priceSizeCell"
        case RightDetailCell = "rightDetailCell"
        case AddressCell = "addressCell"
        case MoverCell = "moverCell"
        case ExpandableHeaderCell = "expandableHeaderCell"
        case ExpandableContentCell = "expandableContentCell"
        case ExpandableContentAdCell = "expandableContentAdCell"
    }
    
    
    struct CellInfo {
        let cellIdentifier: CellIdentifier
        var hidden: Bool
        var cellHeight: CGFloat
        let handler: (UITableViewCell) -> ()
    }
    
    class HouseUrl: NSObject, UIActivityItemSource {
        
        var houseUrl: NSURL
        
        init(houseUrl: NSURL) {
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
        
        var houseText: String
        
        init(houseText: String) {
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
        static let sectionNum: Int = 1
    }
    
    struct ViewTransConst {
        static let displayHouseOnMap: String = "displayHouseOnMap"
        static let displayHouseSource: String = "displayHouseSource"
    }
    
    @IBOutlet weak var contactBarView: HouseDetailContactBarView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private Utils
    
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
            
            let optionMenu = UIAlertController(title: nil, message: message, preferredStyle: .ActionSheet)
            
            
            if let phoneNumbers = houseDetail.valueForKey("phone") as? [String] {
                
                ///Add only first 3 numbers
                for phoneNumber in phoneNumbers.prefix(3) {
                    
                    var phoneDisplayString = phoneNumber
                    let phoneComponents = phoneNumber.componentsSeparatedByString(PhoneExtensionChar)
                    
                    /// Convert to human-redable display format for phone number with extension
                    if(phoneComponents.count == 2) {
                        phoneDisplayString = phoneComponents.joinWithSeparator(DisplayPhoneExtensionChar)
                    } else if (phoneComponents.count > 2) {
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
    
    private func displayCacheNotice() {
        
        var sourceName = "原始房源"
        
        if let source = self.houseItem?.source {
            
            sourceName = houseTypeLabelMaker.fromCodeForField("source", code: source, defaultValue: "原始房源")
            
            self.cacheNoticeLabel.text = "本頁為\(sourceName)快取資料，聯繫屋主請以原始網頁資料為準"
            
        }
        
    }
    
    ///TODO: Not used for now
    private func displayDetailedCacheNotice() {
        
        /*
         var sourceName = "原始房源"
         
         if let houseItemDetail = self.houseItemDetail,
         source = houseItemDetail.valueForKey("source") as? Int,
         updateTime = houseItemDetail.valueForKey("update_time") as? String {
         
         sourceName = houseTypeLabelMaker.fromCodeForField("source", code: source, defaultValue: "原始房源")
         
         if let utcTime = CommonUtils.getUTCDateFromString(updateTime),
         let localTime = CommonUtils.getCustomStringFromDate(utcTime, format: "yyyy-MM-dd HH:mm", timezone: NSTimeZone.localTimeZone()) {
         
         self.houseItemNotification.displayNotificationWithMessage("本頁為\(sourceName)暫存檔，更新時間：\(localTime)") {
         
         }
         
         } else {
         
         self.houseItemNotification.displayNotificationWithMessage("本頁為\(sourceName)暫存檔，聯繫屋主請以原始網頁資料為準") {
         
         }
         }
         
         }
         */
    }
    
    private func hideDetailedCacheNotice() {
        /*
         self.houseItemNotification.notificationWindow?.hidden = true
         self.houseItemNotification.dismissNotification()
         */
    }
    
    private func startCheckSourceAvailability(url: String) {
        
        do {
            let cache = try Cache<NSHTTPURLResponse>(name: SourceCheckCache.cacheName)
            
            cache.setObjectForKey(url, cacheBlock: { successCallback, failureCallback in
                
                /// Check source availability from remote
                self.alamoFireRequest = HouseDetailViewController.alamoFireManager.request(Alamofire.Method.GET, url).responseString { (request, response, result) in
                    
                    if(result.isFailure) {
                        
                        failureCallback(nil)
                        
                        Log.error("Cannot get item = \(url)")
                        
                        return
                    }
                    
                    if let response = response {
                        
                        Log.error("[[response]] = \n \(response)")
                        
                        successCallback(response, .Seconds(SourceCheckCache.cacheTime)) // Cache response for 30 minutes
                        
                    }
                }
                
                }, completion: { object, isLoadedFromCache, error in
                    
                    /// Check response (either from cache or not)
                    if let code = object?.statusCode {
                        
                        Log.error("Item response, isCache = \(isLoadedFromCache), code = \(code)")
                        
                        switch(code) {
                        case 302, 404:
                            self.showItemRemovedNotice()
                            break
                        default:
                            break
                        }
                        
                    }
            })
            
        } catch _ {
            Log.debug("Something went wrong with the cache")
        }
    }
    
    
    private func stopCheckSourceAvailability() {
        
        self.alamoFireRequest?.cancel()
        
        self.notificationBar.dismissNotify()
        
    }
    
    private func showItemRemovedNotice() {
        
        let defaultView = notificationBar.defaultView(JKType.WARNING, message: "提醒您，此物件可能已經從原始房源下架")
        defaultView.setColor(UIColor.colorWithRGB(0xFF6666))
        
        notificationBar.delegate = self
        notificationBar.timeUntilDismiss = 3.5
        notificationBar.enableTapDismiss = false
        
        if let navigationController = self.navigationController {
            notificationBar.showNotify(withView: defaultView, belowNavigation: navigationController)
        }
        
        ///GA Tracker: Item Removed Notice
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                        action: GAConst.Action.UIActivity.RemovedItemNotice, label: houseItem?.id ?? "")
        
    }
    
    private func handleHouseDetailResponse(result: AnyObject) {
        
        self.houseItemDetail = result
        
        /// Check is item removed / sold
        if let houseDetail = self.houseItemDetail,
            url = houseDetail.valueForKey("link") as? String {
            
            if(TagUtils.shouldCheckSource()) {
                self.startCheckSourceAvailability(url)
            }
        }
        
        let defaultTitle = "豬豬大台北微搬家—跑多遠、算多少，最划算!"
        
        /// Enable experiment only for Taipei/New Taipei city
        if let data = self.experimentData {
            if let houseDetail = self.houseItemDetail,
                let city = houseDetail.valueForKey("city") as? Int
                where city == 100 || city == 207 {
                
                let moverCell = CellInfo(cellIdentifier: .MoverCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                    if let cell = cell as? HouseDetailMoverCell {
                        
                        if let title = data.title {
                            cell.detailLabel.text = title
                        } else {
                            cell.detailLabel.text = defaultTitle
                        }
                        
                    }
                })
                
                tableRows.insert(moverCell, atIndex: 1)
                
                ///GA Tracker: Campaign Displayed
                self.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                action: GAConst.Action.Campaign.MicroMovingDisplay, label: data.title ?? defaultTitle)
            }
        }
        
        
        ///Reload Table View
        self.tableView.reloadData()
        
        ///Configure Views On Data Loaded
        self.configureViewsOnDataLoaded()
        
        ///Display cache data notice
        self.runOnMainThreadAfter(1.0) {
            
        }
        
        self.enableNavigationBarItems()
    }
    
    
    private func fetchHouseDetail(houseItem: HouseItem) {
        
        var hitCache = false
        
        do {
            let cache = try Cache<NSData>(name: HouseDetailCache.cacheName)
            
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
            
            HouseDataRequestService.getInstance().searchById(houseItem.id) { (result, error) -> Void in
                
                LoadingSpinner.shared.stop()
                
                
                if let error = error {
                    Log.debug("Cannot get remote data \(error.localizedDescription)")
                    
                    if let alertView = self.networkErrorAlertView {
                        let subTitle = "您目前可能處於飛航模式或是無網路狀態，暫時無法檢視詳細資訊。"
                        alertView.showCloseButton = true
                        alertView.showInfo("網路無法連線", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                    }
                    
                    self.delegate?.onHouseItemLoaded?(false)
                    
                    return
                }
                
                self.delegate?.onHouseItemLoaded?(true)
                
                if let result = result {
                    
                    ///Try to cache the house detail response
                    do {
                        let cache = try Cache<NSData>(name: HouseDetailCache.cacheName)
                        let cachedData = NSKeyedArchiver.archivedDataWithRootObject(result)
                        cache.setObject(cachedData, forKey: houseItem.id, expires: CacheExpiry.Seconds(HouseDetailCache.cacheTime))
                        
                    } catch _ {
                        Log.debug("Something went wrong with the cache")
                    }
                    
                    self.handleHouseDetailResponse(result)
                    
                } else {
                    
                    self.alertItemNotFound()
                    
                }
            }
            
        }
    }
    
    private func setupTableCells() {
        
        tableRows = [
            CellInfo(cellIdentifier: .HouseDetailTitleCell, hidden: false, cellHeight: 213, handler: { (cell: UITableViewCell) -> () in
                if let cell = cell as? HouseDetailTitleViewCell {
                    
                    if let houseItemDetail = self.houseItemDetail {
                        var data = JSON(houseItemDetail)
                        let imgList = data["img"].arrayObject as? [String] ?? [String]()
                        
                        cell.carouselView.imageUrls = imgList
                        cell.carouselView.tapHandler = { () -> Void in
                            Log.debug("carouselView.tapHandler")
                            
                            let rowToSelect: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0);  //slecting 0th row with 0th section
                            //self.tableView.selectRowAtIndexPath(rowToSelect, animated: true, scrollPosition: UITableViewScrollPosition.None);
                            self.tableView(self.tableView, didSelectRowAtIndexPath: rowToSelect)
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
            CellInfo(cellIdentifier: .PriceSizeCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailPriceSizeCell {
                    
                    var priceDetail: String?
                    if let houseItemDetail = self.houseItemDetail {
                        
                        let attributes = [
                            NSBackgroundColorAttributeName: UIColor.colorWithRGB(0xFFFFFF),
                            NSForegroundColorAttributeName: UIColor.colorWithRGB(0xFF6666),
                            NSFontAttributeName: UIFont.systemFontOfSize(15)
                        ]
                        
                        /// Show previous price
                        if let prevPrice = houseItemDetail.valueForKey("previous_price") as? Int {
                            
                            let myMutableString = NSMutableAttributedString(string: "\(prevPrice)↯", attributes: attributes)
                            
                            myMutableString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSRange(location:0, length:myMutableString.string.characters.count-1))
                            
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
                            cell.priceLabel.text = "\(price) 元/月"
                        }
                        
                        if let size = houseItemDetail.valueForKey("size") as? Float {
                            cell.sizeLabel.font = UIFont.boldSystemFontOfSize(cell.sizeLabel.font.pointSize)
                            
                            /// Round the size to the second place
                            let multiplier: Float = pow(10.0, 2)
                            cell.sizeLabel.text = "\(round(size * multiplier)/multiplier) 坪"
                        }
                    } else {
                        ///Before data is loaded
                        cell.priceDetailLabel.text = " " //To reserve the height
                        cell.priceDetailLabel.hidden = false
                    }
                }
            }),
            CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var houseTypeString = String()
                        var purposeTypeString = String()
                        
                        if let houseType = houseDetail.valueForKey("house_type") as? Int {
                            houseTypeString = self.houseTypeLabelMaker.fromCodeForField("house_type", code: houseType, defaultValue: "")
                        }
                        
                        if let purposeType = houseDetail.valueForKey("purpose_type") as? Int {
                            purposeTypeString = self.houseTypeLabelMaker.fromCodeForField("purpose_type", code: purposeType, defaultValue: "")
                        }
                        
                        cell.leftInfoText.text = "\(houseTypeString) / \(purposeTypeString)"
                        
                        var parkingTypeLabel = "—"
                        
                        if let hasParking = houseDetail.valueForKey("parking_lot") as? Bool {
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
            CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var floorLabel = "—"
                        
                        let floorList = houseDetail.valueForKey("floor") as? [Int] ?? []
                        
                        /// Has floor
                        if let floorLow = floorList.first, floorHigh = floorList.last {
                            
                            var totalFloorLabel = "—"
                            
                            if let total_floor = houseDetail.valueForKey("total_floor") as? Int {
                                
                                totalFloorLabel = "\(total_floor)"
                                
                            }
                            
                            let floorLowLabel = (floorLow < 0) ? "B\(-floorLow)" : "\(floorLow)"
                            
                            if(floorLow == floorHigh) {
                                floorLabel = "\(floorLowLabel) / \(totalFloorLabel)"
                            } else {
                                floorLabel = "\(floorLowLabel)~\(floorHigh) / \(totalFloorLabel)"
                            }
                            
                        } else {
                            /// No floor
                            if let total_floor = houseDetail.valueForKey("total_floor") as? Int {
                                
                                floorLabel = "— / \(total_floor)"
                                
                            }
                        }
                        
                        cell.leftInfoText.text = "樓層: \(floorLabel)"
                        
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
            CellInfo(cellIdentifier: .RightDetailCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        let community = houseDetail.valueForKey("community") as? String ?? "—"
                        cell.leftInfoText.text = "社區: \(community)"
                        
                        var mgmtFeeString = "—"
                        
                        if let hasMgmt = houseDetail.valueForKey("has_mgmt_fee") as? Bool where hasMgmt == true {
                            
                            if let mgmtFee = houseDetail.valueForKey("mgmt_fee") as? Int {
                                mgmtFeeString = "\(mgmtFee) 元"
                            } else {
                                mgmtFeeString = "有"
                            }
                            
                        }
                        
                        cell.rightInfoText.text = "管理費: \(mgmtFeeString)"
                        
                    }
                }
            }),
            CellInfo(cellIdentifier: .AddressCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailAddressCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        cell.addressLabel.text = houseDetail.valueForKey("addr") as? String
                    } else {
                        cell.addressLabel.text = " " //To reserve the height
                    }
                    
                }
            }),
            CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "提供物品"
                }
            }),
            CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString = String()
                        
                        if let furnitureList = houseDetail.valueForKey("furniture") as? [Int] {
                            
                            let furnitureStringList = furnitureList.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("furniture", code: code, defaultValue: "—")
                            }
                            
                            resultString += furnitureStringList.joinWithSeparator("; ") + "\n\n"
                        }
                        
                        if let facilityList = houseDetail.valueForKey("facility") as? [Int] {
                            let facilityStringList = facilityList.map { (code) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("facility", code: code, defaultValue: "—")
                            }
                            
                            resultString += facilityStringList.joinWithSeparator("; ")
                        }
                        
                        if(resultString.characters.count > 0) {
                            cell.contentLabel.text = resultString
                            cell.contentLabel.text = "\(resultString)\n"
                        } else {
                            cell.contentLabel.text = "無資訊\n"
                        }
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                    
                }
            }),
            CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "生活機能"
                }
            }),
            CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString = String()
                        
                        if let surroundingList = houseDetail.valueForKey("surrounding") as? [Int] {
                            
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
            CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "租屋限制"
                }
            }),
            CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    if let houseDetail = self.houseItemDetail {
                        
                        var resultString = String()
                        
                        /// Profile / Sex Restrictions
                        
                        if let profiles = houseDetail.valueForKey("restr_profile") as? [Int] {
                            let profilesStringList = profiles.map { (profileCode) -> String in
                                self.houseTypeLabelMaker.fromCodeForField("restr_profile", code: profileCode, defaultValue: "")
                            }
                            resultString += "身份限制：" + profilesStringList.joinWithSeparator("; ") + "\n"
                        }
                        
                        if let sex = houseDetail.valueForKey("restr_sex") as? Int {
                            if let sexString = self.houseTypeLabelMaker.fromCodeForField("restr_sex", code: sex) {
                                
                                resultString += "限\(sexString)性" + "\n"
                            }
                        }
                        
                        /// Other Restrictions: Allow Pet, Allow Cooking
                        var restrictionList = [String]()
                        
                        if let allow_pet = houseDetail.valueForKey("allow_pet") as? Bool {
                            
                            restrictionList.append( (allow_pet ? "可養寵物" : "不可養寵物"))
                        }
                        
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
            CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "其他資訊"
                }
            }),
            CellInfo(cellIdentifier: .ExpandableContentCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                    
                    var otherInfoList = [String]()
                    if let houseDetail = self.houseItemDetail {
                        otherInfoList.append("隔間材料: \( (houseDetail.valueForKey("wall_mtl") as? String ?? "—") )")
                        
                        var orientationStr = "—"
                        if let orientation = houseDetail.valueForKey("orientation") as? Int {
                            orientationStr = self.houseTypeLabelMaker.fromCodeForField("orientation", code: orientation, defaultValue: "")
                        }
                        
                        otherInfoList.append("房屋朝向: \(orientationStr)")
                        
                        
                        var readyDateStr = "—"
                        if let readyDate = houseDetail.valueForKey("ready_date") as? String {
                            if let dateEnd = readyDate.characters.indexOf("T") {
                                readyDateStr = String(readyDate.characters.prefixUpTo(dateEnd))
                            }
                        }
                        
                        otherInfoList.append("可遷入日: \(readyDateStr)")
                        
                        var updateDateStr = "—"
                        if let updateTime = houseDetail.valueForKey("update_time") as? String {
                            if let utcTime = CommonUtils.getUTCDateFromString(updateTime),
                                let localTime = CommonUtils.getCustomStringFromDate(utcTime, format: "yyyy-MM-dd HH:mm", timezone: NSTimeZone.localTimeZone()) {
                                updateDateStr = localTime
                                
                            }
                        }
                        
                        #if DEBUG
                            otherInfoList.append("資料更新: \(updateDateStr)")
                            
                            if(otherInfoList.count > 0) {
                                cell.contentLabel.text = otherInfoList.joinWithSeparator("\n") + "\n"
                            } else {
                                cell.contentLabel.text = "無資訊\n"
                            }
                        #endif
                        
                        
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                }
            }),
            CellInfo(cellIdentifier: .ExpandableHeaderCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    cell.headerLabel.text = "屋主說明"
                }
            }),
            CellInfo(cellIdentifier: .ExpandableContentAdCell, hidden: false, cellHeight: 55, handler: { (cell) -> () in
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
                        
                        Log.debug("Frame Height: \(cell.contentLabel.frame.height)")
                    } else {
                        cell.contentLabel.text = "無資訊\n"
                    }
                    
                    if(TagUtils.shouldDisplayADs()) {
                        if(cell.isAdSupported) {
                            
                            if(TagUtils.shouldDisplayVideoADs()) {
                                /// Display VMFiveAdNetwork ADs
                                cell.setVideoAdBanner(self)
                            } else {
                                /// Display ADMOB, FACEBOOK, MOPUB ADs
                                cell.setAdBanner(self)
                            }
                            
                        }
                    }
                }
            })
        ]
    }
    
    private func alertItemNotFound() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "請您參考其他物件，謝謝！"
        
        alertView.showCloseButton = false
        
        alertView.addButton("知道了") {
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertView.showInfo("此物件已下架", subTitle: subTitle, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    
    private func alertAddingToCollectionSuccess() {
        
        if(!UserDefaultsUtils.needsMyCollectionPrompt()) {
            return
        }
        
        let alertView = SCLAlertView()
        
        let subTitle = "成功加入一筆租屋到\"我的收藏\"\n現在去看看收藏項目嗎？"
        
        alertView.addButton("馬上去看看") {
            UserDefaultsUtils.disableMyCollectionPrompt()
            
            NSNotificationCenter.defaultCenter().postNotificationName(SwitchToTabNotification, object: self, userInfo: ["targetTab" : MainTabConstants.COLLECTION_TAB_INDEX])
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
    
    //TODO: Not used for now
    private func configureNotificationBar() {
        /*
         self.houseItemNotification.notificationAnimationInStyle = .Top
         self.houseItemNotification.notificationLabelBackgroundColor = UIColor.colorWithRGB(0xF5AA00)
         self.houseItemNotification.notificationLabelTextColor = UIColor.whiteColor()
         self.houseItemNotification.notificationStyle = .StatusBarNotification
         */
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
        tableView.tableFooterView = UIView(frame: CGRect.zero)
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
        contactBarView.contactByMailButton.removeFromSuperview()
        
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
        self.performSegueWithIdentifier(ViewTransConst.displayHouseSource, sender: self)
    }
    
    func contactNameTouched(sender: UITapGestureRecognizer) {
        self.performSegueWithIdentifier(ViewTransConst.displayHouseSource, sender: self)
    }
    
    func contactByPhoneButtonTouched(sender: UIButton) {
        self.performSegueWithIdentifier(ViewTransConst.displayHouseSource, sender: self)
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
    
    private func performCollectionDeletion(houseID: String) {
        
        CollectionItemService.sharedInstance.deleteItemById(houseID)
        
        if let barItem = self.navigationItem.rightBarButtonItems?.first?.customView as? UIButton {
            barItem.setImage(UIImage(named: "heart_toolbar_n"), forState: UIControlState.Normal)
        }
        
        ///Notify the search result table to refresh the selected row
        delegate?.onHouseItemStateChanged?()
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                                        action: GAConst.Action.MyCollection.Delete)
        
    }
    
    func collectButtonTouched(sender: UIButton) {
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self) {
                (task: AWSTask!) -> AnyObject! in
                return nil
            }
            return
        }
        
        if let houseItemDetail = self.houseItemDetail,
            let houseID = houseItemDetail.valueForKey("id") as? String {
            
            
            
            let collectionService = CollectionItemService.sharedInstance
            
            ///Determine action based on whether the house item is already in "My Collection"
            if(collectionService.isExist(houseID)) {
                
                /// Ask for user confirmation if there exists notes for this item
                if(NoteService.sharedInstance.hasNote(houseID)) {
                    
                    let alertView = SCLAlertView()
                    
                    alertView.addButton("確認移除") {
                        
                        self.performCollectionDeletion(houseID)
                        
                    }
                    
                    alertView.showNotice("是否確認移除", subTitle: "此物件包含您撰寫筆記，將此物件從「我的收藏」中移除會一併將筆記刪除，是否確認？", closeButtonTitle: "暫時不要", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                    
                    return
                }
                
                self.performCollectionDeletion(houseID)
                
            } else {
                
                if !CollectionItemService.sharedInstance.canAdd() {
                    let subTitle = "您目前的收藏筆數已達上限\(CollectionItemService.CollectionItemConstants.MYCOLLECTION_MAX_SIZE)筆。"
                    SCLAlertView().showInfo("提醒您", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                    return
                }
                
                if let barItem = self.navigationItem.rightBarButtonItems?.first?.customView as? UIButton {
                    barItem.setImage(UIImage(named: "heart_pink"), forState: UIControlState.Normal)
                }
                
                LoadingSpinner.shared.stop()
                LoadingSpinner.shared.setImmediateAppear(false)
                LoadingSpinner.shared.setGraceTime(1.0)
                LoadingSpinner.shared.setOpacity(0.3)
                LoadingSpinner.shared.startOnView(self.view)
                Log.debug("LoadingSpinner startOnView")
                
                HouseDataRequestService.getInstance().searchById(houseID) { (result, error) -> Void in
                    LoadingSpinner.shared.stop()
                    Log.debug("LoadingSpinner stop")
                    
                    if let error = error {
                        let alertView = SCLAlertView()
                        alertView.showCloseButton = false
                        
                        alertView.addButton("知道了") {
                            if let barItem = self.navigationItem.rightBarButtonItems?.first?.customView as? UIButton {
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
        
        ///Init Style
        self.configureNotificationBar()
        
        ///Start Loading
        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.startOnView(view)
        
        ///Init Contact Bar View
        initContactBarView()
        
        ///Configure navigation bar items
        configureNavigationBarItems()
        
        ///Prepare table view
        setupTableCells()
        
        configureTableView()
        
        ///Get remote data
        if let houseItem = self.houseItem {
            fetchHouseDetail(houseItem)
        }
        
        ///Display cache data notice
        self.displayCacheNotice()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ///Hide tab bar
        self.tabBarController?.tabBarHidden = true
        
        ///Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        ///Display tab bar
        self.tabBarController?.tabBarHidden = false
        
        ///Do not need to display alert once the view controller is not in the foreground
        self.networkErrorAlertView = nil
        
        LoadingSpinner.shared.stop()
        
        if(TagUtils.shouldCheckSource()) {
            self.stopCheckSourceAvailability()
        }
        
        // self.hideDetailedCacheNotice()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Controller Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            
            Log.debug("prepareForSegue: \(identifier)")
            
            let item = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem = item
            
            switch identifier {
                
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
                        bvc.viewTitle = "原始網頁"
                        
                        if let houseItemDetail = self.houseItemDetail {
                            bvc.houseItem = self.houseItem
                            bvc.agentName = houseItemDetail.valueForKey("agent") as? String
                            bvc.agentType = houseItemDetail.valueForKey("agent_type") as? Int
                            bvc.agentPhoneList = houseItemDetail.valueForKey("phone") as? [String]
                            bvc.agentMail = houseItemDetail.valueForKey("email") as? String
                        }
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

// MARK: - Table View Data Source
extension HouseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableRows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cellInfo = tableRows[indexPath.row]
        
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
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if let myCell = cell as? HouseDetailTitleViewCell {
            
            Log.debug("willDisplayCell: \(myCell)")
            
            let label: MarqueeLabel =  myCell.houseTitleLabel as! MarqueeLabel
            label.restartLabel()
            
        } else if let myCell = cell as? HouseDetailExpandableContentCell where myCell.isAdBannerEnabled {
            
            Log.debug("willDisplayCell: \(myCell)")
            
            myCell.loadBanner()
            
        } else if let myCell = cell as? HouseDetailExpandableContentCell where myCell.isVideoAdBannerEnabled {
            
            Log.debug("willDisplayCell: \(myCell)")
            
            myCell.loadVideoBanner()
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cellInfo = tableRows[indexPath.row]
        
        switch(cellInfo.cellIdentifier) {
        case .MoverCell:
            LoadingSpinner.shared.startOnView(self.view)
            
            var moverLandingPage = "http://bit.ly/299e995"
            
            if let promotionUrl = self.experimentData?.url {
                
                moverLandingPage = promotionUrl
                
            }
            
            if #available(iOS 9.0, *) {
                let svc = SFSafariViewController(URL: NSURL(string: moverLandingPage)!)
                self.presentViewController(svc, animated: true, completion: nil)
                
                ///GA Tracker: Campaign Displayed
                self.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                action: GAConst.Action.Campaign.MicroMovingClick, label: self.experimentData?.title ?? "")
            } else {
                // Fallback on earlier versions
                
                let browserViewController = self.storyboard?.instantiateViewControllerWithIdentifier("browserView") as? BrowserViewController
                
                if let browserViewController = browserViewController {
                    browserViewController.enableToolBar = false
                    browserViewController.sourceLink = moverLandingPage
                    browserViewController.viewTitle = "豬豬搬一下"
                    //self.modalPresentationStyle = .CurrentContext
                    self.navigationController?.pushViewController(browserViewController, animated: true)
                    
                    ///GA Tracker: Campaign Displayed
                    self.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                    action: GAConst.Action.Campaign.MicroMovingClick, label: self.experimentData?.title ?? "")
                }
            }
            
        case .AddressCell:
            LoadingSpinner.shared.startOnView(self.view)
            
            ///It takes time to load the map, leave some time to display loading spinner makes the flow look smoother
            self.runOnMainThreadAfter(0.1) {
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
            browser.enableGrid = true
            
            // Whether to start on the grid view (default: false)
            browser.startOnGrid = false
            
            // Auto-play first video
            browser.autoPlayOnAppear = false
            
            browser.setCurrentPhotoIndex(0)
            
            self.navigationController?.pushViewController(browser, animated: true)
            
            self.trackScreenWithTitle("View: Image Viewer")
            
        case .ExpandableHeaderCell:
            let nextRow = indexPath.row + 1
            var nextCellInfo = tableRows[nextRow]
            
            
            if nextCellInfo.hidden == true {
                Log.debug("Set Show for Row \(nextRow)")
                nextCellInfo.hidden = false
            } else {
                Log.debug("Set Hide for Row \(nextRow)")
                nextCellInfo.hidden = true
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

// MARK: - MWPhotoBrowserDelegate
// Provide photos for photo browser
extension HouseDetailViewController: MWPhotoBrowserDelegate {
    func numberOfPhotosInPhotoBrowser(photoBrowser: MWPhotoBrowser!) -> UInt {
        
        if let houseItemDetail = self.houseItemDetail,
            let imgList = houseItemDetail.valueForKey("img") as? [String] {
            
            return UInt(imgList.count)
        } else {
            return 0
        }
    }
    
    
    func photoBrowser(photoBrowser: MWPhotoBrowser!, photoAtIndex index: UInt) -> MWPhotoProtocol! {
        
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


// MARK: - JKNotificationPanelDelegate
extension HouseDetailViewController: JKNotificationPanelDelegate {
    
    func notificationPanelDidDismiss () {
        // Dismissed
    }
    
    func notificationPanelDidTap() {
        // Tapped
    }
}

// MARK: - Scroll View Delegate
extension HouseDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // self.hideDetailedCacheNotice()
    }
}
