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


class RadarPurchaseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // This list of available in-app purchases
    var products = [SKProduct]()
    
    var cancelPurchaseHandler: (() -> Void)?
    
    var completePurchaseHandler: ((isSuccess:Bool, error: NSError?) -> Void)?
    
    var unfinishedTransactionHandler: (() -> Void)?
    
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
        reload()
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self, mode: 2) {
                (task: AWSTask!) -> AnyObject! in
                return nil
            }
        }
    }
    
    // MARK: - Private Util
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) onCancelButtonTouched")
        
        if let cancelPurchaseHandler = self.cancelPurchaseHandler {
            cancelPurchaseHandler()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    
    // Fetch the products from iTunes connect, redisplay the table on successful completion
    func reload() {
        products = []
        tableView.reloadData()
        ZuzuStore.sharedInstance.requestProducts { success, products in
            if success {
                self.products = products
                self.tableView.reloadData()
            }
        }
    }
    
    // Purchase the product
    func onBuyButtonTapped(button: UIButton) {
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self, mode: 2) {
                (task: AWSTask!) -> AnyObject! in
                
                if(task.error == nil) {
                    self.runOnMainThread({ () -> Void in
                        self.alertPurchase(button)
                    })
                }
                
                return nil
            }
        }else{
            alertPurchase(button)
        }
    }
    
    func alertPurchase(button: UIButton){
        let product = products[button.tag]
        Log.info("productIdentifier: \(product.productIdentifier)")
        priceFormatter.locale = product.priceLocale
        let price = priceFormatter.stringFromNumber(product.price)
        
        let loginAlertView = SCLAlertView()
        loginAlertView.addButton("購買") {
            if(ZuzuStore.sharedInstance.makePurchase(product, handler: self)) {
                
                ///Successfully sent out the payment request. Wait for handler callback
                
            } else {
                Log.info("Find unfinished transaction")
                if let handler = self.unfinishedTransactionHandler{
                    handler()
                }
            }
        }
        
        loginAlertView.addButton("未完成交易") {
            
            let transList = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            
            for trans in transList {
                ZuzuStore.sharedInstance.finishTransaction(trans)
                Log.warning("Unfinished Transactions: \(trans.transactionIdentifier), product = \(trans.payment.productIdentifier)")
            }
        }

        let subTitle = "您要以 \(price!) 的價格購買一個 \(product.localizedTitle) 嗎？"
        loginAlertView.showNotice("確認您的購買項目", subTitle: subTitle, closeButtonTitle: "取消", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
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
        cell.textLabel?.text = product.localizedTitle
        
        /*if ZuzuStore.sharedInstance.isProductPurchased(product.productIdentifier) {
            cell.accessoryType = .Checkmark
            cell.accessoryView = nil
            cell.detailTextLabel?.text = ""
        }*/
        
        if ZuzuStore.canMakePayments() {
            priceFormatter.locale = product.priceLocale
            cell.detailTextLabel?.text = priceFormatter.stringFromNumber(product.price)
            
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 72, height: 36))
            button.backgroundColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            button.setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: .Normal)
            button.setTitle("購買", forState: .Normal)
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            button.layer.cornerRadius = CGFloat(18.0)
            
            button.tag = indexPath.row
            button.addTarget(self, action: "onBuyButtonTapped:", forControlEvents: .TouchUpInside)
            cell.accessoryType = .None
            cell.accessoryView = button
        }
        else {
            cell.accessoryType = .None
            cell.accessoryView = nil
            cell.detailTextLabel?.text = "Not available"
        }
        return cell
    }
}

extension RadarPurchaseViewController: ZuzuStorePurchaseHandler {
    
    func onPurchased(store: ZuzuStore, transaction: SKPaymentTransaction){
        Log.debug("\(transaction.transactionIdentifier)")
        RadarService.sharedInstance.createPurchase(transaction){
            (result: String?, error: NSError?) -> Void in

            if error != nil{
                Log.error("create purchase error")
                if let handler = self.completePurchaseHandler{
                    handler(isSuccess: false, error: NSError(domain: "設定雷達服務交易失敗", code: -1, userInfo: nil))
                }
                return
            }
            
            ZuzuStore.sharedInstance.finishTransaction(transaction)
            
            if let handler = self.completePurchaseHandler{
                handler(isSuccess: true, error: nil)
            }
        }
        
    }
    
    func onFailed(store: ZuzuStore, transaction: SKPaymentTransaction){
        Log.debug("\(transaction.transactionIdentifier)")
        if let handler = self.completePurchaseHandler{
            handler(isSuccess: false, error: NSError(domain: "購買雷達服務交易失敗", code: -1, userInfo: nil))
        }

    }

}