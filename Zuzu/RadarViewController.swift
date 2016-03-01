//
//  RadarViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

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
            updateCriteriaTextLabel()()
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
        updateCriteriaTextLabel()()
    }
    
    private func updateCriteriaTextLabel()(){
        let displayItem = RadarDisplayItem(criteria:self.searchCriteria)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.detail
        var filterNum = 0
        if let filterGroups = searchCriteria.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherCriteriaLabel?.text = "其他\(filterNum)個過濾條件"
    }
    
    
    @IBOutlet weak var regionLabel: UILabel!
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherCriteriaLabel: UILabel!
    
    @IBOutlet weak var activateButton: UIButton!
    
    @IBAction func activateButtonClick(sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            vc.completeHandler = { () -> Void in
                ///Show tab bar
                self.tabBarController?.tabBarHidden = false
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
                
                ZuzuWebService .sharedInstance.purchaseCriteria(self.searchCriteria, purchase: zuzuPurchase){
                    (result, error) -> Void in
                    if error != nil{
                        
                    }
                }
            }
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

