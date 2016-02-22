//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct UserDefaultsUtils{
    
    // MARK: Login Provider
    static let loginProviderUserDefaultKey = "loginProvider"
    static let loginUserDataUserDefaultKey = "loginUserData"
    
    static func clearLoginProvider() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(loginProviderUserDefaultKey)
    }
    
    static func setLoginProvider(provider: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(provider, forKey: loginProviderUserDefaultKey)
    }
    
    static func getLoginProvider() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(loginProviderUserDefaultKey) as? String
    }
    
    static func setUserLoginData(userData: UserData?) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(loginUserDataUserDefaultKey, forKey: loginUserDataUserDefaultKey)
    }
    
    static func getUserLoginData() -> UserData?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(loginUserDataUserDefaultKey) as? UserData
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
