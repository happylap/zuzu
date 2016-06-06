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
    
    private static var alertViewResponder: SCLAlertViewResponder?
    
    private var alertNoCriteria = false
    
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
    
    private func configureLoginRightButton() {
        
        if(!AmazonClientManager.sharedInstance.isLoggedIn()) {
            
            let loginButton: UIButton = UIButton(type: UIButtonType.Custom)
            loginButton.setTitle("登入", forState: UIControlState.Normal)
            loginButton.titleLabel?.font = UIFont.systemFontOfSize(16)
            loginButton.autoScaleFontSize = true
            loginButton.addTarget(self, action: #selector(RadarDisplayViewController.onLoginRightButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            loginButton.sizeToFit()
            
            let loginItem = UIBarButtonItem(customView: loginButton)
            
            self.navigationItem.setRightBarButtonItems([loginItem], animated: false)
            
        } else {
            
            self.navigationItem.setRightBarButtonItems(nil, animated: false)
            
        }
        
        
    }
    
    @IBOutlet weak var radarDiagnosisButton: UIButton! {
        didSet {
            radarDiagnosisButton.setImage(UIImage(named: "notification_error")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            radarDiagnosisButton.tintColor = UIColor.colorWithRGB(0xFF6666)
            
            radarDiagnosisButton.addTarget(self, action: #selector(RadarDisplayViewController.onDiagnosisButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            
            setDisplayRadarDiagnosisButton(false)
        }
    }
    
    @IBOutlet weak var modifyButtoon: UIButton! // buton to update or configure criteria
    
    @IBOutlet weak var currentConditionBannerLabel: UILabel!
    
    @IBOutlet weak var criteriaEnableSwitch: UISwitch! {
        didSet {
            let ratio = getCurrentScale()
            
            criteriaEnableSwitch.transform = CGAffineTransformMakeScale(ratio, ratio)
        }
    }
    
    @IBOutlet weak var criteriaMessage: UILabel! {
        didSet {
            self.criteriaMessage.hidden = true
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
    
    private func setDisplayRadarDiagnosisButton(visible: Bool) {
        
        if(visible) {
            self.radarDiagnosisButton.hidden = false
        } else {
            self.radarDiagnosisButton.hidden = true
        }
    }
    
    private func doPromptAuthLocalNotification() {
        Log.enter()
        
        RadarUtils.shared.promptAuthLocalNotification {
            
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                
                /// Enable Local App Notifications
                appDelegate.setupLocalNotifications({ (result) -> () in
                    
                    Log.warning("setupLocalNotifications = \(result)")
                    
                    if(result) {
                        
                        if(!appDelegate.isPushNotificationRegistered()) {
                            
                            self.doAlertPushNotificationDisabled()
                            
                        }
                        
                    } else {
                        
                        self.doAlertLocalNotificationDisabled()
                        
                    }
                })
                
            }else{
                assert(false, "appDelegate cannot be nil")
                Log.error("appDelegate is nil")
            }
            
        }
    }
    
    private func doAlertLocalNotificationDisabled() {
        Log.enter()
        
        self.setDisplayRadarDiagnosisButton(true)
        
        let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken()
        let userID = UserManager.getCurrentUser()?.userId ?? ""
        let grantedSettings = UIApplication.sharedApplication().currentUserNotificationSettings()?.types
        
        
        self.trackEventForCurrentScreen(GAConst.Catrgory.NotificationStatus,
                                        action: GAConst.Action.NotificationStatus.LocalNotificationDisabled, label: "\(deviceTokenString), uid: \(userID), ntype: \(grantedSettings)")
        
        RadarUtils.shared.alertLocalNotificationDisabled()
    }
    
    private func doAlertPushNotificationDisabled() {
        Log.enter()
        
        self.setDisplayRadarDiagnosisButton(true)
        
        let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken()
        let userID = UserManager.getCurrentUser()?.userId ?? ""
        self.trackEventForCurrentScreen(GAConst.Catrgory.NotificationStatus,
                                        action: GAConst.Action.NotificationStatus.PushNotificationNotRegistered, label: "\(deviceTokenString), \(userID)")
        
        RadarUtils.shared.alertPushNotificationDisabled { (result) in
            if(result) {
                
                RadarUtils.shared.alertRegisterSuccess()
                
            } else {
                
                RadarUtils.shared.alertRegisterFailure()
                
            }
        }
    }
    
    private func toggleServiceStatusIcon(isValid: Bool) {
        
        statusImageView.hidden = false
        
        if(isValid) {
            statusImageView.image = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        } else {
            statusImageView.image = UIImage(named: "comment-alert-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
    }
    
    private func performRadarStatusCheck() {
        
        self.setDisplayRadarDiagnosisButton(false)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            /// Local notification enabled
            if(appDelegate.isLocalNotificationEnabled()) {
                
                /// Remote notification not registered
                if(!appDelegate.isPushNotificationRegistered()) {
                    
                    self.doAlertPushNotificationDisabled()
                    
                }
                
            } else {
                
                /// Ask notification type permission
                self.doPromptAuthLocalNotification()
                
            }
            
        }
        
    }
    
    // MARK: - Action Handlers
    
    func onLoginRightButtonTouched(sender: UIButton) {
        Log.enter()
        
        AmazonClientManager.sharedInstance.loginFromView(self, mode: 2, allowSkip: false) {
            (task: AWSTask!) -> AnyObject! in
            
            return nil
            
        }
        
    }
    
    func onDiagnosisButtonTouched(sender: UIButton) {
        Log.enter()
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDiagnosisView") as? RadarDiagnosisViewController {
            vc.modalPresentationStyle = .OverFullScreen
            vc.delegate = self
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize
        /// Always display "renew" button
        self.serviceButton?.hidden = false
        
        self.serviceStatusLabel?.text = ""
        self.serviceExpireLabel?.text = ""
        self.configureButton()
        self.configureBannerText()
        self.configurePurchaseTableView()
        
        /// Enable login button when unauthenticated users are allowed
        if(FeatureOption.Radar.enableUnauth) {
            self.configureLoginRightButton()
        }
        
        // purchase history only refresh in view load
        self.purchaseHistotyTableDataSource.purchaseHistoryTableDelegate = self
        self.purchaseHistotyTableDataSource.refresh(nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Log.debug("viewWillAppear")
        
        self.criteriaEnableSwitch?.on = self.zuzuCriteria.enabled ?? false
        
        // update criteria UI according to zuzuCriteria
        self.updateCriteriaTextLabel()
        
        // update service UI according to zuzuService
        self.updateServiceUI()
        
        
        self.performRadarStatusCheck()
        
        //Google Analytics Tracker
        self.trackScreen()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
        
        /// When there are some unfinished transactions
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.alertCompleteUnfinishTransactions(unfinishedTranscations)
        }else{
            if self.zuzuCriteria.criteriaId == nil{
                
                if self.alertNoCriteria == true{
                    return
                }
                
                // only show once
                self.alertNoCriteria = true
                
                if RadarDisplayViewController.alertViewResponder == nil{
                    RadarDisplayViewController.alertViewResponder = SCLAlertView().showInfo("請即設定", subTitle: "您的租屋雷達服務已在作用中，\n請立即設定租屋雷達條件並開啟通知，以維護您的權益，謝謝！", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                    RadarDisplayViewController.alertViewResponder?.setDismissBlock(){
                        RadarDisplayViewController.alertViewResponder = nil
                    }
                }
                
                return
            }
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
            
            SCLAlertView().showInfo("尚未設定雷達條件", subTitle: "開啟通知前請先設定雷達條件", closeButtonTitle: "確認", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
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
        
        /// GA
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                        action: GAConst.Action.UIActivity.ChangeRadarStatus, label: String(isEnabled))
        
        self.setCriteriaEnabled(isEnabled)
    }
    
    func setCriteriaEnabled(isEnabled: Bool){
        if let userId = UserManager.getCurrentUser()?.userId,
            criteriaId = self.zuzuCriteria.criteriaId{
            
            var text = "開啟通知"
            if isEnabled == false{
                text = "關閉通知"
            }
            
            RadarService.sharedInstance.startLoadingText(self,text:text, animated:false, minShowTime: 1.0)
            
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
            let text = "您的租屋雷達服務已在作用中\n請立即設定租屋條件並開啟通知，才能開始收到通知。"
            self.criteriaMessage.hidden = false
            self.criteriaMessage.text = text
            self.regionLabel?.text = ""
            self.houseInfoLabel?.text = ""
            self.priceSizeLabel?.text = ""
            self.otherFiltersLabel?.text = ""
            self.modifyButtoon?.setTitle("設定雷達", forState: .Normal)
            return
        }
        
        self.criteriaMessage.hidden = true
        
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
            if let expireDate = service.expireTime {
                
                if let dateString = CommonUtils.getLocalShortStringFromDate(expireDate) {
                    expireDateStr = dateString
                }
            }
            self.serviceExpireLabel?.text = "雷達服務到期日: \(expireDateStr)"
            
            
        } else {
            /// Service is invalid or status info not available
            
            self.serviceStatusLabel?.text = "很抱歉!無法取得租屋雷達服務狀態"
            self.serviceExpireLabel?.text = ""
            //self.serviceButton?.hidden = true
            
            /// Clear Chart
            self.clearChart("無法載入資料")
            
            self.enableModifyButton()
            
        }
    }
    
    private func handleServiceExpired() {
        
        /// Update UI for service expiry
        self.serviceStatusLabel?.text = "您的租屋雷達服務已到期"
        self.criteriaEnableSwitch?.on = false
        //self.serviceButton?.hidden = false
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
        
        
//        if(remainingDays <= Double(RenewalThresholdDays)) {
//            self.serviceButton?.hidden = false
//        }else{
//            self.serviceButton?.hidden = true
//        }
        
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
        
        if let userId = UserManager.getCurrentUser()?.userId, endpointArn = UserDefaultsUtils.getSNSEndpointArn(){
            // calling the sendNotifcaiont is just to make sure the app can receive the push notification from server
            // we don't want it to engage the flow about purchase and criteria setup, thus, we delay the sending for 5 seconds
            self.runOnMainThreadAfter(5.0){
                ZuzuWebService.sharedInstance.sendNotification(userId, targetARN: endpointArn, customMessage: nil, handler: {
                    (result, error) in
                    // don't need to handle the error
                })
            }
        }
        
        Log.exit()
    }
    
    func onFindUnfinishedTransaction(unfinishedTranscations:[SKPaymentTransaction]) -> Void{
        Log.enter()
        
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
            
            if RadarDisplayViewController.alertViewResponder == nil{
                RadarDisplayViewController.alertViewResponder = SCLAlertView().showInfo("請即設定", subTitle: "您的租屋雷達服務已在作用中，\n請立即設定租屋雷達條件並開啟通知，以維護您的權益，謝謝！", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                
                RadarDisplayViewController.alertViewResponder?.setDismissBlock(){
                    RadarDisplayViewController.alertViewResponder = nil
                }
            }
            
            return
            
        }
        
        if let userId = UserManager.getCurrentUser()?.userId,
            criteiraId = self.zuzuCriteria.criteriaId{
            
            if isEnabled == true{
                
                //GA tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                                                action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaSuccess, label: userId)
                
                self.setCriteriaSwitch(isEnabled)
                
                RadarService.sharedInstance.startLoading(self)
                
                self.purchaseHistotyTableDataSource.refresh(){
                    // don't need to stop loading here because it is going to reload ui
                    self.reloadRadarUI()
                }
                
                return
            }
            
            isEnabled = true
            
            RadarService.sharedInstance.startLoading(self)
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                                                                 criteriaId: criteiraId, enabled: isEnabled) { (result, error) -> Void in
                                                                    
                                                                    if error != nil{
                                                                        
                                                                        //GA tracker
                                                                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                                                                                                        action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaError, label: userId)
                                                                        
                                                                        self.setCriteriaSwitch(!isEnabled)
                                                                        
                                                                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您啟動雷達服務，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                                                            () -> Void in
                                                                            
                                                                            self.purchaseHistotyTableDataSource.refresh(){
                                                                                // don't need stop loading here because it is going to reloa ui
                                                                                self.reloadRadarUI()
                                                                            }
                                                                        }
                                                                        return
                                                                    }
                                                                    
                                                                    //GA tracker
                                                                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                                                                                                    action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaSuccess, label: userId)
                                                                    
                                                                    self.setCriteriaSwitch(isEnabled)
                                                                    
                                                                    self.purchaseHistotyTableDataSource.refresh(){
                                                                        
                                                                        // don't need stop loading here because it is going to reloa ui
                                                                        
                                                                        self.reloadRadarUI()
                                                                        
                                                                    }
                                                                    
            }
        }
    }
}


// MARK: Handle unfinished transactions

extension RadarDisplayViewController {
    
    func alertCompleteUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        
        if RadarDisplayViewController.alertViewResponder == nil{
            
            let alertView = SCLAlertView()
            
            alertView.addButton("啟用服務", action: {
                () -> Void in
                
                /// Allow finish transaction for auth / unauth users
                if let _ = UserManager.getCurrentUser()?.userId {
                    
                    RadarDisplayViewController.alertViewResponder = nil
                    
                    RadarService.sharedInstance.startLoadingText(self, text:"啟用中...")
                    
                    RadarService.sharedInstance.tryCompleteUnfinishTransactions(unfinishedTranscations){
                        
                        (success, fail) -> Void in
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        self.alertUnfinishTransactionsStatus(success, fail: fail)
                    }
                    
                }else{
                    /// No current userID, ask user to login
                    
                    assert(false, "RadarDisplayViewcontroller should not be shown when there is no current user")
                    
                }
                
            })
            
            RadarDisplayViewController.alertViewResponder = alertView.showNotice("啟用租屋雷達服務", subTitle: "您已經成功購買過租屋雷達，但服務尚未完成啟用，請點選「啟用服務」以啟用此服務項目", closeButtonTitle: "下次再說", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            
            RadarDisplayViewController.alertViewResponder?.setDismissBlock(){
                RadarDisplayViewController.alertViewResponder = nil
            }
        }
        
    }
    
    func alertUnfinishTransactionsStatus(success: Int, fail: Int){
        
        UserServiceStatusManager.shared.resetServiceStatusCache() // reset service cache
        
        if fail <= 0{
            SCLAlertView().showInfo("服務啟用成功", subTitle: "所有服務已經完成啟用", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            
            return
        }
        
        if fail > 0{
            let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            let msgTitle = "服務啟用失敗"
            let okButton = "知道了"
            let subTitle = "您已經成功購買過租屋雷達，但是目前無法成功為您啟用服務，請您請稍後再試！ 若持續發生失敗，請與臉書粉絲團客服聯繫!"
            let alertView = SCLAlertView()
            alertView.showCloseButton = true
            
            alertView.addButton("重新再試") {
                
                RadarService.sharedInstance.startLoadingText(self, text:"啟用中...")
                
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

// MARK: RadarPurchaseHistoryTableDelegate
extension RadarDisplayViewController: RadarPurchaseHistoryTableDelegate {
    
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

// MARK: RadarDiagnosisViewControllerDelegate
extension RadarDisplayViewController: RadarDiagnosisViewControllerDelegate {
    
    func onDismiss(){
        
        self.performRadarStatusCheck()
        
    }
    
}