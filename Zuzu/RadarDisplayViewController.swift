//
//  RadarDisplayViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/4.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView
import Charts

private let Log = Logger.defaultLogger

class RadarDisplayViewController: UIViewController {
    
    private let RenewalThresholdDays = 3
    
    // segue to configure UI
    
    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    // Zuzu criteria variable
    
    var zuzuCriteria = ZuzuCriteria()
    
    // ZuzuService status variable
    
    var zuzuService: ZuzuServiceMapper?
    
    // Purchase History variables
    
    let emptyPurchaseHistoryLabel = UILabel()
    private lazy var purchaseHistotyTableDataSource: RadarPurchaseHistoryTableViewDataSource = RadarPurchaseHistoryTableViewDataSource()
    
    
    // Criteria UI outlet
    
    @IBOutlet weak var modifyButtoon: UIButton! // buton to update or configure criteria
    
    @IBOutlet weak var currentConditionBannerLabel: UILabel!
    
    @IBOutlet weak var criteriaEnableSwitch: UISwitch! {
        didSet {
            let ratio = getCurrentScale()
            
            criteriaEnableSwitch.transform = CGAffineTransformMakeScale(ratio, ratio)
        }
    }
    
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var otherFiltersLabel: UILabel!
    
    
    
    // ZuzuService status UI outlet
    
    @IBOutlet weak var serviceButton: UIButton! // button to renew the ZuzuService if it is expired
    
    @IBOutlet weak var serviceStatusLabel: UILabel!
    
    @IBOutlet weak var serviceExpireLabel: UILabel!
    
    @IBOutlet weak var servieBannerLabel: UILabel!
    
    @IBOutlet weak var purchaseHistoryBannerLabel: UILabel!
    
    
    @IBOutlet weak var statusImageView: UIImageView!{
        
        didSet {
            statusImageView.image = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
            statusImageView.tintColor = UIColor.lightGrayColor()
            statusImageView.hidden = true
        }
        
    }
    
    @IBOutlet weak var statusPieChart: PieChartView! {
        didSet {
            statusPieChart.descriptionText = ""
            statusPieChart.noDataText = "載入中..."
            statusPieChart.highlightPerTapEnabled = false
            statusPieChart.rotationEnabled = false
            statusPieChart.legend.enabled = false
            
            statusPieChart.drawMarkers = false
            statusPieChart.drawSliceTextEnabled = false
            statusPieChart.drawSlicesUnderHoleEnabled = false
        }
    }
    
    // Purchase hstory UI outlet
    
    @IBOutlet weak var purchaseTableView: UITableView!
    
    
    // MARK: - Private Utils
    
    private func alertLocalNotificationDisabled() {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "請到：設定 > 通知 > 豬豬快租\n開啟「允許通知」選項\n才能接收租屋雷達通知物件"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("尚未授權通知功能", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func alertPushNotificationDisabled() {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "遠端通知功能開啟失敗，請您重新開啟豬豬快租，並再次進入「租屋雷達」，謝謝！"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("通知功能尚未開啟", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func toggleServiceStatusIcon(isValid: Bool) {
        
        statusImageView.hidden = false
        
        if(isValid) {
            statusImageView.image = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            statusImageView.image = UIImage(named: "comment-alert-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize
        self.serviceButton?.hidden = true
        self.serviceStatusLabel?.text = ""
        self.serviceExpireLabel?.text = ""
        self.configureButton()
        self.configureBannerText()
        self.configurePurchaseTableView()
        
        // purchase history only refresh in view load
        self.purchaseHistotyTableDataSource.purchaseHistoryTableDelegate = self
        self.purchaseHistotyTableDataSource.refresh(nil)

        if self.zuzuCriteria.criteriaId == nil{
            SCLAlertView().showInfo("請即啟用", subTitle: "您的租屋雷達服務已在作用中，\n請立即設定租屋雷達條件並啟用，\n以維護您的權益，謝謝！", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return
        }
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            /// Enable Remote Notifications
            if(UIApplication.sharedApplication().isRegisteredForRemoteNotifications()) {
                Log.debug("Remote Notifications Registered = Y")
                /// Enable Local App Notifications
                appDelegate.setupLocalNotifications({ (result) -> () in
                    if(!result) {
                        self.alertLocalNotificationDisabled()
                    }
                })
                
            } else {
                Log.debug("Remote Notifications Registered = N")
                
                appDelegate.setupPushNotifications({ (result) -> () in
                    
                    if(result) {
                        
                        /// Enable Local App Notifications
                        appDelegate.setupLocalNotifications({ (result) -> () in
                            if(!result) {
                                self.alertLocalNotificationDisabled()
                            }
                        })
                        
                    } else {
                        self.alertPushNotificationDisabled()
                    }
                    
                })
                
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Log.debug("viewWillAppear")
        
        self.criteriaEnableSwitch?.on = self.zuzuCriteria.enabled ?? false
        
        // update criteria UI according to zuzuCriteria
        self.updateCriteriaTextLabel()
        
        // update service UI according to zuzuService
        self.updateServiceUI()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
        
         /// When there are some unfinished transactions
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.alertCompleteUnfinishTransactions(unfinishedTranscations)
        }
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
                
            case ViewTransConst.showConfigureRadar:
                if let vc = segue.destinationViewController as? RadarViewController {
                    self.navigationItem.backBarButtonItem?.title = "返回"
                    vc.delegate = self
                    vc.criteiraId = self.zuzuCriteria.criteriaId
                    vc.isUpdateMode = true
                    if let radarSearchCriteria = self.zuzuCriteria.criteria{
                        vc.radarSearchCriteria = radarSearchCriteria
                    }
                    
                }
            default: break
                
            }
        }
    }
    
    // MARK: - Reload to RadarNavigationController
    
    func reloadRadarUI(){
        if let navigation = self.navigationController as? RadarNavigationController{
            // set nil criteria to navigation controller to re-get criteria
            navigation.zuzuCriteria = nil
            
            navigation.showRadar(){
                self.updateCriteriaTextLabel()
                self.updateServiceUI()
            }
        }
    }
    
    // MARK: - Enable / Disable Criteria action
    
    @IBAction func enableCriteria(sender: UISwitch) {
        
        let isEnabled = sender.on
        
        if self.zuzuCriteria.criteriaId == nil{
            SCLAlertView().showInfo("尚未設定租屋雷達", subTitle: "啟用前請先完成租屋雷達的設定", closeButtonTitle: "確認", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                    sender.on = !isEnabled
                }
            
            return
        }
        
        if let service = self.zuzuService{
            if let status = service.status
                where status != RadarStatus.Valid.rawValue {
                    //expired service -> show purchase modal
                    sender.on = !isEnabled
                    self.showPurchase()
                    
                    return
            }
        }
        
        self.setCriteriaEnabled(isEnabled)
    }
    
    func setCriteriaEnabled(isEnabled: Bool){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, criteriaId = self.zuzuCriteria.criteriaId{
            
            var text = "啟用中"
            if isEnabled == false{
                text = "停用中"
            }
            
            RadarService.sharedInstance.stopLoading()
            RadarService.sharedInstance.startLoadingText(self,text:text, animated:false)
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId, criteriaId: criteriaId, enabled: isEnabled) {
                (result, error) -> Void in
                
                if error != nil{
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前暫時無法為您完成此操作，請稍後再試，謝謝！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            self.setCriteriaSwitch(!isEnabled)
                        }
                        
                        return
                    }
                
                    self.setCriteriaSwitch(isEnabled)
                    RadarService.sharedInstance.stopLoading()
            }
        }else{
            self.setCriteriaSwitch(!isEnabled)
        }
    }
    
    func setCriteriaSwitch(isEnabled: Bool){
        self.zuzuCriteria.enabled = isEnabled
        self.criteriaEnableSwitch.on = isEnabled
    }
    
    // MARK: - Show Purchase action
    
    @IBAction func onServiceButtonTapped(sender: AnyObject) {
        self.showPurchase()
    }
    
    func showPurchase(){
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {

            vc.modalPresentationStyle = .OverCurrentContext
            vc.purchaseDelegate = self
            
            presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Criteria View Update Function
    
    private func updateCriteriaTextLabel(){
        
        if self.zuzuCriteria.criteria == nil{
            let text = "您的租屋雷達服務已在作用中\n請立即將租屋雷達條件設定並啟用"
            self.regionLabel?.numberOfLines = 0
            self.regionLabel?.text = text
            self.houseInfoLabel?.text = ""
            self.priceSizeLabel?.text = ""
            self.otherFiltersLabel?.text = ""
            self.modifyButtoon?.setTitle("設定雷達", forState: .Normal)
            return
        }
        
        let displayItem = RadarDisplayItem(criteria:self.zuzuCriteria.criteria!)
        self.regionLabel?.numberOfLines = 1
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.purpostString
        self.priceSizeLabel?.text = displayItem.priceSizeString
        var filterNum = 0
        if let filterGroups = self.zuzuCriteria.criteria!.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherFiltersLabel?.text = "其他 \(filterNum) 個過濾條件"
        self.modifyButtoon?.setTitle("更改條件", forState: .Normal)
    }
    
    private func disableModifyButton(){
        let disabledColor = UIColor.colorWithRGB(0xE0E0E0, alpha: 0.8)
        modifyButtoon.enabled = false
        modifyButtoon.setTitleColor(disabledColor, forState: .Normal)
        modifyButtoon.tintColor = disabledColor
        modifyButtoon.layer.borderColor = disabledColor.CGColor
    }
    
    private func enableModifyButton(){
        let enbledColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        modifyButtoon.enabled = true
        modifyButtoon.layer.borderColor = enbledColor.CGColor
        modifyButtoon.tintColor = enbledColor
        modifyButtoon.setTitleColor(enbledColor, forState: .Normal)
        modifyButtoon.setTitleColor(enbledColor, forState: .Selected)
    }
    
    // MARK: - Service View Update Function
    
    private func updateServiceUI(){
        
        if let service = self.zuzuService,
            status = service.status, remainingSeconds = service.remainingSecond, totalSeconds = service.totalSecond {
                /// Service is valid
                
                if(status == RadarStatus.Valid.rawValue) {
                    
                    let usedSeconds = totalSeconds - remainingSeconds
                    
                    self.handleServiceValidForDuration(remainingSeconds, usedSeconds: usedSeconds)
                    
                }else{
                    
                    self.handleServiceExpired()
                    
                }
                
                // Display service expiration date
                var expireDateStr = "—"
                if let expireDate = service.expireTime{
                    if let dateString = CommonUtils.getLocalShortStringFromDate(expireDate) {
                        expireDateStr = dateString
                    }
                }
                self.serviceExpireLabel?.text = "雷達服務到期日: \(expireDateStr)"

                
        } else {
            /// Service is invalid or status info not available
            
            self.serviceStatusLabel?.text = "很抱歉!無法取得租屋雷達服務狀態"
            self.serviceExpireLabel?.text = ""
            self.serviceButton?.hidden = true
            
            /// Clear Chart
            self.clearChart("無法載入資料")
            
            self.enableModifyButton()
            
        }
    }
    
    private func handleServiceExpired() {
        
        /// Update UI for service expiry
        self.serviceStatusLabel?.text = "您的租屋雷達服務已到期"
        self.criteriaEnableSwitch?.on = false
        self.serviceButton?.hidden = false
        self.disableModifyButton()
        
        // Update Chart
        self.setChart(["已使用天數","剩餘天數"], values: [10.0, 0.0], info: "已到期")
        
        toggleServiceStatusIcon(false)
        
    }
    
    private func handleServiceValidForDuration(remainingSeconds: Int, usedSeconds: Int) {
        
        /// Get precise remianings days / used days
        /// e.g. 15.5 Days
        let remainingDays = UserServiceUtils.convertSecondsToPreciseDays(remainingSeconds)
        let usedDays = UserServiceUtils.convertSecondsToPreciseDays(usedSeconds)
        
        /// Get rounded up remianings days
        /// e.g. 15.5 Days = Round-up Days: 16
        let roundUpRemainingDays = UserServiceUtils.getRoundUpDays(remainingSeconds)
        
        /// Get only hours part
        /// e.g. 15.5 Days = Hour Part: 12 (minutes are ignored)
        let roundedRemainingHoursPart  = UserServiceUtils.getHoursPart(remainingSeconds)
        
        
        /// Update UI for service valid
        var infoText: String?
        
        if(remainingDays >= 1) {
            /// More than 1 day
            
            infoText = "\(roundUpRemainingDays) 日"
            self.serviceStatusLabel?.text = "您的租屋雷達服務尚有：\(roundUpRemainingDays) 日"
            
        } else {
            /// Within 1 day
            
            if(roundedRemainingHoursPart > 0) {
                infoText = "\(roundedRemainingHoursPart) 小時"
                self.serviceStatusLabel?.text = "您的租屋雷達服務只剩：\(roundedRemainingHoursPart) 小時"
            }else {
                /// Last Hour
                infoText = "將失效"
                self.serviceStatusLabel?.text = "您的租屋雷達服務將在一小時內失效"
            }
        }
        
        // Update Chart
        self.setChart(["已使用天數","剩餘天數"],
            values: [usedDays, remainingDays],
            info: infoText ?? "")
        
        if(remainingDays <= Double(RenewalThresholdDays)) {
            self.serviceButton?.hidden = false
        }else{
            self.serviceButton?.hidden = true
        }
        
        self.enableModifyButton()
        toggleServiceStatusIcon(true)
        
    }
    
    // MARK: - Zuzu Service status chart functions
    
    /// Utils for controlling the service pie chart
    private func setChart(dataPoints: [String], values: [Double], info: String) {
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(yVals: dataEntries, label: "服務狀態")
        let pieChartData = PieChartData(xVals: dataPoints, dataSet: pieChartDataSet)
        pieChartDataSet.drawValuesEnabled = false
        statusPieChart.data = pieChartData
        statusPieChart.centerText = info
        
        let usedDays = UIColor.colorWithRGB(0xFFCC66)
        let remainingDays = UIColor.colorWithRGB(0x1CD4C6)
        
        pieChartDataSet.colors = [usedDays, remainingDays]
    }
    
    private func clearChart(noDataText: String) {
        
        statusPieChart?.noDataText = noDataText
        statusPieChart?.data = nil
        
    }
    
    // MARK: - Configure UI
    
    private func configureButton() {
        modifyButtoon.layer.borderWidth = 1
        self.enableModifyButton()
    }
    
    private func configureBannerText(){
        let color = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        self.currentConditionBannerLabel.textColor = color
        self.servieBannerLabel.textColor = color
        self.purchaseHistoryBannerLabel.textColor = color
    }
    
    private func configurePurchaseTableView(){
        self.purchaseTableView.delegate = self.purchaseHistotyTableDataSource
        self.purchaseTableView.dataSource = self.purchaseHistotyTableDataSource
        
        //self.purchaseTableView.rowHeight = UIScreen.mainScreen().bounds.width * (500/1440)
        
        self.purchaseTableView.allowsSelection = false
        
        //Remove extra cells when the table height is smaller than the screen
        
        self.purchaseTableView.tableFooterView = UIView(frame: CGRectZero)
        
        // configure empty label
        if let contentView = self.purchaseTableView {
            emptyPurchaseHistoryLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyPurchaseHistoryLabel.textAlignment = NSTextAlignment.Center
            emptyPurchaseHistoryLabel.numberOfLines = -1
            emptyPurchaseHistoryLabel.font = UIFont.systemFontOfSize(14)
            emptyPurchaseHistoryLabel.textColor = UIColor.grayColor()
            emptyPurchaseHistoryLabel.autoScaleFontSize = true
            emptyPurchaseHistoryLabel.hidden = true
            contentView.addSubview(emptyPurchaseHistoryLabel)
            
            let xConstraint = NSLayoutConstraint(item: emptyPurchaseHistoryLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let yConstraint = NSLayoutConstraint(item: emptyPurchaseHistoryLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            yConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: emptyPurchaseHistoryLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow
            
            let rightConstraint = NSLayoutConstraint(item: emptyPurchaseHistoryLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow
            
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint])
            
        }
        
    }
    
}

// MARK: - RadarViewControllerDelegate

extension RadarDisplayViewController : RadarViewControllerDelegate {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria){
        self.zuzuCriteria.criteria = searchCriteria
        self.updateCriteriaTextLabel()
    }
}

// MARK: - RadarPurchaseDelegate

extension RadarDisplayViewController: RadarPurchaseDelegate{
    
    func onPurchaseCancel() -> Void{
        // do nothing
    }
    
    func onPurchaseSuccess() -> Void{
        Log.enter()
        UserServiceStatusManager.shared.resetServiceStatusCache() // reset service cache
        
        self.enableCriteriaForPurchase()
        
        Log.exit()
    }
    
    func onFindUnfinishedTransaction(unfinishedTranscations:[SKPaymentTransaction]) -> Void{
        Log.enter()
                
        RadarService.sharedInstance.stopLoading()
        
        self.alertCompleteUnfinishTransactions(unfinishedTranscations)
        
        Log.exit()
    }
    
    func onLoggedInForPurchase() {
        assert(false, "onLoggedInForPurchase is impossible to be called-back in status UI purchase")
    }
}

// MARK: Criteria seeting function for purchase

extension RadarDisplayViewController{
    
    func enableCriteriaForPurchase(){
        
        var isEnabled = self.zuzuCriteria.enabled ?? false
        
        if self.zuzuCriteria.criteriaId == nil{
            SCLAlertView().showInfo("請即啟用", subTitle: "您的租屋雷達服務已在作用中，\n請立即設定租屋雷達條件並啟用，\n以維護您的權益，謝謝！", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, criteiraId = self.zuzuCriteria.criteriaId{
 
            if isEnabled == true{
                self.setCriteriaSwitch(isEnabled)
                
                RadarService.sharedInstance.startLoading(self)
                
                self.purchaseHistotyTableDataSource.refresh(){
                    self.reloadRadarUI()
                }
                
                return
            }
                        
            isEnabled = true
            
            RadarService.sharedInstance.startLoading(self)
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: criteiraId, enabled: isEnabled) { (result, error) -> Void in
                    
                    if error != nil{
                        self.setCriteriaSwitch(!isEnabled)
                        
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您啟動雷達服務，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            () -> Void in
                            self.purchaseHistotyTableDataSource.refresh(){
                                self.reloadRadarUI()
                            }
                        }
                        return
                    }
                    
                    self.setCriteriaSwitch(isEnabled)
                    self.purchaseHistotyTableDataSource.refresh(){
                        self.reloadRadarUI()
                    }
                    
            }
        }
    }
}


// MARK: Handle unfinished transactions

extension RadarDisplayViewController{
    
    func alertCompleteUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        
        let alertView = SCLAlertView()
        
        alertView.addButton("重新建立", action: {
            () -> Void in
            
            RadarService.sharedInstance.startLoadingText(self, text:"建立服務...")
            
            RadarService.sharedInstance.tryCompleteUnfinishTransactions(unfinishedTranscations){
                
                (success, fail) -> Void in
                
                RadarService.sharedInstance.stopLoading()
                
                self.alertUnfinishTransactionsStatus(success, fail: fail)
            }
        })
        
        
        alertView.showNotice("重新建立服務", subTitle: "您已經成功購買過租屋雷達，但服務尚未建立完成，請重新建立服務", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
    }
    
    func alertUnfinishTransactionsStatus(success: Int, fail: Int){
        
        UserServiceStatusManager.shared.resetServiceStatusCache() // reset service cache
        
        if fail <= 0{
            SCLAlertView().showInfo("服務建立成功", subTitle: "所有服務已經建立完成", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                
                self.reloadRadarUI()
                
            }
            
            return
        }
    
        if fail > 0{
            let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            let msgTitle = "服務建立失敗"
            let okButton = "知道了"
            let subTitle = "您已經成功購買過租屋雷達，但是目前無法成功為您建立服務，請您請稍後再試！ 若持續發生失敗，請與臉書粉絲團客服聯繫!"
            let alertView = SCLAlertView()
            alertView.showCloseButton = true
            
            alertView.addButton("重新再試") {
                
                RadarService.sharedInstance.startLoadingText(self, text:"建立服務...")
                
                RadarService.sharedInstance.tryCompleteUnfinishTransactions(unfinishedTranscations){
                    
                    (success, fail) -> Void in
                    
                    self.runOnMainThread(){
                        RadarService.sharedInstance.stopLoading()
                        
                        self.alertUnfinishTransactionsStatus(success, fail: fail)
                    }
                }
            }
            
            alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        }
    
    }
    
}

extension RadarDisplayViewController: RadarPurchaseHistoryTableDelegate{
    
    func onRefreshData(){
        self.purchaseTableView.reloadData()
    }
    
    func onEmptyData(isEmpty: Bool){
        if isEmpty == false{
            self.emptyPurchaseHistoryLabel.hidden = true
            return
        }
        
        self.emptyPurchaseHistoryLabel.text = SystemMessage.INFO.EMPTY_HISTORICAL_PURCHASE
        self.emptyPurchaseHistoryLabel.sizeToFit()
        self.emptyPurchaseHistoryLabel.hidden = false
    }
    
}
