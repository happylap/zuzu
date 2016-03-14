//
//  RadarDisplayViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/4.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView
import MBProgressHUD
private let Log = Logger.defaultLogger

let RadarStatusValid = "valid"

class RadarDisplayViewController: UIViewController {
    
    var isCheckService = true
    
    var isOnLogging = false
    
    var unfinishedTranscations: [SKPaymentTransaction]?
    
    var porcessTransactionNum = -1
    
    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    private lazy var purchaseHistotyTableDataSource: RadarPurchaseHistoryTableViewDataSource = RadarPurchaseHistoryTableViewDataSource(uiViewController: self)
    
    let emptyLabel = UILabel()
    
    @IBOutlet weak var criteriaEnableSwitch: UISwitch!
    
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
    
    // MARK: - View Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.serviceButton?.hidden = true
        self.serviceStatusLabel?.text = ""
        self.serviceExpireLabel?.text = ""
        self.configureButton()
        self.configureBannerText()
        self.configurePurchaseTableView()
        self.updateCriteriaTextLabel()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            if let vc = self.navigationController as? RadarNavigationController{
                vc.showRadar()
            }
            return
        }
        
        self.tabBarController?.tabBarHidden = false
        
        if self.isCheckService == false{
            self.isCheckService = true
            return
        }
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
        }else{
            if self.zuzuService != nil{
                RadarService.sharedInstance.stopLoading(self)
            }else{
                self.checkService()
            }
        }


    }
    
    // MARK: - Update UI
    
    private func updateServiceUI(){
        if let service = self.zuzuService{
            if let status = service.status{
                if status == RadarStatusValid{

                    var days = 0
                    var hours = 0
                    if let remaining = service.remainingSecond{
                        days = remaining/86400
                        hours = (remaining % 86400)/3600
                    }
                    self.serviceStatusLabel?.text = "您的租屋雷達服務還有\(days)天又\(hours)小時"
                }else{
                    self.serviceStatusLabel?.text = "您的租屋雷達服務已到期"
                    self.criteriaEnableSwitch?.on = false
                    self.criteriaEnableSwitch?.enabled = false
                    self.serviceButton?.hidden = false
                }
            }else{
                self.serviceStatusLabel?.text = "您的租屋雷達服務已到期"
                self.criteriaEnableSwitch?.on = false
                self.criteriaEnableSwitch?.enabled = false
                self.serviceButton?.hidden = false
            }
            
            // expiration date
            var expireDateStr = ""
            if let expireDate = service.expireTime{
                if let dateString = CommonUtils.getLocalShortStringFromDate(expireDate) {
                    expireDateStr = dateString
                }
            }
            self.serviceExpireLabel?.text = "到期日: \(expireDateStr)"
            
            
            return
        }

        
        self.serviceStatusLabel?.text = "很抱歉!無法取得租屋雷達服務狀態"
        self.serviceExpireLabel?.text = ""
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
            
            switch identifier{
                
            case ViewTransConst.showConfigureRadar:
                if let vc = segue.destinationViewController as? RadarViewController {
                    self.navigationItem.backBarButtonItem?.title = "返回"
                    self.isCheckService = false
                    vc.delegate = self
                    vc.displayRadarViewController = self
                    vc.isUpdateMode = true
                    vc.searchCriteria = self.zuzuCriteria.criteria!
                }
            default: break
                
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func enableCriteria(sender: UISwitch) {
        
        if let service = self.zuzuService{
            let isEnabled = sender.on
            if let status = service.status{
                if status == RadarStatusValid{
                    RadarService.sharedInstance.startLoading(self)
                    self.setCriteriaEnabled(isEnabled)
                    return
                }
            }
        }

    }
    
    @IBAction func onServiceButtonTapped(sender: AnyObject) {
        self.showPurchase()
    }
    
    func setCriteriaEnabled(isEnabled: Bool){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: self.zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in
                    self.runOnMainThread(){
                        if error != nil{
                            RadarService.sharedInstance.stopLoading(self)
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "啟動雷達設定失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                            self.criteriaEnableSwitch.on = self.zuzuCriteria.enabled ?? false
                            return
                        }
                        
                        
                        self.zuzuCriteria.enabled = isEnabled
                        var subTitle = "租屋雷達服務已經啟用"
                        if isEnabled == false{
                            subTitle = "租屋雷達服務已經停用"
                        }
                        RadarService.sharedInstance.stopLoading(self)
                        SCLAlertView().showInfo("設定成功", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
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
            if let vc = self.navigationController as? RadarNavigationController{
                vc.showRadar()
            }
        }
    }
    
    func purchaseSuccessHandler() -> Void{
        Log.enter()
        self.tabBarController?.tabBarHidden = false
        RadarService.sharedInstance.startLoading(self)
        self.updateCriteria()
        Log.exit()
    }
    
    func unfinishedTransactionHandler() -> Void{
        Log.enter()
        self.tabBarController?.tabBarHidden = false
        SCLAlertView().showInfo("雷達服務", subTitle: "之前購買的雷達服務尚未完成設定", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, duration: 2.0, colorTextButton: 0xFFFFFF)
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.doUnfinishTransactions(unfinishedTranscations)
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
                        SCLAlertView().showInfo("與伺服器連線失敗", subTitle: "更新雷達設定失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                        self.criteriaEnableSwitch.on = self.zuzuCriteria.enabled ?? false
                    }else{
                        self.enableCriteriaForPurchase(true)
                    }
                }
            }
        }
        Log.exit()
    }
    
    func enableCriteriaForPurchase(isEnabled: Bool){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId,
                criteriaId: self.zuzuCriteria.criteriaId!, enabled: isEnabled) { (result, error) -> Void in

                    if error != nil{
                        self.runOnMainThread(){
                            self.criteriaEnableSwitch.on = false
                            RadarService.sharedInstance.stopLoading(self)
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "啟動雷達失敗", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                        }
                        return
                    }
                    
                    self.criteriaEnableSwitch.on = true
                    if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
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
                                SCLAlertView().showInfo("設定成功", subTitle: "啟動雷達設定成功", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                            }
                        }
                    }else{
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
            ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                (result: ZuzuServiceMapper?, error: NSError?) -> Void in
                self.runOnMainThread(){
                    self.purchaseHistotyTableDataSource.refresh()
                    RadarService.sharedInstance.stopLoading(self)
                    if error != nil{
                        self.zuzuService = nil
                        Log.error("get radar service error")
                        return
                    }
                    
                    self.zuzuService = result
                }
            }
        }
    }
}

// MARK: Handle unfinished transactions

extension RadarDisplayViewController{
    
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
 
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        Log.enter()
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        RadarService.sharedInstance.startLoadingText(self, text:"重新設定租屋雷達服務...")
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
        }
    }
    
    func transactionDone(){
        Log.enter()
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        self.checkService()
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