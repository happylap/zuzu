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
    var isUpdateMode = true
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            
            vc.purchaseCompleteHandler = {(isSuccess, appleProductId) -> Void in
                if isSuccess == true{
                    let user = "test"
                    ZuzuWebService.sharedInstance.createCriteriaByUserId(user, appleProductId: appleProductId, criteria: self.searchCriteria) { (result, error) -> Void in
                        Log.debug(result)
                        
                    }
                }else{
                    //zuzualert
                }
            }
        }
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    
    /*
    private func alertChoosingRegion(currentCity: City?) {
    
    let regionChoiceAlertView = SCLAlertView()
    
    var subTitle = "請選擇地區以進行租屋搜尋"
    
    if let currentCity = currentCity {
    var regionName = "\(currentCity.name)"
    
    if let cityRegion = currentCity.regions.first {
    regionName = "\(regionName) \(cityRegion.name)"
    }
    
    subTitle = "豬豬成功定位您的當前位置！\n\n\(regionName)"
    
    regionChoiceAlertView.addButton("使用當前位置") {
    self.setRegionToCriteria(currentCity)
    self.performSegueWithIdentifier(ViewTransConst.showSearchResult, sender: nil)
    }
    
    regionChoiceAlertView.addButton("自行選擇地區") {
    self.performSegueWithIdentifier(ViewTransConst.showAreaSelector, sender: nil)
    }
    
    } else {
    
    regionChoiceAlertView.addButton("選擇地區") {
    self.performSegueWithIdentifier(ViewTransConst.showAreaSelector, sender: nil)
    }
    
    regionChoiceAlertView.addButton("關閉") {
    }
    }
    
    regionChoiceAlertView.showCloseButton = false
    
    self.alertViewResponder = regionChoiceAlertView.showTitle("尚未選擇欲搜尋地區", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    
    }

    func onSearchButtonClicked(sender: UIButton) {
    Log.info("Sender: \(sender)", label: ActionLabel)
    
    //Hide size & price pickers
    self.setRowVisible(CellConst.pricePicker, visible: false)
    self.setRowVisible(CellConst.sizePicker, visible: false)
    
    //Validate field
    if(currentCriteria.region?.count <= 0) {
    
    if let placeMark = self.placeMark {
    let currentCity = self.getDefaultLocation(placeMark)
    
    alertChoosingRegion(currentCity)
    
    } else {
    
    alertChoosingRegion(nil)
    
    }
    
    return
    }
    
    //present the view modally (hide the tabbar)
    performSegueWithIdentifier(ViewTransConst.showSearchResult, sender: nil)
    }

    */
    
    
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
}

// MARK: - RadarConfigureTableViewControllerDelegate
extension RadarViewController : RadarConfigureTableViewControllerDelegate {
    func onCriteriaConfigureDone(searchCriteria:SearchCriteria){
        Log.debug("onCriteriaConfigureDone")
        self.searchCriteria = searchCriteria
    }

}

