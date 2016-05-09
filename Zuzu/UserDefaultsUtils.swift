//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct UserDefaultsUtils {
    
    // MARK: Walkthrough Pages
    static let onboardingPagesUserDefaultKey = "displayOnboardingPages"
    
    static func setDisplayOnboardingPages() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(true, forKey: onboardingPagesUserDefaultKey)
    }
    
    static func needsDisplayOnboardingPages() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let _ = userDefaults.objectForKey(onboardingPagesUserDefaultKey) {
            return false
        } else {
            return true
        }
    }
    
    // MARK: Radar
    static let radarLandingPageDisplayedUserDefaultKey = "radarLandingPageDisplayed"
    
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
    static let googleTokenDefaultKey = "googleToken"
    static let googleTokenExpiryDefaultKey = "googleTokenExpiry"
    static let userProfileUserDefaultKey = "loginUserData"
    static let loginUserUserDefaultKey = "loginUser"
    static let loginProviderUserDefaultKey = "loginProvider"
    static let userLastCognitoIdentityUserDefaultKey = "userLastCognitoIdentityUserDefaultKey"
    
    // Google Token
    static func clearGoogleToken() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(googleTokenDefaultKey)
        userDefaults.removeObjectForKey(googleTokenExpiryDefaultKey)
        userDefaults.synchronize()
    }
    
    static func setGoogleToken(token: String, expiry: NSDate) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(token, forKey: googleTokenDefaultKey)
        userDefaults.setObject(expiry, forKey: googleTokenExpiryDefaultKey)
        userDefaults.synchronize()
    }
    
    static func getGoogleToken() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(googleTokenDefaultKey) as? String
    }
    
    static func getGoogleTokenExpiry() -> NSDate? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(googleTokenExpiryDefaultKey) as? NSDate
    }
    
    // Login Provider
    static func clearLoginProvider() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(loginProviderUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func setLoginProvider(provider: Provider) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(provider.rawValue, forKey: loginProviderUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func getLoginProvider() -> Provider? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let providerStr = userDefaults.objectForKey(loginProviderUserDefaultKey) as? String {
            return Provider(rawValue: providerStr)
        }else {
            return nil
        }
    }
    
    // User Profile
    static func clearUserProfile() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(userProfileUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func setUserProfile(userProfile: ZuzuUser) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let data = NSKeyedArchiver.archivedDataWithRootObject(userProfile)
        userDefaults.setObject(data, forKey: userProfileUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func getUserProfile() -> ZuzuUser?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let data = userDefaults.objectForKey(userProfileUserDefaultKey) as? NSData
        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? ZuzuUser
    }
    
    // Logged in User Id
    static func clearLoginUser() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(loginUserUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func setLoginUser(userId: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(userId, forKey: loginUserUserDefaultKey)
        userDefaults.synchronize()
    }
    
    static func getLoginUser() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        return userDefaults.objectForKey(loginUserUserDefaultKey) as? String
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
        /// Make sure the data is saved immediately
        userDefaults.synchronize()
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
    
    // MARK: Backward compatibility
    static func upgradeToLatest() -> Void {
        
        /// Removed in 1.1
        if let userProfile = UserDefaultsUtils.getUserProfile(), userId = userProfile.id  {
            
            UserDefaultsUtils.setLoginUser(userId)
            UserDefaultsUtils.clearUserProfile()
            
        }
        
    }
}
