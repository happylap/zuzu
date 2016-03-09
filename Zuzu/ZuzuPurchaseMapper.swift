//
//  ZuzuPurchaseMapper.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/23/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


private let Log = Logger.defaultLogger

class ZuzuPurchaseMapper: NSObject, Mappable {

    var purchaseId: String?
    var transactionId: String?
    var userId: String?
    var store: String?
    var productId: String?
    var productTitle: String?
    var productLocaleId: String?
    var productPrice: Double?
    var purchaseTime: NSDate?
    
    override init() {
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        purchaseId          <-  map["purchase_id"]
        transactionId       <-  map["transaction_id"]
        userId              <-  map["user_id"]
        store               <-  map["store"]
        productId           <-  map["product_id"]
        productTitle        <-  map["product_title"]
        productLocaleId     <-  map["product_locale_id"]
        productPrice        <-  map["product_price"]
        purchaseTime        <- (map["purchase_time"], timeTransform)
    }
    
    //
    let timeTransform = TransformOf<NSDate, String>(fromJSON: { (values: String?) -> NSDate? in
        if let dateString = values {
            return CommonUtils.getUTCDateFromString(dateString)
        }
        return nil
    }, toJSON: { (values: NSDate?) -> String? in
        if let date = values {
            return CommonUtils.getUTCStringFromDate(date)
        }
        return nil
    })
    
    func toPurchase() -> ZuzuPurchase? {
        if let transactionId = self.transactionId, userId = self.userId, let productId = self.productId, let productPrice = self.productPrice {
            let purchase = ZuzuPurchase(transactionId: transactionId, userId: userId, productId: productId, productPrice: NSDecimalNumber(double:productPrice))
            if let store = self.store {
                purchase.store = store
            }
            purchase.purchaseId = self.purchaseId
            purchase.productTitle = self.productTitle
            purchase.productLocaleId = self.productLocaleId
            purchase.purchaseTime = self.purchaseTime
            return purchase
        }
        return nil
        
    }
}
