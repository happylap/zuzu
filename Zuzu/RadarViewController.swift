//
//  RadarViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView
import MBProgressHUD

private let Log = Logger.defaultLogger

protocol RadarViewControllerDelegate: class {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria)
}

class RadarViewController: UIViewController {
    
    var unfinishedTranscations: [SKPaymentTransaction]?
    
    var porcessTransactionNum = -1
    
    var isOnLogging = false
    
    var hasValidService = false
    
    @IBOutlet weak var radarBannerLabel: UILabel!
    @IBOutlet weak var currentConditionsLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    struct ViewTransConst {
        static let showRegionConfigureTable:String = "showRegionConfigureTable"
    }
    
    var delegate: RadarViewControllerDelegate?
    var searchCriteria = SearchCriteria(){
        didSet{
            updateCriteriaTextLabel()
        }
    }
    var isUpdateMode = false
    
    // MARK: - View Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isUpdateMode == true{
            self.activateButton.setTitle("設定完成", forState: .Normal)
        }
        
        self.updateCriteriaTextLabel()
        self.currentConditionsLabel.textColor = UIColor.colorWithRGB(0xf5a953, alpha: 1)
        self.radarBannerLabel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        self.configureButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                self.doUnfinishTransactions(unfinishedTranscations)
            }else{
                self.loginForUnfinishTransactions()
            }
        }else{
            self.checkService()
        }
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        if(parent == nil) {
            /// Filter Setting Finished
            self.delegate?.onCriteriaSettingDone(searchCriteria)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier) \(self)")
            
            switch identifier{
            case ViewTransConst.showRegionConfigureTable:
                if let vc = segue.destinationViewController as? RadarConfigureTableViewController {
                    vc.currentCriteria = searchCriteria
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
    

    // MARK: - Loading
    
    func startLoading(){
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.view)
    }
    
    func stopLoading(){
        LoadingSpinner.shared.stop()
    }
    
    func startLoadingText(text: String){
        let dialog = MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        dialog.animationType = .ZoomIn
        dialog.dimBackground = true
        dialog.labelText = text
        
        self.runOnMainThread() { () -> Void in}
    }
    
    func stopLoadingText(){
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
    
    
    private func alertServerError(subTitle: String) {
        
        let alertView = SCLAlertView()
        
        alertView.showInfo("與伺服器連線失敗", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    // MARK: - Purchase Radar
    
    @IBAction func activateButtonClick(sender: UIButton) {
        if RadarService.sharedInstance.checkCriteria(self.searchCriteria) == false{
           return
        }
        
        if self.hasValidService == true{
            self.setUpCriteria()
            return
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            
            vc.cancelPurchaseHandler = self.cancelPurchaseHandler
            vc.completePurchaseHandler = self.completePurchaseHandler
            vc.unfinishedTransactionHandler = self.unfinishedTransactionHandler
            
            presentViewController(vc, animated: true, completion: nil)
        }
    }
}

// MARK: - RadarConfigureTableViewControllerDelegate
extension RadarViewController : RadarConfigureTableViewControllerDelegate {
    func onCriteriaConfigureDone(searchCriteria:SearchCriteria){
        Log.debug("onCriteriaConfigureDone")
        self.searchCriteria = searchCriteria
    }
    
}

// MARK: - Purchase Radar Callback

extension RadarViewController{
    func cancelPurchaseHandler() -> Void{
        self.tabBarController?.tabBarHidden = false
    }
    
    func completePurchaseHandler(isSuccess:Bool, error: NSError?) -> Void{
        Log.debug("isSuccess: \(isSuccess), error: \(error)")
        self.tabBarController?.tabBarHidden = false
        if error != nil{
            return
        }
        self.setUpCriteria()
    }
    
    func unfinishedTransactionHandler() -> Void{
        Log.enter()
        self.tabBarController?.tabBarHidden = false
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
        }
        Log.exit()
    }
    
    func setUpCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            self.startLoading()
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                if error != nil{
                    Log.error("Cannot get criteria by user id:\(userId)")
                    self.stopLoading()
                    //alert
                    return
                }
                
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
                
                self.stopLoading()
                
                if error != nil{
                    //alert
                    if let vc = self.navigationController as? RadarNavigationController{
                        vc.zuzuCriteria = zuzuCriteria // still old criteria
                        vc.showRadar()
                    }
                    return
                }
                
                self.setCriteriaEnabled(zuzuCriteria, isEnabled:true)
                
            }
        }
        Log.exit()
    }
    
    func createCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.createCriteriaByUserId(userId, criteria: self.searchCriteria){
                (result, error) -> Void in
                self.stopLoading()
                
                if error != nil{
                    //alert
                    return
                }
                
                if let vc = self.navigationController as? RadarNavigationController{
                    vc.showRadar()
                }
            }
        }
        Log.exit()
    }
    
    func setCriteriaEnabled(zuzuCriteria: ZuzuCriteria, isEnabled: Bool){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                    self.stopLoading()
                    if error != nil{
                        //alert
                        self.alertServerError("啟動租屋雷達服務失敗")
                    }
                    
                    if let vc = self.navigationController as? RadarNavigationController{
                        zuzuCriteria.criteria = self.searchCriteria // new criteria
                        zuzuCriteria.enabled = isEnabled
                        vc.zuzuCriteria = zuzuCriteria
                        vc.showRadar()
                    }
            }
        }
    }
}

// MARK: Check Radar service

extension RadarViewController{
    
    func checkService(){
        if self.hasValidService == true{
            return
        }
        
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                self.startLoading()
                ZuzuWebService.sharedInstance.getServiceByUserId(userId, handler: self.checkServiceHandler)
            }
        }
    }
    
    func checkServiceHandler(result: ZuzuServiceMapper?, error: NSError?) -> Void{
        self.stopLoading()
        if error != nil{
            self.alertServiceError("目前可能處於飛航模式或是無網路狀態，暫時無法取得租屋雷達服務狀態")
            return
        }
        
        if result != nil{
            if result?.status == RadarStatusValid{
                self.hasValidService = true
                self.alertService("租屋雷達服務已設定完成\n請立即啟用租屋雷達")
            }
        }
    }
    
    func alertServiceError(subTitle: String) {
        let alertView = SCLAlertView()
        alertView.showInfo("無法取得雷達服務狀態", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        
    }
    
    func alertService(subTitle: String){
        let alertView = SCLAlertView()
        alertView.showInfo("雷達服務已設定完成", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
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
        }else{
            self.checkService()
        }
        return nil
    }
    
    func cancelLoginHandler() -> Void{
        self.tabBarController?.tabBarHidden = false
    }
    
    func loginForUnfinishTransactions(){
        if self.isOnLogging == true {
            return
        }
        
        self.tabBarController?.tabBarHidden = true
        AmazonClientManager.sharedInstance.loginFromView(self, mode: 3, cancelHandler: self.cancelLoginHandler, withCompletionHandler: self.handleCompleteLoginForUnfinishTransaction)
    }
    
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        Log.enter()
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        self.startLoadingText("重新設定租屋雷達服務...")
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
            
            self.transactionDone()
            if let vc = self.navigationController as? RadarNavigationController{
                vc.showRadar()
            }
        }
    }
    
    func transactionDone(){
        Log.enter()
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        self.stopLoadingText()
        Log.exit()
    }
    
    func alertUnfinishError(){
        let msgTitle = "重新設定租屋雷達服務失敗"
        let okButton = "知道了"
        let subTitle = "很抱歉！設定租屋雷達服務無法成功！"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
        
        alertView.addButton("重新再試") {
            let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            if unfinishedTranscations.count > 0{
                if AmazonClientManager.sharedInstance.isLoggedIn(){
                    self.doUnfinishTransactions(unfinishedTranscations)
                }
            }
        }
        
        alertView.addButton("取消") {
        }
        
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
}
