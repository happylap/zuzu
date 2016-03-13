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

let ResetCriteriaNotification = "ResetCriteriaNotification"
let ZuzuUserLoginNotification = "ZuzuUserLoginNotification"
let ZuzuUserLogoutNotification = "ZuzuUserLogoutNotification"

class RadarService : NSObject {
    
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
                            handler(result: nil, error: error)
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
    
    func checkCriteria(criteria: SearchCriteria) -> Bool{
        let region = criteria.region
        let price = criteria.price
        let types = criteria.types
        let size = criteria.size
        
        if region == nil {
             SCLAlertView().showInfo("設定雷達條件", subTitle: "尚未選擇通知條件地區", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return false
        }
        
        if types == nil{
             SCLAlertView().showInfo("設定雷達條件", subTitle: "尚未選擇用途", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return false
        }

        if price == nil{
             SCLAlertView().showInfo("設定雷達條件", subTitle: "尚未選擇租金範圍", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return false
        }
        
        if size == nil{
            SCLAlertView().showInfo("設定雷達條件", subTitle: "尚未選擇坪數範圍", closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            return false
        }
        
        return true
        
    }
}