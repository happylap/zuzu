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
    var userToken: String
}

class UserManager {
    
    internal static func getCurrentUser() -> UserInfo? {
        
        if(AmazonClientManager.sharedInstance.isLoggedIn()) {
            
            if let userID = AmazonClientManager.sharedInstance.currentUserProfile?.id,
                userToken = AmazonClientManager.sharedInstance.currentUserToken.token {
                
                Log.debug("Authenticated userID = \(userID)")
                
                return UserInfo(userType: .Authenticated, userId: userID, userToken: userToken)
            } else {
                assert(false, "userID and userToken cannot be nil after logging in")
            }
            
        }
        
        if let userID = ZuzuUnauthUtil.getUnauthUserID(), userToken =  ZuzuUnauthUtil.getUnauthUserToken() {
            
            Log.debug("Unauthenticated userID = \(userID)")
            return UserInfo(userType: .Unauthenticated, userId: userID, userToken: userToken)
            
        }
        
        
        return nil
    }
    
    
}
