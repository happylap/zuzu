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

class ZuzuUnauthUtil {
    
    private static let keychainName = "com.lap.zuzurentals"
    private static let userIDKey = "unauthUserId"
    private static let userTokenKey = "unauthUserToken"
    
    static func saveUnauthUser(userID: String, userToken: String) -> Void {
        
        let keychain = Keychain(service: keychainName)
        
        do {
            try keychain
                .set(userID, key: userIDKey)
            
            Log.debug("Write userID to keychain =  \(userID)")
            
            try keychain
                .set(userToken, key: userTokenKey)
            
            Log.debug("Write userToken to keychain =  \(userToken)")
            
        } catch let error {
            Log.error("Cannot write userID or userToken to keychain error =  \(error)")
        }
        
    }
    
    static func isRandomIdGenerated() -> Bool {
        if let _ = getUnauthUserID() {
            return true
        } else {
            return false
        }
    }
    
    static func getUnauthUserID() -> String? {
        
        let keychain = Keychain(service: keychainName)
        
        do {
            if let userId = try keychain.get(userIDKey) {
                return userId
            } else {
                return nil
            }
        } catch let error {
            Log.error("Cannot get userID from keychain error =  \(error)")
            return nil
        }
    }
    
    static func getUnauthUserToken() -> String? {
        
        let keychain = Keychain(service: keychainName)
        
        do {
            if let userToken = try keychain.get(userTokenKey) {
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