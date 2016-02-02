//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct UserDefaultsUtils{
    
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
    
    static let APN_DEVICE_TOKEN_KEY = "deviceToken"
    static let SNS_ENDPOINT_ARN = "endpointArn"
    
    static func setAPNDevicetoken(deviceToken: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(deviceToken, forKey: APN_DEVICE_TOKEN_KEY)
    }

    static func getAPNDevicetoken() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(APN_DEVICE_TOKEN_KEY)
    }
    
    static func setSNSEndpointArn(endpointArn: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(endpointArn, forKey: SNS_ENDPOINT_ARN)
    }
    
    static func getSNSEndpointArn() -> String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(SNS_ENDPOINT_ARN)
    }
}
