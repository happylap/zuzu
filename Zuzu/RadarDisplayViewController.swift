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

let RadarStatusValid = "valid"

class RadarDisplayViewController: UIViewController {
    
    private let secPerDay = 86400.0
    private let secPerHour = 3600.0
    
    var isCheckService = true
    
    var isOnLogging = false
    
    var unfinishedTranscations: [SKPaymentTransaction]?
    
    var porcessTransactionNum = -1
    
    
    var purchaseViewController: RadarPurchaseViewController? //Used for view transition in purchase flow. Ex: dismiss purchase view afetr purchase is successful and done!
    
    var navigationView: RadarNavigationController?  //Used for view transition. Ex: if user log out, let configure UI show up
    
    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    private lazy var purchaseHistotyTableDataSource: RadarPurchaseHistoryTableViewDataSource = RadarPurchaseHistoryTableViewDataSource(uiViewController: self)
    
    let emptyLabel = UILabel()
    
    
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
    
    @IBOutlet weak var criteriaEnableSwitch: UISwitch! {
        didSet {
            let ratio = getCurrentScale()
            
            criteriaEnableSwitch.transform = CGAffineTransformMakeScale(ratio, ratio)
        }
    }
    
    
    // banner text label
    @IBOutlet weak var currentConditionBannerLabel: UILabel!
    
    @IBOutlet weak var servieBannerLabel: UILabel!
    
    @IBOutlet weak var purchaseHistoryBannerLabel: UILabel!
    
    // label in criteria
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var otherFiltersLabel: UILabel!
    
    
    // service status
    @IBOutlet weak var serviceStatusLabel: UILabel!
    
    @IBOutlet weak var serviceExpireLabel: UILabel!
    
    
    // purchase hstory
    @IBOutlet weak var purchaseTableView: UITableView!
    
    
    // buton
    @IBOutlet weak var modifyButtoon: UIButton!
    
    @IBOutlet weak var serviceButton: UIButton!
    
    var zuzuService: ZuzuServiceMapper?{
        didSet{
            self.updateServiceUI()
        }
    }
    
    var zuzuCriteria = ZuzuCriteria(){
        didSet{
            if zuzuCriteria.criteria == nil{
                zuzuCriteria.criteria = SearchCriteria()
            }
            self.updateCriteriaTextLabel()
        }
    }
    
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
        
        let subTitle = "遠端通知功能開啟失敗，請您重新開啟豬豬快租，並在進入「租屋雷達」一次，謝謝！"
        
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
    
    private func getDaysPart(seconds: Int) -> Int {
        
        return Int(ceil(convertSecondsToPreciseDays(seconds)))
        
    }
    
    private func getHoursPart(seconds: Int) -> Int {
        
        let hours = (Double(seconds) % secPerDay)/secPerHour
        
        return Int(floor(hours))
        
    }
    
    private func convertSecondsToPreciseDays(seconds: Int) -> Double {
        
        return Double(seconds)/secPerDay
        
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.serviceButton?.hidden = true
        self.serviceStatusLabel?.text = ""
        self.serviceExpireLabel?.text = ""
        self.configureButton()
        self.configureBannerText()
        self.configurePurchaseTableView()
        self.updateCriteriaTextLabel()
        self.purchaseHistotyTableDataSource.refresh()
        
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
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.navigationView?.showConfigureRadarView()
            return
        }
        
        self.tabBarController?.tabBarHidden = false
        
        self.criteriaEnableSwitch?.on = self.zuzuCriteria.enabled ?? false
        
        if self.isCheckService == false{
            self.isCheckService = true
            RadarService.sharedInstance.stopLoading(self)
            return
        }
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
        }else{
            self.checkService()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
    }
    
    // MARK: - Update UI
    private func updateServiceUI(){
        
        if let service = self.zuzuService,
            let status = service.status, let remainingSeconds = service.remainingSecond, let totalSeconds = service.totalSecond {
                /// Service is valid
                
                if status == RadarStatusValid{
                    
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
        let remainingDays = convertSecondsToPreciseDays(remainingSeconds)
        let usedDays = convertSecondsToPreciseDays(usedSeconds)
        
        /// Get rounded remianings days/hours part
        /// e.g. 15.5 Days = Day Part: 15, Hour Part: 12
        let roundedRemainingDaysPart = getDaysPart(remainingSeconds)
        let roundedRemainingHoursPart  = getHoursPart(remainingSeconds)
        
        
        /// Update UI for service valid
        var infoText: String?
        
        if(remainingDays >= 1) {
            /// More than 1 day
            
            infoText = "\(roundedRemainingDaysPart) 日"
            self.serviceStatusLabel?.text = "您的租屋雷達服務尚有：\(roundedRemainingDaysPart) 日"
            
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
        
        
        self.serviceButton?.hidden = true
        self.enableModifyButton()
        toggleServiceStatusIcon(true)
        
    }
    
    
    private func updateCriteriaTextLabel(){
        let displayItem = RadarDisplayItem(criteria:self.zuzuCriteria.criteria!)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.purpostString
        self.priceSizeLabel?.text = displayItem.priceSizeString
        var filterNum = 0
        if let filterGroups = self.zuzuCriteria.criteria!.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherFiltersLabel?.text = "其他 \(filterNum) 個過濾條件"
    }
    
    // MARK: - Configure UI
    
    private func configureButton() {
        modifyButtoon.layer.borderWidth = 1
        self.enableModifyButton()
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
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyLabel.textAlignment = NSTextAlignment.Center
            emptyLabel.numberOfLines = -1
            emptyLabel.font = UIFont.systemFontOfSize(14)
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.autoScaleFontSize = true
            emptyLabel.hidden = true
            contentView.addSubview(emptyLabel)
            
            let xConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let yConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            yConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow
            
            let rightConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow
            
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint])
            
        }
        
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
                
            case ViewTransConst.showConfigureRadar:
                if let vc = segue.destinationViewController as? RadarViewController {
                    self.navigationItem.backBarButtonItem?.title = "返回"
                    self.isCheckService = false
                    vc.delegate = self
                    vc.displayRadarViewController = self
                    vc.isUpdateMode = true
                    vc.radarSearchCriteria = self.zuzuCriteria.criteria!
                }
            default: break
                
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func enableCriteria(sender: UISwitch) {
        let isEnabled = sender.on
        
        if let service = self.zuzuService{
            if let status = service.status{
                if status != RadarStatusValid{
                    //expired service -> show purchase modal
                    self.showPurchase()
                    return
                }
            }
        }
        
        self.setCriteriaEnabled(isEnabled)
    }
    
    @IBAction func onServiceButtonTapped(sender: AnyObject) {
        self.showPurchase()
    }
    
    func setCriteriaEnabled(isEnabled: Bool){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            var text = "啟用中"
            if isEnabled == false{
                text = "停用中"
            }
            
            RadarService.sharedInstance.stopLoading(self)
            RadarService.sharedInstance.startLoadingText(self,text:text, animated:false)
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: self.zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                    self.runOnMainThread(){
                        if error != nil{
                            RadarService.sharedInstance.stopLoading(self)
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前暫時無法為您完成此操作，請稍後再試，謝謝！", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                self.criteriaEnableSwitch.on = !isEnabled
                            }
                            
                            return
                        }
                        
                        RadarService.sharedInstance.stopLoading(self)
                        self.zuzuCriteria.enabled = isEnabled
                    }
            }
        }
    }
    
    func showPurchase(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            
            vc.cancelPurchaseHandler = self.cancelPurchaseHandler
            vc.purchaseSuccessHandler = self.purchaseSuccessHandler
            vc.unfinishedTransactionHandler = self.unfinishedTransactionHandler
            
            presentViewController(vc, animated: true, completion: nil)
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

// MARK: - Purchase Radar Callback

extension RadarDisplayViewController{
    func cancelPurchaseHandler() -> Void{
        self.tabBarController?.tabBarHidden = false
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.navigationView?.showConfigureRadarView()
        }
    }
    
    func purchaseSuccessHandler(purchaseView: RadarPurchaseViewController) -> Void{
        Log.enter()
        self.purchaseViewController = purchaseView
        self.serviceButton.hidden = true
        RadarService.sharedInstance.startLoading(self)
        self.setUpCriteria()
        Log.exit()
    }
    
    func unfinishedTransactionHandler(purchaseView: RadarPurchaseViewController) -> Void{
        Log.enter()
        self.tabBarController?.tabBarHidden = false
        
        self.purchaseViewController = purchaseView
        
        RadarService.sharedInstance.stopLoading(self)
        
        SCLAlertView().showInfo("尚未建立服務", subTitle: "您之前已經成功購買租屋雷達服務，但是我們發現還沒為您建立服務", closeButtonTitle: "確認", colorStyle: 0x1CD4C6, duration: 2.0, colorTextButton: 0xFFFFFF).setDismissBlock(){
            () -> Void in
            self.purchaseViewController?.dismissViewControllerAnimated(true){
                () -> Void in
                self.tabBarController?.tabBarHidden = false
            }
        }
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
        }
        
        Log.exit()
    }
    
    func setUpCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                
                if error != nil{
                    self.runOnMainThread(){
                        
                        RadarService.sharedInstance.stopLoading(self)
                        
                        Log.error("Cannot get criteria by user id:\(userId)")
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新雷達條件設定，請稍後再試!", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            () -> Void in
                            self.updateServiceAndPurchase(userId)
                        }
                    }
                    return
                }
                
                Log.info("get criteria successfully")
                
                if result != nil{
                    self.zuzuCriteria = result!
                    
                    self.updateCriteria()
                }else{
                    assert(false, "Criteria should not be nil")
                }
            }
        }
        Log.exit()
    }
    
    func updateCriteria(){
        Log.enter()
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: self.zuzuCriteria.criteriaId!, criteria: self.zuzuCriteria.criteria!) { (result, error) -> Void in
                
                self.runOnMainThread(){
                    if error != nil{
                        
                        RadarService.sharedInstance.stopLoading(self)
                        
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新雷達條件設定，請稍後再試!", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            () -> Void in
                            self.criteriaEnableSwitch.on = self.zuzuCriteria.enabled ?? false
                            self.updateServiceAndPurchase(userId)
                        }
                    }else{
                        self.enableCriteriaForPurchase()
                    }
                }
            }
        }
        Log.exit()
    }
    
    func enableCriteriaForPurchase(){
        
        let isEnabled = self.zuzuCriteria.enabled ?? false
        if isEnabled == true{
            
            self.criteriaEnableSwitch.on = true
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                self.updateServiceAndPurchase(userId)
            }
            
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: self.zuzuCriteria.criteriaId!, enabled: true) { (result, error) -> Void in
                    
                    if error != nil{
                        self.runOnMainThread(){
                            self.criteriaEnableSwitch.on = false
                            
                            RadarService.sharedInstance.stopLoading(self)
                            
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您啟動雷達服務，請您稍後再試！", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                () -> Void in
                                self.updateServiceAndPurchase(userId)
                            }
                        }
                        return
                    }
                    
                    self.criteriaEnableSwitch.on = true
                    self.updateServiceAndPurchase(userId)
            }
        }
    }
    
    func updateServiceAndPurchase(userId: String){
        self.clearChart("載入中")
        self.purchaseViewController?.dismissViewControllerAnimated(true){
            self.tabBarController?.tabBarHidden = false
            ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                (result, error) ->Void in
                
                self.runOnMainThread(){
                    
                    self.purchaseHistotyTableDataSource.refresh()
                    
                    if error != nil{
                        self.zuzuService = nil
                        Log.error("get radar service error")
                    }else{
                        self.zuzuService = result
                    }
                    
                    RadarService.sharedInstance.stopLoading(self)
                }
            }
        }
    }
    
}

// MARK: Check Radar service

extension RadarDisplayViewController{
    
    func checkService(){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            RadarService.sharedInstance.startLoading(self)
            
            ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                (result: ZuzuServiceMapper?, error: NSError?) -> Void in
                self.runOnMainThread(){
                    RadarService.sharedInstance.stopLoading(self)
                    if error != nil{
                        self.zuzuService = nil
                        Log.error("get radar service error")
                        return
                    }
                    
                    self.zuzuService = result
                }
            }
        }else{
            RadarService.sharedInstance.stopLoading(self)
        }
    }
}

// MARK: Handle unfinished transactions

extension RadarDisplayViewController{
    
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        Log.enter()
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        //RadarService.sharedInstance.stopLoading(self, animated: false)
        RadarService.sharedInstance.startLoadingText(self, text:"建立服務...")
        self.performFinishTransactions()
        Log.exit()
    }
    
    func performFinishTransactions(){
        if let transactions = self.unfinishedTranscations{
            if self.porcessTransactionNum  < transactions.count{
                RadarService.sharedInstance.createPurchase(transactions[self.porcessTransactionNum], handler: self.handleCompleteTransaction)
            }
        }else{
            self.transactionDone()
        }
    }
    
    func handleCompleteTransaction(purchaseTransaction: SKPaymentTransaction, error: NSError?) -> Void{
        if error != nil{
            self.transactionDone()
            self.alertUnfinishError()
            return
        }
        
        ZuzuStore.sharedInstance.finishTransaction(purchaseTransaction)
        
        self.porcessTransactionNum = self.porcessTransactionNum + 1
        
        if let transactions = self.unfinishedTranscations{
            if self.porcessTransactionNum  < transactions.count{
                self.performFinishTransactions()
                return
            }
            
            self.transactionDone()
        }
    }
    
    func transactionDone(){
        Log.enter()
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        RadarService.sharedInstance.stopLoading(self)
        self.checkService()
        Log.exit()
    }
    
    func alertUnfinishError(){
        let msgTitle = "服務建立失敗"
        let okButton = "知道了"
        let subTitle = "您已經成功購買過租屋雷達，但是目前無法成功為您建立服務，請您請稍後再試！ 若持續發生失敗，請與臉書粉絲團客服聯繫!"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                alertView.addButton("重新再試") {
                    self.doUnfinishTransactions(unfinishedTranscations)
                }
            }
        }
        
        alertView.addButton("取消") {
        }
        
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
}