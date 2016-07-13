//
//  RadarService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SCLAlertView

private let Log = Logger.defaultLogger


class RadarService : NSObject {
    
    var successTransaction = 0
    
    var failTransaction = 0
    
    var currentTransactionIdx = 0
    
    
    var isLoading = false
    var isLoadingText = false
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: RadarService {
        struct Singleton {
            static let instance = RadarService()
        }
        
        return Singleton.instance
    }
    
    // MARK: start
    func start(){

    }
    

    func composeZuzuPurchase(transaction: SKPaymentTransaction, product: ZuzuProduct?=nil, purchaseReceipt:NSData, handler: (result: ZuzuPurchase?, error: NSError?) -> Void){
        
        if let userId = UserManager.getCurrentUser()?.userId,
            transId = transaction.transactionIdentifier{
            
            if let purchaseProduct = product{
                let purchase = ZuzuPurchase(transactionId: transId, userId: userId, productId: purchaseProduct.productIdentifier, productPrice: purchaseProduct.price, purchaseReceipt: purchaseReceipt)
                
                purchase.productTitle = purchaseProduct.localizedTitle
                purchase.productLocaleId = purchaseProduct.priceLocale.localeIdentifier
                
                handler(result: purchase, error: nil)
                return
            }
            
            let productId = transaction.payment.productIdentifier
            
            ZuzuStore.sharedInstance.requestProducts { success, products in
                if success {
                    for product in products{
                        if product.productIdentifier == productId{
                            let purchase = ZuzuPurchase(transactionId: transId, userId: userId, productId: productId, productPrice: product.price, purchaseReceipt: purchaseReceipt)
                            purchase.productTitle = product.localizedTitle
                            purchase.productLocaleId = product.priceLocale.localeIdentifier
                            handler(result: purchase, error: nil)
                            return
                        }
                    }
                    
                    handler(result: nil, error: NSError(domain: "Cannot find any product associated with the transaction", code: -1, userInfo: nil))
                    
                }else{
                    handler(result: nil, error: NSError(domain: "Can not request products from ZuzuStore", code: -1, userInfo: nil))
                }
                
            }
        }else{
            handler(result: nil, error: NSError(domain: "Invalid parameters", code: -1, userInfo: nil))
        }
    }

    func createPurchase(transaction: SKPaymentTransaction, product: ZuzuProduct?=nil, handler: (purchaseTransaction: SKPaymentTransaction, error: NSError?) -> Void){
        
        if let receipt = ZuzuStore.sharedInstance.readReceipt(){
            self.createPurchase(transaction, product:product, receipt: receipt, handler:handler)
        }
        else {
            ZuzuStore.sharedInstance.fetchReceipt(){
                (success, receiptData) -> () in
                if receiptData != nil{
                    self.createPurchase(transaction, product:product, receipt: receiptData!, handler:handler)
                }
                else{
                    Log.error("Fail to ftech receipt for the transaction")
                    handler(purchaseTransaction: transaction, error: NSError(domain: "Fail to ftech receipt for the transaction", code: -1, userInfo: nil))
                }
            }
        }
    }
    
    func createPurchase(transaction: SKPaymentTransaction, product: ZuzuProduct?, receipt: NSData,handler: (purchaseTransaction: SKPaymentTransaction, error: NSError?) -> Void){
        
        self.composeZuzuPurchase(transaction, product:product, purchaseReceipt: receipt){
            (result, error) -> Void in
            if let purchase = result{
                
                ZuzuWebService.sharedInstance.createPurchase(purchase){ (result, error) -> Void in
                    if error != nil{
                        Log.error("Fail to createPurchase for transaction: \(transaction.transactionIdentifier)")
                        
                        self.checkPurchaseExist(purchase.transactionId){
                            (isExist, checkExistError) -> Void in
                            
                            if isExist == true{
                                handler(purchaseTransaction: transaction, error: nil)
                                return
                            }
                            
                            handler(purchaseTransaction: transaction, error: error)
                            
                        }
                        
                        
                        return
                    }
                    
                    handler(purchaseTransaction: transaction, error: nil)
                }
            }else{
                Log.error("Fail to composeZuzuPurchase for transaction: \(transaction.transactionIdentifier)")
                handler(purchaseTransaction: transaction, error: error)
            }
        }
    }
    
    func checkPurchaseExist(transactionId: String, handler: (isExist: Bool, checkExistError: ErrorType?) -> Void) {
        if let userId = UserManager.getCurrentUser()?.userId {
            
            ZuzuWebService.sharedInstance.getPurchaseByUserId(userId){
                (totalNum, result, error) -> Void in
                
                if error != nil{
                    Log.error("cannot get purchase information for transaction: \(transactionId)")
                    handler(isExist: false, checkExistError: error)
                    return
                }
                
                if(result != nil){
                    for purchase in result!{
                        if purchase.transactionId == transactionId{
                            handler(isExist: true, checkExistError: nil)
                            return
                        }
                    }
                }
                
                Log.error("purchase not exist for transaction: \(transactionId)")
                
                handler(isExist: false, checkExistError: nil)
            }
        }
    }
    
    
    func checkCriteria(criteria: SearchCriteria) -> Bool{
        let region = criteria.region
        let price = criteria.price
        let size = criteria.size
        
        var subTitle = ""
        
        if region == nil || region?.count<=0{
            subTitle  =  "• 地區 "
        }
        
        if price == nil{
            subTitle  =  "\(subTitle)\n•租金範圍"
        }
        
        if size == nil{
            subTitle  =  "\(subTitle)\n•坪數範圍"
        }
        
        if subTitle == ""{
            return true
        }
        
        subTitle = "請設定下列幾項必要條件，以達到租屋雷達最好的效果:\n\(subTitle)"
        
        SCLAlertView().showInfo("必要條件尚未設定", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
        return false
        
    }
    
    // MARK: - Loading
    
    func startLoading(theViewController: UIViewController, animated: Bool = true, minShowTime: Float? = nil, graceTime: Float? = nil){
        if self.isLoading == true{
            return
        }
        
        if self.isLoadingText == true{
            return
        }
        
        Log.debug("startLoading")
        
        self.isLoading = true
        LoadingSpinner.shared.setOpacity(0.3)
        
        if let graceTime = graceTime {
            LoadingSpinner.shared.setGraceTime(graceTime)
        } else {
            LoadingSpinner.shared.setImmediateAppear(true)
        }
        
        if let min = minShowTime{
            LoadingSpinner.shared.setMinShowTime(min)
        }
        
        
        LoadingSpinner.shared.startOnView(theViewController.view, animated: animated)
    }
    
    func startLoadingText(theViewController: UIViewController, text: String, animated: Bool = true, minShowTime: Float? = nil, graceTime: Float? = nil){
        if self.isLoadingText == true{
            LoadingSpinner.shared.updateText(text)
            if let min = minShowTime{
                LoadingSpinner.shared.setMinShowTime(min)
            }
            return
        }
        
        if self.isLoading == true{
            LoadingSpinner.shared.updateText(text)
            if let min = minShowTime{
                LoadingSpinner.shared.setMinShowTime(min)
            }
            return
        }
        
        Log.debug("startLoadingText")
        
        self.isLoadingText = true
        
        LoadingSpinner.shared.setOpacity(0.8)
        LoadingSpinner.shared.setText(text)
        
        if let graceTime = graceTime {
            LoadingSpinner.shared.setGraceTime(graceTime)
        } else {
            LoadingSpinner.shared.setImmediateAppear(true)
        }
        
        if let min = minShowTime{
            LoadingSpinner.shared.setMinShowTime(min)
        }
        
        LoadingSpinner.shared.startOnView(theViewController.view, animated: animated)
    }
    
    func stopLoading(animated: Bool = true){
        Log.enter()
        self.isLoading = false
        self.isLoadingText = false
        LoadingSpinner.shared.stop(animated)
        Log.exit()
    }
    
}

extension RadarService {

    /// unfinished transactions
    func tryCompleteUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction],
        completeHandler: ((success: Int, fail: Int) -> Void)?){
            
            Log.enter()
            
            self.currentTransactionIdx = 0
            self.successTransaction = 0
            self.failTransaction = 0
            
            if unfinishedTranscations.count <= 0{
                Log.error("no unfinished transactions")
                return
            }
            
            Log.debug("unfinishedTranscations count: \(unfinishedTranscations.count)")
            
            self.performFinishTransactions(unfinishedTranscations, completeHandler:completeHandler)
        
            Log.exit()
    }
    
    func performFinishTransactions(unfinishedTranscations:[SKPaymentTransaction],
        completeHandler: ((success: Int, fail: Int) -> Void)?){
        
        if self.currentTransactionIdx >= unfinishedTranscations.count{
            if let handler = completeHandler{
                handler(success:self.successTransaction, fail:self.failTransaction)
            }
            
            self.currentTransactionIdx = 0
            self.successTransaction = 0
            self.failTransaction = 0
            
            return
        }
        
        let transaction = unfinishedTranscations[self.currentTransactionIdx]
        
        let tranId = transaction.transactionIdentifier ?? "nil"
        
        RadarService.sharedInstance.createPurchase(transaction){
            
            (purchaseTransaction, error) -> Void in
            
            self.currentTransactionIdx = self.currentTransactionIdx + 1
            
            if error != nil{
                
                GAUtils.trackEvent(GAConst.Catrgory.ZuzuRadarPurchase,
                    action: GAConst.Action.ZuzuRadarPurchase.ResumeTransactionFailure, label: transaction.payment.productIdentifier)
                
                Log.error("Encounter error while finish the transaction: \(tranId)")
                
                Log.error("error info: \(error)")
                
                Log.error("transation \(tranId) is alreadt not successful")
                
                self.failTransaction = self.failTransaction + 1
                
                self.performFinishTransactions(unfinishedTranscations, completeHandler:completeHandler)
                
                return
            }
            
            GAUtils.trackEvent(GAConst.Catrgory.ZuzuRadarPurchase,
                action: GAConst.Action.ZuzuRadarPurchase.ResumeTransactionSuccess, label: transaction.payment.productIdentifier)
            
            Log.debug("Successfully finish trnasaction: \(tranId)")
            
            ZuzuStore.sharedInstance.finishTransaction(purchaseTransaction)
            
            self.successTransaction = self.successTransaction + 1
            
            self.performFinishTransactions(unfinishedTranscations, completeHandler:completeHandler)
        }
    }
    
}

