//
//  UserManager.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/5/3.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

enum UserType: Int {
    case Authenticated
    case Unauthenticated
}

struct UserInfo {
    var userType: UserType
    var userId: String
    var provider: Provider?
    var userToken: String
}

class UserManager {
    
    internal static func getCurrentUser() -> UserInfo? {
        
        if(AmazonClientManager.sharedInstance.isLoggedIn()) {
            
            if let userID = AmazonClientManager.sharedInstance.currentUserToken?.userId,
                userToken = AmazonClientManager.sharedInstance.currentUserToken?.token {
                
                Log.debug("Authenticated userID = \(userID)")
                
                let accountProvider = UserDefaultsUtils.getLoginProvider()
                
                return UserInfo(userType: .Authenticated, userId: userID, provider: accountProvider, userToken: userToken)
                
            } else {
                assert(false, "userID and userToken cannot be nil after logging in")
            }
            
        }
        
        if let userID = UnauthClientManager.sharedInstance.getUnauthUserID(),
            userToken =  UnauthClientManager.sharedInstance.getUnauthUserToken() {
            
            Log.debug("Unauthenticated userID = \(userID)")
            return UserInfo(userType: .Unauthenticated, userId: userID, provider: nil, userToken: userToken)
            
        }
        
        
        return nil
    }
    
    
}
