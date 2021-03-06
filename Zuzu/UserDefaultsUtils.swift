//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct UserDefaultsUtils {

    // MARK: App Version
    static let currentAppVersionUserDefaultKey = "appVersion"

    static let previousAppVersionUserDefaultKey = "previousAppVersion"

    /// Record App version change for upgrade
    static func persistAppVersion() {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as? String {

            if let current = userDefaults.objectForKey(currentAppVersionUserDefaultKey) as? String {

                /// Version changes.
                if(current != version) {
                    /// Move current to previous
                    userDefaults.setObject(current, forKey: previousAppVersionUserDefaultKey)

                    /// Save current App version
                    userDefaults.setObject(version, forKey: currentAppVersionUserDefaultKey)

                    userDefaults.synchronize()
                }

            } else {

                /// Save current App version
                userDefaults.setObject(version, forKey: currentAppVersionUserDefaultKey)

                userDefaults.synchronize()
            }

        } else {
            assert(false, "Version number cannot be nil")
        }

    }

    static func getPreviousVersion() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(previousAppVersionUserDefaultKey) as? String
    }

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

    // MARK: Experiments
    static let rentDiscountExperimentNextDisplayUserDefaultKey = "rentDiscountExperimentNextDisplay"
    static let rentDiscountExperimentDelayFactorUserDefaultKey = "rentDiscountExperimentDelayFactor"

    static func setNextRentDiscountDisplayDate(expiry: NSDate) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(expiry, forKey: rentDiscountExperimentNextDisplayUserDefaultKey)
        userDefaults.synchronize()
    }

    static func getNextRentDiscountDisplayDate() -> NSDate? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(rentDiscountExperimentNextDisplayUserDefaultKey) as? NSDate
    }

    static func setRentDiscountDisplayDelayFactor(days: Int) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(days, forKey: rentDiscountExperimentDelayFactorUserDefaultKey)
    }

    static func getRentDiscountDisplayDelayFactor() -> Int? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(rentDiscountExperimentDelayFactorUserDefaultKey) as? Int
    }

    // MARK: Radar
    static let radarSuggestionTriggerCounterUserDefaultKey = "radarSuggestionTriggerCounter"
    static let allowPromptRadarSuggestionUserDefaultKey = "allowPromptRadarSuggestion"

    // RadarSuggestionTriggerCounter
    static func incrementRadarSuggestionTriggerCounter() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let current = getRadarSuggestionTriggerCounter()

        userDefaults.setInteger(current + 1, forKey: radarSuggestionTriggerCounterUserDefaultKey)
    }

    static func resetRadarSuggestionTriggerCounter() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(radarSuggestionTriggerCounterUserDefaultKey)
    }

    static func getRadarSuggestionTriggerCounter() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let count = userDefaults.integerForKey(radarSuggestionTriggerCounterUserDefaultKey)

        return count
    }

    // SuggestRadarCounter
    static func setAllowPromptRadarSuggestion(allow: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        if(allow) {
            userDefaults.setInteger(0, forKey: allowPromptRadarSuggestionUserDefaultKey)
        } else {
            userDefaults.setInteger(1, forKey: allowPromptRadarSuggestionUserDefaultKey)
        }
    }

    static func isAllowPromptRadarSuggestion() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        let allowInt = userDefaults.integerForKey(allowPromptRadarSuggestionUserDefaultKey)

        if(allowInt == 0) {
            return true
        } else {
            return false
        }
    }

    // Radar Landing Page
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

    static let radarNewBadgeDisplayedUserDefaultKey = "radarNewBadgeDisplayed"

    static func setRadarNewBadgeDisplayed() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(true, forKey: radarNewBadgeDisplayedUserDefaultKey)
    }

    static func needsDisplayRadarNewBadge() -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let _ = userDefaults.objectForKey(radarNewBadgeDisplayedUserDefaultKey) {
            return false
        } else {
            return true
        }
    }

    static let radarExpiryDateUserDefaultKey = "radarExpiryDate"

    static func setRadarExpiryDate(expiry: NSDate) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(expiry, forKey: radarExpiryDateUserDefaultKey)
        userDefaults.synchronize()
    }

    static func getRadarExpiryDate() -> NSDate? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.objectForKey(radarExpiryDateUserDefaultKey) as? NSDate
    }

    static func removeRadarExpiryDate() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(radarExpiryDateUserDefaultKey)
        userDefaults.synchronize()
    }

    // Free Trial (Need to be cleared when switching users)
    static func setUsedFreeTrial(productIdentifier: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setInteger(1, forKey: productIdentifier)
    }

    static func hasUsedFreeTrial(productIdentifier: String) -> Bool {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let status = userDefaults.integerForKey(productIdentifier)

        return (status >= 1)
    }

    static func clearUsedFreeTrial(productIdentifier: String) {
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
        } else {
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

    static func getUserProfile() -> ZuzuUser? {
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

    static func getLoginUser() -> String? {
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

    static func getAPNDevicetoken() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(deviceTokenUserDefaultKey)
    }

    static func setSNSEndpointArn(endpointArn: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(endpointArn, forKey: snsEndpointUserDefaultKey)
    }

    static func getSNSEndpointArn() -> String? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        return userDefaults.stringForKey(snsEndpointUserDefaultKey)
    }

    // MARK: Backward compatibility
    static func upgradeToLatest() -> Void {

        /// Removed in 1.1
        if let userProfile = UserDefaultsUtils.getUserProfile(), userId = userProfile.id {

            UserDefaultsUtils.setLoginUser(userId)
            UserDefaultsUtils.clearUserProfile()

        }

    }
}
