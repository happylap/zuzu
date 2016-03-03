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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isUpdateMode == true{
            self.activateButton.hidden = true
            self.activateButton.enabled = false
        }
        self.houseInfoLabel.numberOfLines = 0
        self.updateCriteriaTextLabel()
        self.registerCriteriaObserver()
        self.currentConditionsLabel.textColor = UIColor.colorWithRGB(0xf5a953, alpha: 1)
    }
    
    private func updateCriteriaTextLabel(){
        let displayItem = RadarDisplayItem(criteria:self.searchCriteria)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.detail
        var filterNum = 0
        if let filterGroups = searchCriteria.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherCriteriaLabel?.text = "其他\(filterNum)個過濾條件"
    }
    
    @IBOutlet weak var currentConditionsLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    @IBAction func activateButtonClick(sender: UIButton) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            vc.completeHandler = { () -> Void in
                ///Show tab bar
                self.tabBarController?.tabBarHidden = false
                self.registerCriteriaObserver()
            }
            
            presentViewController(vc, animated: true, completion: nil)
            
            vc.purchaseCompleteHandler  = self.createCriteriaAfterPurchase
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
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        if(parent == nil) {
            /// Filter Setting Finished
            self.delegate?.onCriteriaSettingDone(searchCriteria)
        }
    }
    
    func createCriteriaAfterPurchase(isSuccess:Bool, product: SKProduct) -> Void{
        if isSuccess == true{
            if let userId = UserDefaultsUtils.getZuzuUserId(){
                let zuzuPurchase = ZuzuPurchase(userId:userId ,productId:product.productIdentifier, productPrice:product.price)
                
                zuzuPurchase.purchaseReceipt = "test".dataUsingEncoding(NSUTF8StringEncoding)
                
                ZuzuWebService .sharedInstance.purchaseCriteria(self.searchCriteria, purchase: zuzuPurchase){
                    (result, error) -> Void in
                    if error != nil{
                        self.alertServerError("購買雷達失敗，，請檢查您的裝置是否處於無網路狀態或飛航模式")
                    }
                }
            }
        }
    }
    
    private func alertServerError(subTitle: String) {
        
        let alertView = SCLAlertView()
        
        alertView.showInfo("與伺服器連線失敗", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    func handleResetCriteria(notification: NSNotification){
        Log.enter()
        if let zuzuCriteria = RadarService.sharedInstance.zuzuCriteria{
            if zuzuCriteria.criteria != nil{
                NSNotificationCenter.defaultCenter().removeObserver(self)
                if let vc = self.navigationController as? RadarNavigationController{
                    vc.showDisplayRadarView(zuzuCriteria)
                }
            }
        }else{
            NSNotificationCenter.defaultCenter().removeObserver(self)
            if let vc = self.navigationController as? RadarNavigationController{
                vc.showRetryRadarView() // error -> show retry
            }
        }
        Log.exit()
    }
    
    func registerCriteriaObserver(){
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            NSNotificationCenter.defaultCenter().removeObserver(self)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleResetCriteria:", name: ResetCriteriaNotification, object: nil)
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

