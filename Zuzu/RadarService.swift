//
//  RadarService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SCLAlertView
import MBProgressHUD

private let Log = Logger.defaultLogger

let ResetCriteriaNotification = "ResetCriteriaNotification"
let ZuzuUserLoginNotification = "ZuzuUserLoginNotification"
let ZuzuUserLogoutNotification = "ZuzuUserLogoutNotification"

class RadarService : NSObject {
    
    var isLoading = false
    var isLoadingText = true
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
    
    func composeZuzuPurchase(transaction: SKPaymentTransaction, purchaseReceipt:NSData, handler: (result: ZuzuPurchase?, error: NSError?) -> Void){
        
        let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id
        let transId = transaction.transactionIdentifier
        let productId = transaction.payment.productIdentifier
        
        if userId == nil{
            assert(false, "user id is nil")
            handler(result: nil, error: NSError(domain: "user id is nil", code: -1, userInfo: nil))
            return
        }
        
        if transId == nil{
            assert(false, "transaction id is nil")
            handler(result: nil, error: NSError(domain: "transId", code: -1, userInfo: nil))
            return
        }
        
        ZuzuStore.sharedInstance.requestProducts { success, products in
            if success {
                for product in products{
                    if product.productIdentifier == productId{
                        let purchase = ZuzuPurchase(transactionId: transId!, userId: userId!, productId: productId, productPrice: product.price, purchaseReceipt: purchaseReceipt)
                        purchase.productTitle = product.localizedTitle
                        handler(result: purchase, error: nil)
                        return
                    }
                }
                
                handler(result: nil, error: NSError(domain: "Cannot find any product associated with the transaction", code: -1, userInfo: nil))
                
            }else{
                handler(result: nil, error: NSError(domain: "Can not request products from ZuzuStore", code: -1, userInfo: nil))
            }
            
        }
    }
    

    func createPurchase(transaction: SKPaymentTransaction, handler: (result: String?, error: NSError?) -> Void){
        if let receipt = ZuzuStore.sharedInstance.readReceipt(){
            self.composeZuzuPurchase(transaction, purchaseReceipt: receipt){
                (result, error) -> Void in
                if let purchase = result{
                    ZuzuWebService.sharedInstance.createPurchase(purchase){ (result, error) -> Void in
                        if error != nil{
                            Log.error("Fail to createPurchase for transaction: \(transaction.transactionIdentifier)")
                            
                            self.checkPurchaseExist(purchase.transactionId){
                                (isExist, checkExistError) -> Void in
                                
                                if isExist == true{
                                    handler(result: "", error: nil)
                                    return
                                }
                                
                                handler(result: nil, error: error)
                                
                             }
                            
                            
                            return
                        }
                        
                        handler(result: result, error: nil)
                    }
                }else{
                    Log.error("Fail to composeZuzuPurchase for transaction: \(transaction.transactionIdentifier)")
                    handler(result: nil, error: error)
                }
            }
        }else{
            Log.error("Fail to read receipt for the transaction")
            handler(result: nil, error: NSError(domain: "Fail to read receipt for the transaction", code: -1, userInfo: nil))
            //
        }
    }
    
    func checkPurchaseExist(transactionId: String, handler: (isExist: Bool, checkExistError: ErrorType?) -> Void)
    {
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
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
            subTitle  =  "\(subTitle)\n地區"
        }
        
        if price == nil{
            subTitle  =  "\(subTitle)\n租金範圍"
        }
        
        if size == nil{
            subTitle  =  "\(subTitle)\n坪數範圍"
        }
        
        if subTitle == ""{
            return true
        }
        
        subTitle = "尚未設定以下條件:\(subTitle)"
        
        SCLAlertView().showInfo("設定雷達條件", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
        return false
        
    }
    
    // MARK: - Loading
    
    func startLoading(theViewController: UIViewController){
        if self.isLoading == true{
            return
        }
        self.isLoading = true
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(theViewController.view)
    }
    
    func stopLoading(theViewController: UIViewController){
        if self.isLoading == true{
            self.isLoading = false
            LoadingSpinner.shared.stop()
        }
        
        if self.isLoadingText == true{
            self.isLoadingText = false
            MBProgressHUD.hideHUDForView(theViewController.view, animated: true)
        }
    }
    
    func startLoadingText(theViewController: UIViewController, text: String){
        if self.isLoadingText == true{
            return
        }
        self.isLoadingText = true
        
        let dialog = MBProgressHUD.showHUDAddedTo(theViewController.view, animated: true)
        
        dialog.animationType = .ZoomIn
        dialog.dimBackground = true
        dialog.labelText = text
        
        theViewController.runOnMainThread() { () -> Void in}
    }
    
}