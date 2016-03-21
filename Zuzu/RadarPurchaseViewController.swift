//
//  RadarPurchaseViewController.swift
//  Zuzu
//
//  Created by eechih on 1/22/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView
import StoreKit

private let Log = Logger.defaultLogger

protocol RadarPurchaseDelegate: class {
    
    func onPurchaseCancel() -> Void
    
    func onPurchaseSuccess() -> Void
    
    func onFindUnfinishedTransaction(unfinishedTranscations:[SKPaymentTransaction]) -> Void
    
    func onLoggedInForPurchase() -> Void
}

class RadarPurchaseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var purchasedProduct: ZuzuProduct?
    
    // This list of available in-app purchases
    var products = [ZuzuProduct]()
    
    var purchaseDelegate: RadarPurchaseDelegate?
    
    deinit {
        // NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // priceFormatter is used to show proper, localized currency
    lazy var priceFormatter: NSNumberFormatter = {
        let pf = NSNumberFormatter()
        pf.formatterBehavior = .Behavior10_4
        pf.numberStyle = .CurrencyStyle
        return pf
    }()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    // Purchase Button UI
    let disabledColor = UIColor.colorWithRGB(0xE0E0E0, alpha: 0.8)
    
    // MARK: - Private Util
    
    // Fetch the products from iTunes connect, redisplay the table on successful completion
    private func loadProducts() {
        
        RadarService.sharedInstance.startLoading(self)
        
        self.products.removeAll()
        
        ZuzuStore.sharedInstance.requestProducts { success, products in
            
            /// Provide free trial whether there are products from AppStroe or not
            let trialProduct = ZuzuProducts.TrialProduct
            let productId = trialProduct.productIdentifier

            if let expiryDate = ZuzuProducts.FreeTrialExpiry {
                
                Log.debug("Time to expire frmo now = \(expiryDate.timeIntervalSinceNow)")
                
                if(expiryDate.timeIntervalSinceNow >= 0) {
                    if(!UserDefaultsUtils.hasUsedFreeTrial(productId)) {
                        self.products.append(trialProduct)
                    }
                }
                
            }
            
            if success {
                let storeProducts = products.map({ (product) -> ZuzuProduct in
                    
                    let zuzuProduct:ZuzuProduct = ZuzuProduct(productIdentifier: product.productIdentifier,
                        localizedTitle: product.localizedTitle,
                        price: product.price,
                        priceLocale: product.priceLocale)
                    
                    return zuzuProduct
                })
                
                
                self.products.appendContentsOf(storeProducts)
            }
            
            /// Display result no matter whether we get the products from AppStore successfully
            RadarService.sharedInstance.stopLoading()
            self.tableView.reloadData()
        }
    }
    
    private func proceedTransaction(product: ZuzuProduct) {
        
        self.purchasedProduct = product
        
        if(product.productIdentifier == ZuzuProducts.ProductRadarFreeTrial) {
            //Alert redeem
            
            let freeTrialAlertView = SCLAlertView()
            
            let subTitle = "請問是否確認現在兌換：\(product.localizedTitle)？"
            
            freeTrialAlertView.addButton("馬上兌換", action: { () -> Void in
                
                /// Check if the free trial is already activated
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id {
                    
                    RadarService.sharedInstance.startLoading(self)
                    
                    ZuzuWebService.sharedInstance.getPurchaseByUserId(userId, handler: { (totalNum, purchaseList, error) -> Void in
                        
                        if let _ = error {
                            RadarService.sharedInstance.stopLoading()
                            
                            SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，目前暫時無法為您完成此操作，請稍後再試，謝謝！", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                            return
                        }
                        
                        /// Check if free trial is already activated
                        let alreadyActivated = purchaseList?.contains({ (purchase) -> Bool in
                            
                            return (purchase.productId == ZuzuProducts.ProductRadarFreeTrial)
                            
                        }) ?? false
                        
                        
                        if(alreadyActivated) {
                            
                            Log.debug("Free trial already activated")
                            
                            /// The free trial is activated successfully
                            UserDefaultsUtils.setUsedFreeTrial(ZuzuProducts.ProductRadarFreeTrial)
                            
                            RadarService.sharedInstance.stopLoading()
                            
                            SCLAlertView().showInfo("您已經試用過此服務", subTitle: "若覺得滿意我們的服務，可以考慮購買正式服務，讓您輕鬆找租屋。豬豬快租非常感謝您的支持！", closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF).setDismissBlock({ () -> Void in
                                self.loadProducts()
                            })
                            
                        } else {
                            let transId = ""
                            let productId = product.productIdentifier
                            let price = product.price
                            let purchase = ZuzuPurchase(transactionId:transId, userId: userId, productId: productId, productPrice: price)
                            purchase.productTitle = product.localizedTitle
                            
                            
                            if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
                                AmazonSNSService.sharedInstance.createDevice(deviceTokenString)
                            }
                            
                            ZuzuWebService.sharedInstance.createPurchase(purchase){
                                (result, error) -> Void in
                                
                                if error != nil{
                                    Log.error("Fail to createPurchase for product: \(productId)")
                                    
                                    RadarService.sharedInstance.checkPurchaseExist(transId){
                                        (isExist, checkExistError) -> Void in
                                        if isExist == true{
                                            
                                            /// The free trial is activated successfully
                                            
                                            UserDefaultsUtils.setUsedFreeTrial(ZuzuProducts.ProductRadarFreeTrial)
                                            
                                            self.dismissViewControllerAnimated(true){
                                                
                                                RadarService.sharedInstance.stopLoading()
                                                
                                                self.purchaseDelegate?.onPurchaseSuccess()
                                            }
                                            
                                            return
                                        }
                                        
                                        RadarService.sharedInstance.stopLoading()
                                        
                                        SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，我們目前無法為您建立雷達服務，請您稍後重試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                                        
                                    }
                                    
                                    return
                                }

                                /// The free trial is activated successfully
                                UserDefaultsUtils.setUsedFreeTrial(ZuzuProducts.ProductRadarFreeTrial)
                                
                                self.dismissViewControllerAnimated(true){
                                    
                                    RadarService.sharedInstance.stopLoading()
                                    
                                    self.purchaseDelegate?.onPurchaseSuccess()
                                }

                            }
                        }
                        
                    })
                }
            })
            
            freeTrialAlertView.showNotice("租屋雷達免費兌換", subTitle: subTitle, closeButtonTitle: "下次再說", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            
        } else{
            
            //AppStore will pop up confirmation dialog
            RadarService.sharedInstance.startLoadingText(self, text: "交易中")

            if(ZuzuStore.sharedInstance.makePurchase(product, handler: self)) {
                
                ///Successfully sent out the payment request to Zuzu Backend. Wait for handler callback
                Log.debug("Purchase Request Sent")
                
            } else {
                
                // create device here
                if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
                    AmazonSNSService.sharedInstance.createDevice(deviceTokenString)
                }
                
                ///You have an unfinished transaction for the product or the product is not valid
                Log.info("Find unfinished transaction")
                
                let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
                
                self.dismissViewControllerAnimated(true){
                    self.purchaseDelegate?.onFindUnfinishedTransaction(unfinishedTranscations)
                }
            }
            
        }
        
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        //Configure table DataSource & Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.scrollEnabled = false
        self.tableView.allowsSelection = false
        
        // Subscribe to a notification that fires when a product is purchased.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "productPurchased:", name: ProductPurchasedNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Log.debug("\(self.presentingViewController)")
        self.presentingViewController?.tabBarController?.tabBarHidden = true
        
        loadProducts()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.presentingViewController?.tabBarController?.tabBarHidden = false
    }
    
    // MARK: - Action Handlers
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) onCancelButtonTouched")
        dismissViewControllerAnimated(true){
            self.purchaseDelegate?.onPurchaseCancel()
        }
        
    }
    
    // Purchase the product
    func onBuyButtonTapped(button: UIButton) {
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self, mode: 2) {
                (task: AWSTask!) -> AnyObject! in
                
                if let error = task.error {
                    Log.warning("Login Failed  or cancelled: \(error)")
                    return nil
                }
                
                self.runOnMainThread({ () -> Void in
                    
                    self.purchaseDelegate?.onLoggedInForPurchase()
                    
                    if(button.tag < self.products.count) {
                        let product = self.products[button.tag]
                        self.proceedTransaction(product)
                    } else {
                        assert(false, "Access products array out of bound \(self.products.count)")
                    }
                })

                return nil
            }
        }else{
            if(button.tag < self.products.count) {
                let product = self.products[button.tag]
                self.proceedTransaction(product)
            } else {
                assert(false, "Access products array out of bound \(self.products.count)")
            }
        }
    }
    
    // MARK: - Table View Data Source
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("radarPurchaseTableViewCell", forIndexPath: indexPath)
        
        let product = products[indexPath.row]
        
        self.priceFormatter.locale = product.priceLocale
        cell.detailTextLabel?.text = priceFormatter.stringFromNumber(product.price)
        
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 72, height: 36))
        button.backgroundColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
        button.setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: .Normal)
        
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
        button.layer.cornerRadius = CGFloat(18.0)
        
        if(product.productIdentifier == ZuzuProducts.ProductRadarFreeTrial) {
            cell.textLabel?.text = "\(product.localizedTitle)"
            
            cell.detailTextLabel?.text = "免費，兌換期限：2016-06-30"
            
            button.setTitle("兌換", forState: .Normal)
            cell.textLabel?.textColor = UIColor.colorWithRGB(0xFF6666)
            
        } else {
            cell.textLabel?.text = product.localizedTitle
            button.setTitle("購買", forState: .Normal)
            cell.textLabel?.textColor = UIColor.blackColor()
            
            if(!ZuzuStore.canMakePayments()) {
                button.enabled = false
                button.setTitleColor(disabledColor, forState: .Normal)
                button.layer.borderColor = disabledColor.CGColor
            }
            
        }
        
        button.tag = indexPath.row
        button.addTarget(self, action: "onBuyButtonTapped:", forControlEvents: .TouchUpInside)
        
        cell.accessoryType = .None
        cell.accessoryView = button
        
        return cell
    }
}

// MARK: - ZuzuStorePurchaseHandler

extension RadarPurchaseViewController: ZuzuStorePurchaseHandler {
    
    func onPurchased(store: ZuzuStore, transaction: SKPaymentTransaction){
        
        Log.debug("\(transaction.transactionIdentifier)")
        
        // create device here
        if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
            AmazonSNSService.sharedInstance.createDevice(deviceTokenString)
        }
        
        RadarService.sharedInstance.createPurchase(transaction, product:self.purchasedProduct){
            (purchaseTransaction, error) -> Void in
            if error != nil{
                
                RadarService.sharedInstance.stopLoading()
                Log.error("create purchase error")
 
                SCLAlertView().showInfo("網路連線失敗", subTitle: "很抱歉，您的交易已經成功，但是目前無法為您建立雷達服務，請您稍後重試！", closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                
                return

            }
            
            self.finishTransaction(transaction)
        }
    }
    
    func finishTransaction(transaction: SKPaymentTransaction){
        
        Log.debug("finish transation")
        
        ZuzuStore.sharedInstance.finishTransaction(transaction)
        
        self.dismissViewControllerAnimated(true){
            
            RadarService.sharedInstance.stopLoading()

            self.purchaseDelegate?.onPurchaseSuccess()
        }
    }
    
    
    func onFailed(store: ZuzuStore, transaction: SKPaymentTransaction){
        Log.debug("\(transaction.transactionIdentifier)")

        RadarService.sharedInstance.stopLoading()
        
        SCLAlertView().showInfo("交易失敗", subTitle: "很抱歉，您的交易並未成功，請您稍後重試!", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        
    }
    
    
}
