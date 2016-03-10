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
    
    // MARK: - View Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.isUpdateMode == true{
            self.activateButton.hidden = true
            self.activateButton.enabled = false
        }

        self.updateCriteriaTextLabel()
        self.registerCriteriaObserver()
        self.currentConditionsLabel.textColor = UIColor.colorWithRGB(0xf5a953, alpha: 1)
        self.radarBannerLabel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        
        self.configureButton()
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        if(parent == nil) {
            /// Filter Setting Finished
            self.delegate?.onCriteriaSettingDone(searchCriteria)
        }
    }
    
    // MARK: - UI
    
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
    
    @IBOutlet weak var radarBannerLabel: UILabel!
    @IBOutlet weak var currentConditionsLabel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    
    // MARK: - Action
    
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
    
    // MARK: - Criteria functions
    
    func createCriteriaAfterPurchase(isSuccess:Bool, product: SKProduct) -> Void{
        if isSuccess == true{
            if let userId = UserDefaultsUtils.getZuzuUserId(){
                let zuzuPurchase = ZuzuPurchase(transactionId: "", userId:userId ,productId:product.productIdentifier, productPrice:product.price)
                
                zuzuPurchase.purchaseReceipt = "test".dataUsingEncoding(NSUTF8StringEncoding)
                
                ZuzuWebService .sharedInstance.createPurchase(zuzuPurchase){ (result, error) -> Void in
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
    
    func registerCriteriaObserver(){

    }
}

// MARK: - RadarConfigureTableViewControllerDelegate
extension RadarViewController : RadarConfigureTableViewControllerDelegate {
    func onCriteriaConfigureDone(searchCriteria:SearchCriteria){
        Log.debug("onCriteriaConfigureDone")
        self.searchCriteria = searchCriteria
    }

}

