//
//  ZuzuUnauth.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/5/3.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import KeychainAccess

private let Log = Logger.defaultLogger

let UnauthUserGeneratedNotification = "UnauthUserGeneratedNotification"

class UnauthClientManager {
    
    private static let keychainName = "com.lap.zuzurentals"
    private static let userIDKey = "unauthUserId"
    private static let userTokenKey = "unauthUserToken"
    
    private let keychain = Keychain(service: UnauthClientManager.keychainName)
    
    internal typealias CompleteHandler = (userId: String?, zuzuToken: String?, success: Bool) -> Void
    
    
    private var unauthCompleteHandler: CompleteHandler?
    
    //Share Instance for interacting with the UnauthClientManager
    class var sharedInstance: UnauthClientManager {
        struct Singleton {
            static let instance = UnauthClientManager()
        }
        
        return Singleton.instance
    }
    
    internal func loginUnauthUser(handler: CompleteHandler)-> Bool {

        self.unauthCompleteHandler = handler
        
        if(self.isExistsRandomId()) {
            Log.warning("Random userId already exists in the keychain")
            return false
        }
        
        ZuzuWebService.sharedInstance.getRandomUserId({ (userId, zuzuToken, error) in
            
            if let error = error {
                Log.warning("Cannot get random userId, error = \(error)")
                self.unauthCompleteHandler?(userId: nil, zuzuToken: nil, success: false)
                return
            }
            
            if let userId = userId, zuzuToken = zuzuToken {
                
                /// Save userID to keychain
                if(self.saveUnauthUser(userId, userToken: zuzuToken)) {
                    
                    self.unauthCompleteHandler?(userId: userId, zuzuToken: zuzuToken, success: true)
                    
                    Log.debug("postNotificationName: \(UnauthUserGeneratedNotification)")
                    NSNotificationCenter.defaultCenter().postNotificationName(UnauthUserGeneratedNotification, object: self, userInfo: nil)
                } else {
                    
                    self.unauthCompleteHandler?(userId: nil, zuzuToken: nil, success: false)
                    
                }
                

                
            } else {
                assert(false, "The userID and zuzuToekn cannot be nil")
                
                self.unauthCompleteHandler?(userId: nil, zuzuToken: nil, success: false)
            }
            
        })
        
        return true
    }
    
    internal func saveUnauthUser(userID: String, userToken: String) -> Bool {
        
        do {
            try keychain.set(userID, key: UnauthClientManager.userIDKey)
            
            Log.debug("Write userID to keychain =  \(userID)")
            
            try keychain.set(userToken, key: UnauthClientManager.userTokenKey)
            
            Log.debug("Write userToken to keychain =  \(userToken)")
            
            return true
            
        } catch let error {
            Log.error("Cannot write userID or userToken to keychain error =  \(error)")
            
            return false
        }
        
    }
    
    internal func isExistsRandomId() -> Bool {
        if let _ = getUnauthUserID() {
            return true
        } else {
            return false
        }
    }
    
    internal func getUnauthUserID() -> String? {

        do {
            if let userId = try keychain.get(UnauthClientManager.userIDKey) {
                return userId
            } else {
                return nil
            }
        } catch let error {
            Log.error("Cannot get userID from keychain error =  \(error)")
            return nil
        }
        
    }
    
    internal func getUnauthUserToken() -> String? {

        do {
            if let userToken = try keychain.get(UnauthClientManager.userTokenKey) {
                return userToken
            } else {
                return nil
            }
        } catch let error {
            Log.error("Cannot get userToken from keychain error =  \(error)")
            return nil
        }
        
    }
    
}