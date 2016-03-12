//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct UserDefaultsUtils{
        
    // MARK: Radar
    static let radarLandingPageDisplayedUserDefaultKey = "radarLandingPageDisplayed"
    static let zuzuUserIdUserDefaultKey = "zuzuUserData"

    static func setRadarLandindPageDisplayed() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(true, forKey: radarLandingPageDisplayedUserDefaultKey)
    }
    
    static func needsDisplayRadarLandingPage() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let _ = userDefaults.objectForKey(radarLandingPageDisplayedUserDefaultKey) {
            return false
        } else {
            return true
        }
    }

    static func clearZuzuUserId() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(zuzuUserIdUserDefaultKey)
    }
    
    static func setZuzuUserId(userId: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userId, forKey: zuzuUserIdUserDefaultKey)
    }
    
    static func getZuzuUserId() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(zuzuUserIdUserDefaultKey)
    }
    
    // Free Trial (Need to be cleared when switching users)
    static func setUsedFreeTrial(productIdentifier: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setInteger(1, forKey: productIdentifier)
    }
    
    static func hasUsedFreeTrial(productIdentifier: String) -> Bool{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let status = userDefaults.integerForKey(productIdentifier)
        
        return (status >= 1)
    }
    
    static func clearUsedFreeTrial(productIdentifier: String){
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(productIdentifier)
    }
    
    // MARK: Login
    /// UserProfile UserDefaults persistence APIs
    static let userProfileUserDefaultKey = "loginUserData"
    static let userLastCognitoIdentityUserDefaultKey = "userLastCognitoIdentityUserDefaultKey"
    
    static func clearUserProfile() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(userProfileUserDefaultKey)
    }
    
    static func setUserProfile(userProfile: UserProfile) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(userProfile)
        userDefaults.setObject(data, forKey: userProfileUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func getUserProfile() -> UserProfile?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let data = userDefaults.objectForKey(userProfileUserDefaultKey) as? NSData
        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? UserProfile
    }
    
    /// Check if the user has ever loggin for this installation
    static func setCognitoIdentityId(identityId : String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(identityId, forKey: userLastCognitoIdentityUserDefaultKey)
    }
    
    static func getCognitoIdentityId() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(userLastCognitoIdentityUserDefaultKey) as? String
    }
    
    // MARK: My Collection
    
    static let myCollectionAlertUserDefaultKey = "myCollectionAlert"
    
    static func disableMyCollectionPrompt() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: myCollectionAlertUserDefaultKey)
    }
    
    static func needsMyCollectionPrompt() -> Bool {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return !userDefaults.boolForKey(myCollectionAlertUserDefaultKey)
    }
    
    // MARK: SNS Push Notifications
    
    static let deviceTokenUserDefaultKey = "deviceToken"
    static let snsEndpointUserDefaultKey = "endpointArn"
    
    static func setAPNDevicetoken(deviceToken: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(deviceToken, forKey: deviceTokenUserDefaultKey)
    }

    static func getAPNDevicetoken() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(deviceTokenUserDefaultKey)
    }
    
    static func setSNSEndpointArn(endpointArn: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(endpointArn, forKey: snsEndpointUserDefaultKey)
    }
    
    static func getSNSEndpointArn() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(snsEndpointUserDefaultKey)
    }
}
