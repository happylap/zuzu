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
    
    private static let keychainName = "com.zuzu.unauthuser"
    private static let userIDKey = "userId"
    private static let userTokenKey = "userToken"
    private static let keychain = Keychain(service: keychainName)
    
    static func saveUnauthUser(userID: String, userToken: String) -> Void {
        
        do {
            try keychain
                .accessibility(.WhenUnlocked)
                .set(userID, key: userIDKey)
            
            try keychain
                .accessibility(.WhenUnlocked)
                .set(userToken, key: userTokenKey)
        } catch let error {
            Log.error("Cannot write userID to keychain error =  \(error)")
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