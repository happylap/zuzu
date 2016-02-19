//
//  AppstoreReceiptObtainer.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/2/17.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class AppStoreReceiptObtainer: NSObject, SKRequestDelegate {
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: AppStoreReceiptObtainer {
        struct Singleton {
            static let instance = AppStoreReceiptObtainer()
        }
        
        return Singleton.instance
    }
    
    let receiptUrl = NSBundle.mainBundle().appStoreReceiptURL
    
    func obtainReceipt() {
//        var fileExists = NSFileManager.defaultManager().fileExistsAtPath(receiptUrl!.path!)
//        
//        if fileExists {
//            print("Appstore Receipt already exists")
//            return;
//        }
        
        requestReceipt()
    }
    
    func requestReceipt() {
        print("request a receipt")
        let request = SKReceiptRefreshRequest(receiptProperties: nil)
        request.delegate = self
        request.start()
    }
    
    //MARK: SKRequestDelegate methods
    
    func requestDidFinish(request: SKRequest!) {
        print("request did finish")
        var fileExists = NSFileManager.defaultManager().fileExistsAtPath(receiptUrl!.path!)
        
        if fileExists {
            print("Appstore Receipt now exists")
            return
        }
        
        print("something went wrong while obtaining the receipt, maybe the user did not successfully enter it's credentials")
    }
    
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        print("request did fail with error: \(error.domain)")
    }
}