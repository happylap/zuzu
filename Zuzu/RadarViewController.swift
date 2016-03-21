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
    
    
    private static var alertViewResponder: SCLAlertViewResponder?
    
    // segue to configure UI
    
    struct ViewTransConst {
        static let showCriteriaConfigureTable:String = "showCriteriaConfigureTable"
    }
    
    // unfinished transcation variables
    var isOnLoggingForUnfinishTransaction = false

    
    weak var configTable: RadarConfigureTableViewController?
    
    // update criteria from radar status UI
    var isUpdateMode = false
    var criteiraId: String?
    var delegate: RadarViewControllerDelegate?
    
    // search criteria
    
    var radarSearchCriteria: SearchCriteria = SearchCriteria(){
        didSet{
            updateCriteriaTextLabel()
        }
    }
    
    // Data Store Insatance
    
    private let criteriaDataStore = UserDefaultsRadarCriteriaDataStore.getInstance()
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    // UI out let
    
    @IBOutlet weak var radarBannerLabel: UILabel!
    
    @IBOutlet weak var currentConditionsLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    
    // MARK: - View Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.enter()
        
        /// UI Configuration
        self.currentConditionsLabel.textColor = UIColor.colorWithRGB(0xf5a953, alpha: 1)
        self.radarBannerLabel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        self.configureButton()
        
        
        if (isUpdateMode == true){ /// [Criteria Update Mode]
            
            self.activateButton.setTitle("完成設定", forState: .Normal)
            
            /// Refresh criteria summary on UI
            updateCriteriaTextLabel()
            
        } else { /// [New Criteria Creation Mode]
            
            /// Try to load cached criteria
            let radarSearchCriteria = self.tryLoadCachedRadarCriteria()
            
            // Load Selected filters to search critea
            if let selectedFilterSetting = filterDataStore.loadRadarFilterSetting() {
                radarSearchCriteria.filterGroups = convertIdentifierToFilterGroup(selectedFilterSetting)
            }
            
            self.radarSearchCriteria = radarSearchCriteria
        }
        
        /// Send Criteria to Config Table
        self.configTable?.currentCriteria = self.radarSearchCriteria
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.debug("viewWillAppear")
        
        //Google Analytics Tracker
        if self.isUpdateMode{
            self.trackScreenWithTitle("\(self.title)_Update")
        }else{
            self.trackScreenWithTitle("\(self.title)_Create")
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
       
        /// When there are some unfinished transactions
        if isUpdateMode == false && isOnLoggingForUnfinishTransaction == false{
            
            if let _ = self.presentedViewController as? RadarPurchaseViewController{
                //do not alert unfinish while showPurchase
            }else{
                let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
                
                if unfinishedTranscations.count > 0{
                    self.alertCompleteUnfinishTransactions(unfinishedTranscations)
                }
            }
        }
        
    }
    
    // MARK: - Radar Cache
    
    private func tryLoadCachedRadarCriteria() -> SearchCriteria {
        Log.enter()
        /// Use cached criteria for criteria creation if there is cached data
        if let criteria = criteriaDataStore.loadSearchCriteria() {
            
            return criteria
            
        } else {
            
            /// Reset the criteria on UI
            return SearchCriteria()
        }
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.error("prepareForSegue: \(identifier) \(self)")
            
            switch identifier{
            case ViewTransConst.showCriteriaConfigureTable:
                if let vc = segue.destinationViewController as? RadarConfigureTableViewController {
                    self.configTable = vc
                    vc.delegate  = self
                }
                
            default: break
            }
        }
    }
    
    // MARK: - Action Button
    
    @IBAction func activateButtonClick(sender: UIButton) {
        
        // check critria first
        if RadarService.sharedInstance.checkCriteria(self.radarSearchCriteria) == false{
            return
        }
        
        // has criteriaId and user id --> update criteria
        
        //
        dispatch_async(GlobalQueue.Background) {

            if let priceRange = self.radarSearchCriteria.price {
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                    action: GAConst.Action.ZuzuRadarSetting.PriceMin,
                    label: String(priceRange.0))
                
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                    action: GAConst.Action.ZuzuRadarSetting.PriceMax,
                    label: String(priceRange.1))
            }
            
            if let sizeRange = self.radarSearchCriteria.size {
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                    action: GAConst.Action.ZuzuRadarSetting.SizeMin,
                    label: String(sizeRange.0))
                
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                    action: GAConst.Action.ZuzuRadarSetting.SizeMax,
                    label: String(sizeRange.1))
            }
            
            if let types = self.radarSearchCriteria.types {
                for type in types {
                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                        action: GAConst.Action.ZuzuRadarSetting.Type, label: String(type))
                }
            } else {
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting, action:
                    GAConst.Action.ZuzuRadarSetting.Type, label: "99")
            }
            
        }
        
        if isUpdateMode == true{
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                
                if let criteiraId = self.criteiraId{
                    
                    RadarService.sharedInstance.startLoadingText(self, text:"更新中...")
                    
                    ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: criteiraId, criteria: self.radarSearchCriteria) {
                        (result, error) -> Void in
                        
                        if error != nil{
                            
                            self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                                action: GAConst.Action.ZuzuRadarSetting.UpdateCriteriaError, label: userId)
                            
                            RadarService.sharedInstance.stopLoading()
                            
                            Log.error("Cannot update criteria by user id:\(userId)")
                            
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新雷達條件，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                            
                            return
                        }
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarSetting,
                            action: GAConst.Action.ZuzuRadarSetting.UpdateCriteriaSuccess, label: userId)
                        
                        Log.info("update criteria success")
                        
                        self.delegate?.onCriteriaSettingDone(self.radarSearchCriteria)
                        
                        
                        //don't need to stop loading here because it is going ti reload ui
                        self.reloadRadarUI(){
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                    
                    return
                }
                
                RadarService.sharedInstance.startLoadingText(self, text:"設定中...")
                
                ZuzuWebService.sharedInstance.createCriteriaByUserId(userId, criteria: self.radarSearchCriteria){
                    (result, error) -> Void in
                    
                    if error != nil{
                        
                        Log.info("create criteria fails")
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        Log.error("Cannot update criteria by user id:\(userId)")
                        
                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法成功為您設定租屋雷達條件，請稍後再試!", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                        
                        return
                    }
                    
                    Log.info("create criteria success")
                    
                    //don't need to stop loading here because it is going ti reload ui
                    self.reloadRadarUI(){
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                }
                
            }

            
            return
            
        }else{
            self.showPurchase()
        }
        
    }
    
    // MARK: - Navigation
    
    private func showPurchase(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.purchaseDelegate = self
            presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    // MARK: - Reload to RadarNavigationController
    
    func reloadRadarUI(onCompleteHandler: (() -> Void)? = nil){
        if let navigation = self.navigationController as? RadarNavigationController{
            
            // set nil criteria to navigation controller for re-get the criteria from server
            navigation.zuzuCriteria = nil
            
            navigation.showRadar(){
                onCompleteHandler?()
            }
        }
    }
    
    // MARK: - Criteria View Update Function

    private func updateCriteriaTextLabel(){
        Log.enter()
        
        let displayItem = RadarDisplayItem(criteria:self.radarSearchCriteria)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.purpostString
        self.priceSizeLabel?.text = displayItem.priceSizeString
        var filterNum = 0
        if let filterGroups = radarSearchCriteria.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherCriteriaLabel?.text = "其他 \(filterNum) 個過濾條件"
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

    
    private static func resetAlertView(){
        RadarViewController.alertViewResponder = nil
    }
}

// MARK: - RadarConfigureTableViewControllerDelegate
extension RadarViewController : RadarConfigureTableViewControllerDelegate {
    func onCriteriaChanged(searchCriteria:SearchCriteria){
        Log.debug("onCriteriaChanged")
        
        self.radarSearchCriteria = searchCriteria
        
        /// Cache criteria here only for [New Critera Creation Mode]
        if isUpdateMode == false {
            ///Save search criteria when criteria is updated by the user
            criteriaDataStore.saveSearchCriteria(radarSearchCriteria)
            
            if let filterGroups = radarSearchCriteria.filterGroups {
                self.filterDataStore.saveRadarFilterSetting(convertFilterGroupToIdentifier(filterGroups))
            } else {
                self.filterDataStore.clearRadarFilterSetting()
            }
        }
        
    }
}

// MARK: - RadarPurchaseDelegate

extension RadarViewController: RadarPurchaseDelegate{
    func onPurchaseCancel() -> Void{
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            // If user is logged in and he has purchased service before -> Go to radar status page
            self.reloadRadarUI()
        }
    }
    
    func onPurchaseSuccess() -> Void{
        Log.enter()
        
        UserServiceStatusManager.shared.resetServiceStatusCache() // reset service cache
        
        self.setUpCriteria()
        Log.exit()
    }
    
    func onFindUnfinishedTransaction(unfinishedTranscations:[SKPaymentTransaction]) -> Void{
        Log.enter()

        if isUpdateMode == false && isOnLoggingForUnfinishTransaction == false{
            self.alertCompleteUnfinishTransactions(unfinishedTranscations)
        }
        
        Log.exit()
    }
    
    func onLoggedInForPurchase() {
    }
}

// MARK: Criteria setting function for purchase

extension RadarViewController{
    
    func setUpCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            RadarService.sharedInstance.startLoading(self)
            
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) {
                (result, error) -> Void in
                
                if error != nil{
                    Log.error("Cannot get criteria by user id:\(userId)")
                    
                    //GA tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                        action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaError, label: userId)
            
                    RadarService.sharedInstance.stopLoading()
                    
                    SCLAlertView().showInfo("網路連線失敗", subTitle: "設定租屋雷達失敗", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        
                        self.reloadRadarUI()
                    }
                    
                    return
                }
                
                Log.info("get criteria successfully")
                if result != nil{
                    result!.criteria = self.radarSearchCriteria
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
            
            ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: zuzuCriteria.criteriaId!, criteria: self.radarSearchCriteria) { (result, error) -> Void in
                
                if error != nil{
                    Log.error("Cannot update criteria by user id:\(userId)")
                    
                    //GA tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                        action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaError, label: userId)
                    
                    RadarService.sharedInstance.stopLoading()
                    
                    SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新租屋雷達條件，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        
                        self.reloadRadarUI()
                    
                    }

                    return
                }
                
                Log.info("update criteria success")
                
                self.setCriteriaEnabled(zuzuCriteria)
                
            }
        }
        
        Log.exit()
    }
    
    func setCriteriaEnabled(zuzuCriteria: ZuzuCriteria){
        
        var isEnabled = zuzuCriteria.enabled ?? false
        
        if isEnabled == true{
            
            //GA tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaSuccess, label: zuzuCriteria.userId)
            
            //don't need to stop loading here because it is going ti reload ui
            zuzuCriteria.enabled = isEnabled
            self.reloadRadarUI()
            return
        }
        
        isEnabled = true
                
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: zuzuCriteria.criteriaId!, enabled: isEnabled) {
                    
                    (result, error) -> Void in
                    
                    if error != nil{
                        Log.error("Cannot enable criteria by user id:\(userId)")
                        
                        //GA tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                            action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaError, label: userId)
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        SCLAlertView().showInfo("設定成功", subTitle: "很抱歉，租屋雷達條件儲存成功，但是尚無法成功啟用，請您稍後嘗試手動啟用", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            
                            self.reloadRadarUI()
                        
                        }
                        
                        return
                    }
                    
                    //GA tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                        action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaSuccess, label: userId)
                    
                    Log.info("enable criteria success")
                    
                    //don't need to stop loading here because it is going ti reload ui
                    
                    self.reloadRadarUI()
            }
        }
    }
    
    func createCriteria(){
        Log.enter()
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.createCriteriaByUserId(userId, criteria: self.radarSearchCriteria){
                (result, error) -> Void in
                
                if error != nil{
                    
                    //GA tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                        action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaError, label: userId)
                    
                    Log.info("create criteria fails")
                    
                    RadarService.sharedInstance.stopLoading()
                    
                    Log.error("Cannot update criteria by user id:\(userId)")
                    
                    SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法成功為您設定租屋雷達條件，請稍後再試!", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        
                        self.reloadRadarUI()
                    
                    }
                    return
                }
                
                //GA tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarPurchase,
                    action: GAConst.Action.ZuzuRadarPurchase.SaveCriteriaSuccess, label: userId)
                
                Log.info("create criteria success")
                
                //don't need to stop loading here because it is going ti reload ui
                
                self.reloadRadarUI()
            }
        }
        Log.exit()
    }
}


// MARK: Handle unfinished transactions

extension RadarViewController{
    
    func cancelLoginHandler() -> Void{
        self.isOnLoggingForUnfinishTransaction = false
    }
    
    func loginForUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        
        self.isOnLoggingForUnfinishTransaction = true
        
        AmazonClientManager.sharedInstance.loginFromView(self, mode: 3, cancelHandler: self.cancelLoginHandler){
            
            (task: AWSTask!) -> AnyObject! in
            
            self.isOnLoggingForUnfinishTransaction = false
            
            if let error = task.error {
                Log.warning("Login Failed or cancelled: \(error)")
                return nil
            }
            
            RadarService.sharedInstance.startLoadingText(self, text:"啟用中...")
            
            RadarService.sharedInstance.tryCompleteUnfinishTransactions(unfinishedTranscations){
                
                (success, fail) -> Void in
                
                RadarService.sharedInstance.stopLoading()
                
                self.alertUnfinishTransactionsStatus(success, fail: fail)
                
            }
            
            return nil
        }
    }
 
    func alertCompleteUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        
        if RadarViewController.alertViewResponder == nil{
            let alertView = SCLAlertView()
            
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                
                alertView.addButton("啟用服務", action: {
                    () -> Void in
                    
                    RadarService.sharedInstance.startLoadingText(self, text:"啟用中...")
                    
                    RadarService.sharedInstance.tryCompleteUnfinishTransactions(unfinishedTranscations){
                        
                        (success, fail) -> Void in
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        self.alertUnfinishTransactionsStatus(success, fail: fail)
                    }
                })
                
            }else{
                
                alertView.addButton("啟用服務", action: {
                    () -> Void in
                    
                    self.loginForUnfinishTransactions(unfinishedTranscations)
                })
                
            }
            
            RadarViewController.alertViewResponder = alertView.showNotice("啟用租屋雷達服務", subTitle: "您已經成功購買過租屋雷達，但服務尚未完成啟用，請點選「啟用服務」以啟用此服務項目", closeButtonTitle: "下次再說", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            
            RadarViewController.alertViewResponder?.setDismissBlock(){
                
                RadarViewController.alertViewResponder = nil
                
                self.reloadRadarUI() // if user is logged in on purchase
                
            }
        }

    }
    
    func alertUnfinishTransactionsStatus(success: Int, fail: Int){
        
        UserServiceStatusManager.shared.resetServiceStatusCache() // reset service cache
        
        if fail <= 0{

            SCLAlertView().showInfo("服務啟用成功", subTitle: "所有服務已經完成啟用", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){

                self.reloadRadarUI()
                
            }
            
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
                    
                    RadarService.sharedInstance.stopLoading()
                    
                    self.alertUnfinishTransactionsStatus(success, fail: fail)
                }
            }
            
            alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        }
        
    }

}
