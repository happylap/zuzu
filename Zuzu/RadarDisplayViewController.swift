//
//  RadarDisplayViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/4.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

class RadarDisplayViewController: UIViewController {

    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    private lazy var purchaseHistotyTableDataSource: RadarPurchaseHistoryTableViewDataSource = RadarPurchaseHistoryTableViewDataSource(uiViewController: self)
    
    let emptyLabel = UILabel()
    
    @IBOutlet weak var servieBannerLabel: UILabel!
    
    @IBOutlet weak var currentConditionLbel: UILabel!
    
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var priceSizeLabel: UILabel!
    
    @IBOutlet weak var otherFiltersLabel: UILabel!
    
    @IBOutlet weak var serviceStatusLabel: UILabel!
    
    @IBOutlet weak var serviceExpireLabel: UILabel!
    
    @IBOutlet weak var purchaseTableView: UITableView!
    
    @IBOutlet weak var modifyButtoon: UIButton!
    
    var zuzuCriteria = ZuzuCriteria(){
        didSet{
            if zuzuCriteria.criteria == nil{
                zuzuCriteria.criteria = SearchCriteria()
            }
            self.updateServiceTextLabel()
            self.updateCriteriaTextLabel()
        }
    }
    
    // MARK: - View Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureButton()
        self.configureBannerText()
        self.configurePurchaseTableView()
        self.updateServiceTextLabel()
        self.updateCriteriaTextLabel()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController!.tabBarHidden = false
    }

    
    // MARK: - Update UI
    
    private func updateServiceTextLabel(){
        var diff = 0
        var expirDate = ""
        if let expireDate = self.zuzuCriteria.expireTime{
            let now = NSDate()
            diff = now.daysFrom(expireDate)
            if let dateString = CommonUtils.getLocalShortStringFromDate(expireDate) {
                expirDate = dateString
            }
        }
        self.serviceStatusLabel?.text = "您的通知服務還有\(diff)天"
        self.serviceExpireLabel?.text = "到期日: \(expirDate)"
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
        self.otherFiltersLabel?.text = "其他\(filterNum)個過濾條件"
    }
    
    // MARK: - Configure UI
    
    private func configureButton() {
        modifyButtoon.layer.borderWidth = 1
        modifyButtoon.layer.borderColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
        modifyButtoon.tintColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        modifyButtoon
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Normal)
        modifyButtoon
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Selected)
    }
    
    private func configureBannerText(){
        self.currentConditionLbel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
        self.servieBannerLabel.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
    }
    
    private func configurePurchaseTableView(){
        self.purchaseTableView.delegate = self.purchaseHistotyTableDataSource
        self.purchaseTableView.dataSource = self.purchaseHistotyTableDataSource
        
        //self.purchaseTableView.rowHeight = UIScreen.mainScreen().bounds.width * (500/1440)
        
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
            
            self.navigationItem.backBarButtonItem?.title = "完成"
            
            switch identifier{
                
            case ViewTransConst.showConfigureRadar:
                if let vc = segue.destinationViewController as? RadarViewController {
                    self.navigationItem.backBarButtonItem?.title = "完成"
                    vc.delegate = self
                    vc.isUpdateMode = true
                    vc.searchCriteria = self.zuzuCriteria.criteria!
                }
            default: break
                
            }
        }
    }
    
    // MARK: - Criteria function
    
    @IBAction func enableCriteria(sender: UISwitch) {
        let isEnabled = sender.on
        if let userId = self.zuzuCriteria.userId{
            ZuzuWebService.sharedInstance.hasValidCriteriaByUserId(userId){(result, error) -> Void in
                if error != nil{
                    self.alertServerError("暫時無法更新雷達狀態，請檢查您的裝置是否處於無網路狀態或飛航模式")
                    sender.on = !isEnabled
                    return
                }
                
                if result == true{
                    ZuzuWebService.sharedInstance.enableCriteriaByUserId(self.zuzuCriteria.userId!,
                        criteriaId: self.zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                            if error != nil{
                                self.alertServerError("暫時無法更新雷達狀態，請檢查您的裝置是否處於無網路狀態或飛航模式")
                                sender.on = !isEnabled
                            }else{
                                self.zuzuCriteria.enabled = isEnabled
                            }
                    }
                }else{
                    self.showPurchaseView()
                }
            }
        }
    }
    
    private func alertServerError(subTitle: String) {
        
        let alertView = SCLAlertView()
        
        alertView.showInfo("與伺服器連線失敗", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    private func showPurchaseView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            vc.purchaseCompleteHandler = self.createCriteriaAfterPurchase
            presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func createCriteriaAfterPurchase(isSuccess:Bool, product: SKProduct) -> Void{
        if isSuccess == true{
            if let userId = UserDefaultsUtils.getZuzuUserId(){
                let zuzuPurchase = ZuzuPurchase(userId:userId ,productId:product.productIdentifier, productPrice:product.price)
                
                zuzuPurchase.purchaseReceipt = "test".dataUsingEncoding(NSUTF8StringEncoding)
                
                ZuzuWebService .sharedInstance.purchaseCriteria(self.zuzuCriteria.criteria!, purchase: zuzuPurchase){
                    (result, error) -> Void in
                    if error != nil{
                        self.alertServerError("購買雷達失敗，，請檢查您的裝置是否處於無網路狀態或飛航模式")
                    }
                }
            }
        }
    }
}

// MARK: - RadarViewControllerDelegate
extension RadarDisplayViewController : RadarViewControllerDelegate {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria){
        ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(zuzuCriteria.userId!, criteriaId: zuzuCriteria.criteriaId!, criteria: searchCriteria) { (result, error) -> Void in
            if error != nil{
                self.alertServerError("暫時無法更新雷達設定，請檢查您的裝置是否處於無網路狀態或飛航模式")
                return
            }
            
            self.zuzuCriteria.criteria = searchCriteria
            self.updateCriteriaTextLabel()
        }
    }
    
}
