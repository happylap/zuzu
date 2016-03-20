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
    
    // segue to configure UI
    
    struct ViewTransConst {
        static let showCriteriaConfigureTable:String = "showCriteriaConfigureTable"
    }
    
    // unfinished transcation variables
    
    var isOnLogging = false
    var unfinishedTranscations: [SKPaymentTransaction]?
    var porcessTransactionNum = -1
    
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
            
            self.activateButton.setTitle("設定完成", forState: .Normal)
            
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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
       
        
        if isUpdateMode == true{
            return
        }
        
         /// When there are some unfinished transactions
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                self.doUnfinishTransactions(unfinishedTranscations)
            }else{
                self.loginForUnfinishTransactions()
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
        
        if isUpdateMode == true{
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                
                if let criteiraId = self.criteiraId{
                    
                    RadarService.sharedInstance.startLoadingText(self, text:"更新中...")
                    
                    ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: criteiraId, criteria: self.radarSearchCriteria) {
                        (result, error) -> Void in
                        if error != nil{
                            
                            RadarService.sharedInstance.stopLoading()
                            
                            Log.error("Cannot update criteria by user id:\(userId)")
                            
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新雷達條件，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                            
                            return
                        }
                        
                        Log.info("update criteria success")
                        
                        self.delegate?.onCriteriaSettingDone(self.radarSearchCriteria)
                        
                        RadarService.sharedInstance.stopLoading()
                        
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
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
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
        self.tabBarController?.tabBarHidden = false
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            // If user is logged in and he has purchased service before -> Go to radar status page
            self.reloadRadarUI()
        }
    }
    
    func onPurchaseSuccess() -> Void{
        Log.enter()
        self.tabBarController?.tabBarHidden = false
        
        RadarService.sharedInstance.startLoading(self)
        self.setUpCriteria()
        Log.exit()
    }
    
    func onFindUnfinishedTransaction() -> Void{
        Log.enter()
        
        self.tabBarController?.tabBarHidden = false
        
        RadarService.sharedInstance.stopLoading()
        
        SCLAlertView().showInfo("尚未建立服務", subTitle: "您之前已經成功購買租屋雷達服務，但是我們發現還沒為您建立服務", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
            () -> Void in
            
            let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            if unfinishedTranscations.count > 0{
                self.doUnfinishTransactions(unfinishedTranscations)
            }
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
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) {
                (result, error) -> Void in
                
                if error != nil{
                    Log.error("Cannot get criteria by user id:\(userId)")
                    
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
                    
                    RadarService.sharedInstance.stopLoading()
                    
                    SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法為您更新租屋雷達條件，請您稍後再試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        self.reloadRadarUI()
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
            RadarService.sharedInstance.stopLoading()
            zuzuCriteria.enabled = isEnabled
            self.reloadRadarUI()
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                    if error != nil{
                        Log.error("Cannot enable criteria by user id:\(userId)")
                        
                        RadarService.sharedInstance.stopLoading()
                        
                        SCLAlertView().showInfo("設定成功", subTitle: "很抱歉，租屋雷達條件儲存成功，但是尚無法成功啟用，請您稍後嘗試手動啟用", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock(){
                            self.reloadRadarUI()
                        }
                        
                        return
                    }
                    
                    Log.info("enable criteria success")
                    
                    RadarService.sharedInstance.stopLoading()
                    
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
                    
                    Log.info("create criteria fails")
                    
                    RadarService.sharedInstance.stopLoading()
                    
                    Log.error("Cannot update criteria by user id:\(userId)")
                    
                    SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前無法成功為您設定租屋雷達條件，請稍後再試!", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF).setDismissBlock(){
                        self.reloadRadarUI()
                    }
                    return
                }
                
                Log.info("create criteria success")
                
                RadarService.sharedInstance.stopLoading()
                
                self.reloadRadarUI()
            }
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
        RadarService.sharedInstance.stopLoading()
        AmazonClientManager.sharedInstance.loginFromView(self, mode: 3, cancelHandler: self.cancelLoginHandler, withCompletionHandler: self.handleCompleteLoginForUnfinishTransaction)
    }
    
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        Log.enter()
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        RadarService.sharedInstance.stopLoading()
        RadarService.sharedInstance.startLoadingText(self,text:"建立服務...")
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
            //self.showDisplayRadarUI()
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
            
            transactionDone()
            //self.showDisplayRadarUI()
        }
    }
    
    func transactionDone(){
        Log.enter()
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        RadarService.sharedInstance.stopLoading()
        Log.exit()
    }
    
    func alertUnfinishError(){
        let msgTitle = "服務建立失敗"
        let okButton = "知道了"
        let subTitle = "您已經成功購買過租屋雷達，但是目前無法成功為您建立服務，請您請後再試！ 若持續發生失敗，請與臉書粉絲團客服聯繫!"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                alertView.addButton("重試") {
                    self.doUnfinishTransactions(unfinishedTranscations)
                }
            }
        }
        
        alertView.addButton("取消") {
        }
        
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
}
