//
//  StoreReceiptObtainer.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/2/17.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

/// Completion handler called when products are fetched.
public typealias RequestReceiptCompletionHandler = (success: Bool, receiptData: NSData?) -> ()


class StoreReceiptObtainer: NSObject {
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: StoreReceiptObtainer {
        struct Singleton {
            static let instance = StoreReceiptObtainer()
        }
        
        return Singleton.instance
    }
    
    private var completionHandler: RequestReceiptCompletionHandler?
    
    static let receiptUrl = NSBundle.mainBundle().appStoreReceiptURL
    
    internal func isReceiptExist() -> Bool {
        if let receiptUrl = StoreReceiptObtainer.receiptUrl {
            let fileExists = NSFileManager.defaultManager().fileExistsAtPath(receiptUrl.path!)
            
            if fileExists {
                Log.debug("Appstore Receipt now exists")
                return true
            }
        }
        
        return false
    }
    
    internal func readReceipt() -> NSData? {
        
        return receiptData(StoreReceiptObtainer.receiptUrl)
        
    }
    
    internal func fetchReceipt(handler: RequestReceiptCompletionHandler) {
        
        self.completionHandler = handler

        if(isReceiptExist()) {
            Log.debug("Appstore Receipt now exists")
            return
        }
        
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }
    
    private func receiptData(appStoreReceiptURL : NSURL?) -> NSData? {
        
        guard let receiptURL = appStoreReceiptURL,
            receipt = NSData(contentsOfURL: receiptURL) else {
                return nil
        }
        
        do {
            let receiptData = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            let requestContents = ["receipt-data" : receiptData]
            let requestData = try NSJSONSerialization.dataWithJSONObject(requestContents, options: [])
            return requestData
        }
        catch let error as NSError {
            Log.debug(error.localizedDescription)
        }
        
        return nil
    }
}

/// MARK: SKRequestDelegate methods
// SKRequestDelegate: to fetch the receipt data from the Apple server
extension StoreReceiptObtainer: SKRequestDelegate {
    
    func requestDidFinish(request: SKRequest) {
        Log.debug("request did finish")
        
        if(isReceiptExist()) {
            
            Log.debug("Appstore Receipt now exists")
            
            if let data = receiptData(StoreReceiptObtainer.receiptUrl) {
                completionHandler?(success: true, receiptData: data)
            } else {
                completionHandler?(success: true, receiptData: nil)
            }
            
        } else {
            
            Log.debug("something went wrong while obtaining the receipt, maybe the user did not successfully enter it's credentials")
            
            completionHandler?(success: false, receiptData: nil)
            
        }
        clearRequest()
    }
    
    func request(request: SKRequest, didFailWithError error: NSError) {
        Log.debug("request did fail with error: \(error.domain)")
        
        completionHandler?(success: false, receiptData: nil)
        clearRequest()
    }
    
    private func clearRequest() {
        completionHandler = nil
    }
    
}