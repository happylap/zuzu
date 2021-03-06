//
//  ZuzuPurchase.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/22/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class ZuzuPurchase: NSObject {

    var purchaseId: String?
    var transactionId: String
    var userId: String
    var store: String
    var productId: String
    var productTitle: String?
    var productLocaleId: String?
    var productPrice: NSDecimalNumber
    var purchaseTime: NSDate?
    var purchaseReceipt: NSData?

    init(transactionId: String, userId: String, productId: String, productPrice: NSDecimalNumber, purchaseReceipt: NSData) {
        self.transactionId = transactionId
        self.userId = userId
        self.store = "Apple"
        self.productId = productId
        self.productPrice = productPrice
        self.purchaseReceipt = purchaseReceipt
    }

    init(transactionId: String, userId: String, productId: String, productPrice: NSDecimalNumber) {
        self.transactionId = transactionId
        self.userId = userId
        self.store = "Apple"
        self.productId = productId
        self.productPrice = productPrice
    }

}
