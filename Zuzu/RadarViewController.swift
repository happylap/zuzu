//
//  RadarViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

protocol RadarViewControllerDelegate: class {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria)
}

class RadarViewController: UIViewController {
    
    var hasValidService = false
    
    var needCheckService = false
    
    var unfinishedTranscations: [SKPaymentTransaction]?
    
    var porcessTransactionNum = -1
    
    var isOnLogging = false
    
    var navigationView: RadarNavigationController?
    
    var displayRadarViewController: RadarDisplayViewController?
    
    var purchaseViewController: RadarPurchaseViewController?
    
    var delegate: RadarViewControllerDelegate?
    
    // Data Store Insatance
    private let criteriaDataStore = UserDefaultsRadarCriteriaDataStore.getInstance()
    
    @IBOutlet weak var radarBannerLabel: UILabel!
    @IBOutlet weak var currentConditionsLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    struct ViewTransConst {
        static let showCriteriaConfigureTable:String = "showCriteriaConfigureTable"
    }
    
    var searchCriteria: SearchCriteria = SearchCriteria(){
        didSet{
            updateCriteriaTextLabel()
        }
    }
    
    var isUpdateMode = false
    
    // MARK: - Action Handlers
    func handleUserLogin(notification: NSNotification){
        Log.debug("handleUserLogin")
        self.needCheckService = true
    }
    
    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.enter()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUserLogin:", name: UserLoginNotification, object: nil)
        
        
        if(self.isUpdateMode){
            /// Update Existing Criteria
            
            self.activateButton.setTitle("設定完成", forState: .Normal)
            
            /// Refresh the criteria on UI
            updateCriteriaTextLabel()
            
        } else {
            /// Create New Criteria
            
            /// Use cached criteria for criteria creation if there is cached data
            if let criteria = criteriaDataStore.loadSearchCriteria() {
                
                self.searchCriteria = criteria
                
            } else {
                
                /// Reset the criteria on UI
                self.searchCriteria = SearchCriteria()
            }
        }
        
        self.currentConditionsLabel.textColor = UIColor.colorWithRGB(0xf5a953, alpha: 1)
        self.radarBannerLabel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        self.configureButton()
        self.checkService()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()
        
        if self.needCheckService == true{
            self.needCheckService = false
            self.checkService()
            return
        }
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                self.doUnfinishTransactions(unfinishedTranscations)
            }else{
                self.loginForUnfinishTransactions()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.enter()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        Log.enter()
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.error("prepareForSegue: \(identifier) \(self)")
            
            switch identifier{
            case ViewTransConst.showCriteriaConfigureTable:
                if let vc = segue.destinationViewController as? RadarConfigureTableViewController {
                    vc.loadedCriteria = self.searchCriteria
                    vc.delegate  = self
                }
                
            default: break
            }
        }
    }
    
    // MARK: - UI Configure
    
    private func configureButton() {
        activateButton.layer.borderWidth = 1
        activateButton.layer.borderColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
        activateButton.tintColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        activateButton
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Normal)
        activateButton
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Selected)
    }
    
    private func updateCriteriaTextLabel(){
        Log.error("")
        
        let displayItem = RadarDisplayItem(criteria:self.searchCriteria)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.purpostString
        self.priceSizeLabel?.text = displayItem.priceSizeString
        var filterNum = 0
        if let filterGroups = searchCriteria.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherCriteriaLabel?.text = "其他 \(filterNum) 個過濾條件"
    }
    
    // MARK: - Purchase Radar
    
    @IBAction func activateButtonClick(sender: UIButton) {
        
        // check critria first
        if RadarService.sharedInstance.checkCriteria(self.searchCriteria) == false{
            return
        }
        
        // updateMode --> update criteria
        if self.isUpdateMode == true{
            if let zuzuCriteria = self.displayRadarViewController?.zuzuCriteria{
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                    RadarService.sharedInstance.stopLoading(self)
                    RadarService.sharedInstance.startLoadingText(self, text:"更新雷達條件")
                    ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: zuzuCriteria.criteriaId!, criteria: self.searchCriteria) { (result, error) -> Void in
                        self.runOnMainThread(){
                            if error != nil{
                                
                                RadarService.sharedInstance.stopLoading(self)
                                
                                Log.error("Cannot update criteria by user id:\(userId)")
                                
                                SCLAlertView().showInfo("網路連線失敗", subTitle: "更新雷達條件失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                                return
                            }
                            
                            Log.info("update criteria success")
                            
                            self.delegate?.onCriteriaSettingDone(self.searchCriteria)
                            
                            RadarService.sharedInstance.stopLoading(self)
                            
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                }
            }
            return
        }
        
        if self.hasValidService == true{
            RadarService.sharedInstance.startLoadingText(self, text:"重新設定租屋雷達服務...")
            self.setUpCriteria()
            return
        }
        
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

// MARK: - RadarConfigureTableViewControllerDelegate
extension RadarViewController : RadarConfigureTableViewControllerDelegate {
    func onCriteriaChanged(searchCriteria:SearchCriteria){
        Log.debug("onCriteriaChanged")
        
        ///Save search criteria and enable reset button
        criteriaDataStore.saveSearchCriteria(searchCriteria)
        
        self.searchCriteria = searchCriteria
    }
    
}

// MARK: - Purchase Radar Callback

extension RadarViewController{
    func cancelPurchaseHandler() -> Void{
        self.tabBarController?.tabBarHidden = false
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showDisplayRadarUI()
        }
    }
    
    func purchaseSuccessHandler(purchaseView: RadarPurchaseViewController) -> Void{
        Log.enter()
        self.purchaseViewController = purchaseView
        self.tabBarController?.tabBarHidden = false
        RadarService.sharedInstance.startLoading(self)
        self.setUpCriteria()
        Log.exit()
    }
    
    func unfinishedTransactionHandler(purchaseView: RadarPurchaseViewController) -> Void{
        Log.enter()
        
        self.tabBarController?.tabBarHidden = false
        
        self.purchaseViewController = purchaseView
        
        RadarService.sharedInstance.stopLoading(self)
        
        SCLAlertView().showInfo("雷達服務", subTitle: "之前購買的雷達服務尚未完成設定", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, duration: 2.0, colorTextButton: 0xFFFFFF).setDismissBlock(){
            () -> Void in
            self.purchaseViewController?.dismissViewControllerAnimated(true, completion: nil)
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
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "設定租屋雷達失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                    }
                    return
                }
                
                Log.info("get criteria successfully")
                if result != nil{
                    result!.criteria = self.searchCriteria
                    self.updateCriteria(result!)
                }else{
                    self.createCriteria()
                }
                
            }
        }
        Log.exit()
    }
    
    func updateCriteria(zuzuCriteria: ZuzuCriteria){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: zuzuCriteria.criteriaId!, criteria: self.searchCriteria) { (result, error) -> Void in
                
                if error != nil{
                    self.runOnMainThread(){
                        Log.error("Cannot update criteria by user id:\(userId)")
                        
                        RadarService.sharedInstance.stopLoading(self)
                        
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "設定租屋雷達失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            () ->Void in
                            self.gotoDisplayRadar(zuzuCriteria)
                        }
                    }
                    
                    return
                }
                
                Log.info("update criteria success")
                
                self.setCriteriaEnabled(zuzuCriteria, isEnabled:true)
                
            }
        }
        Log.exit()
    }
    
    func setCriteriaEnabled(zuzuCriteria: ZuzuCriteria, isEnabled: Bool){
        
        if isEnabled == true{
            RadarService.sharedInstance.stopLoading(self)
            
            SCLAlertView().showInfo("設定成功", subTitle: "設定雷達成功", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                () ->Void in
                zuzuCriteria.enabled = isEnabled
                self.gotoDisplayRadar(zuzuCriteria)
            }
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                    self.runOnMainThread(){
                        if error != nil{
                            Log.error("Cannot enable criteria by user id:\(userId)")
                            
                            RadarService.sharedInstance.stopLoading(self)
                            
                            SCLAlertView().showInfo("設定成功", subTitle: "設定雷達成功\n請啟用租屋雷達", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                () ->Void in
                                zuzuCriteria.enabled = isEnabled
                                self.gotoDisplayRadar(zuzuCriteria)
                            }
                        }else{
                            Log.info("enable criteria success")
                            
                            RadarService.sharedInstance.stopLoading(self)
                            
                            SCLAlertView().showInfo("設定成功", subTitle: "設定雷達成功", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                                () ->Void in
                                zuzuCriteria.enabled = isEnabled
                                self.gotoDisplayRadar(zuzuCriteria)
                            }
                        }
                    }
            }
        }
    }
    
    func createCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.createCriteriaByUserId(userId, criteria: self.searchCriteria){
                (result, error) -> Void in
                
                self.runOnMainThread(){
                    
                    if error != nil{
                        
                        RadarService.sharedInstance.stopLoading(self)
                        
                        Log.error("Cannot update criteria by user id:\(userId)")
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "設定租屋雷達失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                        
                        return
                    }
                    
                    Log.info("create criteria success")
                    
                    RadarService.sharedInstance.stopLoading(self)
                    
                    SCLAlertView().showInfo("設定成功", subTitle: "設定雷達成功", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        () ->Void in
                        self.gotoDisplayRadar(nil)
                    }
                }
            }
        }
        Log.exit()
    }
    
    private func gotoDisplayRadar(zuzuCriteria: ZuzuCriteria?){
        self.purchaseViewController?.dismissViewControllerAnimated(true){
            if zuzuCriteria != nil{
                RadarService.sharedInstance.startLoading(self)
                self.navigationView?.showDisplayRadarView(zuzuCriteria!)
            }
        }
    }
    
}

// MARK: Check Radar service

extension RadarViewController{
    
    func showDisplayRadarUI(){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            RadarService.sharedInstance.startLoading(self)
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) {
                (result, error) -> Void in
                
                if error != nil{
                    self.runOnMainThread(){
                        RadarService.sharedInstance.stopLoading(self)
                        Log.error("Cannot get criteria by user id:\(userId)")
                        return
                    }
                    
                    Log.info("get criteria successfully")
                    if result != nil{
                        self.navigationView?.showDisplayRadarView(result!)
                        Log.exit()
                        return
                    }
                    
                }
            }
        }
    }
    
    func checkService(){
        
        Log.enter()
        
        if self.isUpdateMode == true{
            RadarService.sharedInstance.stopLoading(self)
            Log.exit()
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            RadarService.sharedInstance.startLoading(self)
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                
                if error != nil{
                    self.runOnMainThread(){
                        
                        RadarService.sharedInstance.stopLoading(self)
                        
                        Log.error("Cannot get criteria by user id:\(userId)")
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "無法取得租屋雷達服務狀態", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                    }
                    return
                }
                
                Log.info("get criteria successfully")
                if result != nil{
                    self.navigationView?.showDisplayRadarView(result!)
                    Log.exit()
                    return
                }
                
                ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                    (result, error) -> Void in
                    
                    self.runOnMainThread(){
                        RadarService.sharedInstance.stopLoading(self)
                        if error != nil{
                            Log.error("get radar service error")
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "無法取得租屋雷達服務狀態", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                            
                            Log.exit()
                            
                            return
                        }
                        
                        if result != nil{
                            if result?.status == RadarStatusValid{
                                self.hasValidService = true
                                SCLAlertView().showInfo("雷達服務已設定完成", subTitle: "租屋雷達服務已設定完成\n請立即啟用租屋雷達", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                            }
                        }
                    }
                }
            }
        }else{
            RadarService.sharedInstance.stopLoading(self)
        }
        
        Log.exit()
    }
    
    
}

// MARK: Handle unfinished transactions

extension RadarViewController{
    
    func handleCompleteLoginForUnfinishTransaction(task: AWSTask!) -> AnyObject?{
        self.isOnLogging = false
        self.tabBarController!.tabBarHidden = false
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
        }
        return nil
    }
    
    func cancelLoginHandler() -> Void{
        self.isOnLogging = false
        self.tabBarController?.tabBarHidden = false
    }
    
    func loginForUnfinishTransactions(){
        if self.isOnLogging == true {
            return
        }
        
        self.isOnLogging = true
        self.tabBarController?.tabBarHidden = true
        RadarService.sharedInstance.stopLoading(self)
        AmazonClientManager.sharedInstance.loginFromView(self, mode: 3, cancelHandler: self.cancelLoginHandler, withCompletionHandler: self.handleCompleteLoginForUnfinishTransaction)
    }
    
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        Log.enter()
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        RadarService.sharedInstance.stopLoading(self)
        RadarService.sharedInstance.startLoadingText(self,text:"重新設定租屋雷達服務...")
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
            self.showDisplayRadarUI()
        }
    }
    
    func handleCompleteTransaction(result: String?, error: NSError?) -> Void{
        if error != nil{
            self.transactionDone()
            self.alertUnfinishError()
            return
        }
        
        self.porcessTransactionNum = self.porcessTransactionNum + 1
        if let transactions = self.unfinishedTranscations{
            if self.porcessTransactionNum  < transactions.count{
                self.performFinishTransactions()
                return
            }
            
            transactionDone()
            self.showDisplayRadarUI()
        }
    }
    
    func transactionDone(){
        Log.enter()
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        RadarService.sharedInstance.stopLoading(self)
        Log.exit()
    }
    
    func alertUnfinishError(){
        let msgTitle = "重新設定租屋雷達服務失敗"
        let okButton = "知道了"
        let subTitle = "很抱歉！設定租屋雷達服務無法成功！"
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
