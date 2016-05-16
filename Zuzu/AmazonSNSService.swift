//
//  AmazonSNSService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/22.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSSNS

private let Log = Logger.defaultLogger

class AmazonSNSService : NSObject {
    //Share Instance for interacting with the AmazonSNSService
    class var sharedInstance: AmazonSNSService {
        struct Singleton {
            static let instance = AmazonSNSService()
        }
        
        return Singleton.instance
    }
    
    internal var needSwitchToNotificationTab = false
    
    internal var needUpdateTabBadge = false
    
    // MARK: Private Members
    private struct AmazonSNSConstants {
        #if DEBUG
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS_SANDBOX/zuzurentals_development"
        #else
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS/zuzurentals"
        #endif
    }
    
    private struct AWSConstants {
        static let DEFAULT_SERVICE_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_IDENTITY_POOL_ID = "ap-northeast-1:8fb21ade-1c74-41e7-9824-4a254af78b3a"
    }
    
    private var snsService:AWSSNS?
    
    /// MARK: Private Utils
    private func logReceiveNotification(){
        Log.enter()
        if let userId = UserManager.getCurrentUser()?.userId {
            if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
                
                
                ZuzuWebService.sharedInstance.setReceiveNotifyTimeByUserId(userId, deviceId: deviceTokenString){
                    (result, error) -> Void in
                    
                    if error != nil{
                        Log.error("setReceiveNotifyTimeByUserId fails")
                        return
                    }
                    
                    Log.info("setReceiveNotifyTimeByUserId successfully")
                }
            }
        }
        
        Log.exit()
    }
    
    private func isMainTabReady()-> Bool {
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController,
            _ = tabViewController.viewControllers {

            Log.debug("isMainTabReady = true")
            return true
            
        } else {
            
            Log.debug("isMainTabReady = false")
            return false
        }
        
    }
    
    private func isNotificationTabSelected()-> Bool {
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController {
            
            return tabViewController.selectedIndex == MainTabConstants.NOTIFICATION_TAB_INDEX
            
        } else {
            return false
        }
        
    }
    
    override init() {
        super.init()
        
        // Initialize the Amazon Cognito credentials provider
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:AWSConstants.DEFAULT_SERVICE_REGIONTYPE,
                                                                identityPoolId:AWSConstants.COGNITO_IDENTITY_POOL_ID)
        let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider:credentialsProvider)
        
        AWSSNS.registerSNSWithConfiguration(configuration, forKey: "ZUZUSNS")
        
        self.snsService = AWSSNS(forKey: "ZUZUSNS")
    }
    
    // MARK: Public APIs
    internal func start(){
        Log.enter()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AmazonSNSService.handleUserIDCreated(_:)), name: UserLoginNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AmazonSNSService.handleUserIDCreated(_:)), name: UnauthUserGeneratedNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AmazonSNSService.handleDeviceTokenChange(_:)), name: DeviceTokenChangeNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AmazonSNSService.handleReceiveNotifyItems(_:)), name: RadarItemReceiveNotification, object: nil)
        
        Log.exit()
    }
    
    /// Save device token in Zuzu backend
    internal func createDeviceForUser(userId: String, deviceToken: String) {
        ZuzuWebService.sharedInstance.createDeviceByUserId(userId, deviceId: deviceToken){
            (result, error) -> Void in
            
            if error != nil{
                
                GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                                   action: GAConst.Action.NotificationSetup.CreateDeviceFailure, label: userId)
                
                Log.error("Fail to register deviceToken: \(deviceToken) for user: \(userId)")
            }
            
        }
    }
    
    // MARK: Notifications Handlers
    func handleUserIDCreated(notification: NSNotification) {
        Log.enter()
        Log.debug("\(notification.userInfo)")
        
        if let userId = UserManager.getCurrentUser()?.userId {
            if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
                let endpointArn = UserDefaultsUtils.getSNSEndpointArn()
                
                self.registerSNSEndpoint(userId, deviceTokenString:deviceTokenString, endpointArn: endpointArn)
                self.createDeviceForUser(userId, deviceToken: deviceTokenString)
            }else{
                
                GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                                   action: GAConst.Action.NotificationSetup.RegisterSNSNoDeviceToken, label: userId)
                
                Log.debug("deviceTokenString is nil")
            }
        }else{
            
            GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                               action: GAConst.Action.NotificationSetup.RegisterSNSNoUserId)
            Log.error("userId is nil")
        }
        
        Log.exit()
    }
    
    func handleDeviceTokenChange(notification: NSNotification) {
        Log.enter()
        Log.debug("\(notification.userInfo)")
        
        if let deviceTokenString = notification.userInfo?["deviceTokenString"] as? String {
            
            if let userId = UserManager.getCurrentUser()?.userId {
                let endpointArn = UserDefaultsUtils.getSNSEndpointArn()
                
                self.registerSNSEndpoint(userId, deviceTokenString:deviceTokenString, endpointArn: endpointArn)
                self.createDeviceForUser(userId, deviceToken: deviceTokenString)
            }else{
                Log.debug("userId is nil")
            }
            
        }else{
            Log.error("deviceTokenString is nil")
        }
        Log.exit()
    }
    
    /// Centrally handle remote notifications for Zuzu Radar
    func handleReceiveNotifyItems(notification: NSNotification) {
        Log.enter()
        Log.debug("\(notification.userInfo)")
        
        if let info = notification.userInfo,
            appStateRaw = info["appState"] as? Int, switchTab = info["switchTab"] as? Bool,
            appState = AppStateOnNotification(rawValue: appStateRaw) {
            
            Log.debug("appState = \(appState)")
            
            /// Check if there is any current user (auth or unauth)
            if(UserManager.getCurrentUser() == nil) {
                
                Log.debug("Cannot handle the notification. The user is not logged in.")
                
                Log.exit()
                return
            }
            
            /// Check is notification tab selected
            let notificationTab = isNotificationTabSelected()
            
            /// Log notification
            self.logReceiveNotification()
            
            switch(appState) {
            case .Terminated:
                
                if(notificationTab) {
                    
                    // Refresh data on notification view
                    NSNotificationCenter.defaultCenter().postNotificationName("receiveNotifyItemsOnNotifyTab", object: self)
                    
                } else {
                    
                    // Update Badge no matter we'll switch to notification view or not
                    // Reason: Tab switching is delayed until the user session is resumed.
                    // It's better that we display tab badge first during the delay
                    
                    if(isMainTabReady()) {
                        AppDelegate.updateTabBarBadge()
                    } else {
                        self.needUpdateTabBadge = true
                    }
                    
                }
                
                break
            case .Background, .Foreground:
                
                if(notificationTab) {
                    
                    // Refresh data on notification view
                    NSNotificationCenter.defaultCenter().postNotificationName("receiveNotifyItemsOnNotifyTab", object: self)
                    
                } else {
                    
                    if(isMainTabReady()) {
                        AppDelegate.updateTabBarBadge()
                    } else {
                        self.needUpdateTabBadge = true
                    }
                    
                }
                
                break
            }
            
            
            /// Whether to switch to notification tab
            if(switchTab) {
                if(isMainTabReady()) {
                    AppDelegate.switchToNotificationTab()
                } else {
                    self.needSwitchToNotificationTab = switchTab
                }
            }
            
            
        } else {
            assert(false, "The user info for this notification is mandatory")
        }
        
        Log.exit()
    }
    
    private func registerSNSEndpoint(userId: String, deviceTokenString:String, endpointArn:String?) {
        Log.enter()
        
        if (self.snsService == nil) {
            
            GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                               action: GAConst.Action.NotificationSetup.RegisterSNSNoService, label: "\(deviceTokenString),\(userId)")
            
            Log.debug("SnsService is nil, cannot register SNS")
            Log.exit()
            return
        }
        
        if let snsService = self.snsService
            where snsService.configuration.credentialsProvider == nil {
            
            GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                               action: GAConst.Action.NotificationSetup.RegisterSNSNoCredential, label: "\(deviceTokenString),\(userId)")
            
            Log.debug("Credential provider is nil, cannot register SNS")
            Log.exit()
            return
        }
        
        /// Create new endpoint
        if(endpointArn == nil) {
            let task = self.createEndpoint(deviceTokenString, userData: userId)
            
            task?.continueWithBlock({ (task) -> AnyObject? in
                if let error = task.error {
                    
                    Log.debug("createEndpoint failure, error = \(error)")
                    
                    /// Update previous endpoint, need to get the endpointArn from the error message
                    // - http://docs.aws.amazon.com/sns/latest/dg/mobile-platform-endpoint.html
                    // - https://mobile.awsblog.com/post/Tx223MJB0XKV9RU/Mobile-token-management-with-Amazon-SNS
                    if let message = error.userInfo["Message"] as? String {
                        
                        let matches = StringUtils.matchesForRegexInText(".*Endpoint (arn:aws:sns[^ ]+) already exists with the same Token.*", text: message)
                        
                        Log.debug("message = \(message) \nmatches = \(matches)")
                        
                        if let endpointArn = matches.first {
                            
                            /// Save as current endpointArn
                            UserDefaultsUtils.setSNSEndpointArn(endpointArn)
                            
                            /// Update previous endpoint
                            self.updateEndpoint(deviceTokenString, endpointArn:endpointArn, userData: userId)
                        }
                    }
                    
                }
                
                return nil
            })
            
            Log.exit()
            return
        }
        
        if let snsService = self.snsService {
            let request = AWSSNSGetEndpointAttributesInput()
            request.endpointArn = endpointArn
            
            snsService.getEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                
                /// Endpoint not exits. Create new endpoint
                if let error = task.error {
                    Log.debug("Error: \(task.error)")
                    if error == AWSSNSErrorType.NotFound.rawValue{
                        self.createEndpoint(deviceTokenString, userData:userId)
                    }
                    
                    return nil
                }
                
                // Print response attributes
                if let getEndpointResponse = task.result as? AWSSNSGetEndpointAttributesResponse {
                    Log.debug("token: \(getEndpointResponse.attributes!["Token"])")
                    Log.debug("Enabled: \(getEndpointResponse.attributes!["Enabled"])")
                    Log.debug("CustomUserData: \(getEndpointResponse.attributes!["CustomUserData"])")
                }
                
                /// Update previous endpoint
                self.updateEndpoint(deviceTokenString, endpointArn:endpointArn!, userData: userId)
                
                /*var isUpdate = false
                 if let lastToken = getEndpointResponse.attributes?["Token"]{
                 if deviceTokenString != lastToken{
                 isUpdate = true
                 }
                 }
                 
                 if let enabled = getEndpointResponse.attributes?["Enabled"]{
                 Log.debug("enabled:\(enabled)")
                 if enabled == "false"{
                 isUpdate = true
                 }
                 }
                 
                 var customUserData = getEndpointResponse.attributes?["CustomUserData"]
                 if customUserData == nil{
                 customUserData = userId
                 isUpdate = true
                 }
                 
                 if isUpdate == true{
                 self.updateEndpoint(deviceTokenString, endpointArn:endpointArn!, userData: userId)
                 }*/
                
                return nil
            })
        }
        
        Log.exit()
    }
    
    private func updateEndpoint(deviceTokenString: String, endpointArn:String, userData: String) {
        Log.enter()
        
        if let snsService = self.snsService {
            let request = AWSSNSSetEndpointAttributesInput()
            
            request.endpointArn = endpointArn
            request.attributes = [String:String]()
            request.attributes!["Token"] = deviceTokenString
            request.attributes!["Enabled"] = "true"
            request.attributes!["CustomUserData"] = userData
            
            Log.debug("request.endpointArn: \(request.endpointArn)")
            Log.debug("request.attributes: Token = \(request.attributes!["Token"])")
            Log.debug("request.attributes: Enabled = \(request.attributes!["Enabled"])")
            Log.debug("request.attributes: UserData = \(request.attributes!["CustomUserData"])")
            
            snsService.setEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    Log.debug("Error: \(task.error)")
                } else {
                    Log.debug("update result: \(task.result)")
                    Log.debug("update SNS endpoint successful")
                }
                Log.exit()
                return nil
            })
        }
    }
    
    private func createEndpoint(deviceTokenString: String, userData: String?) -> AWSTask? {
        Log.enter()
        
        if let customUserData = userData, snsService = self.snsService {
            
            let request = AWSSNSCreatePlatformEndpointInput()
            request.token = deviceTokenString
            request.customUserData = customUserData
            request.platformApplicationArn = AmazonSNSConstants.PLATFORM_APPLICATION_ARN
            
            Log.debug("request.token: \(request.token)")
            Log.debug("request.customUserData: \(request.customUserData)")
            Log.debug("request.platformApplicationArn: \(request.platformApplicationArn)")
            
            let myTask = snsService.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                
                if let error = task.error {
                    
                    GAUtils.trackEvent(GAConst.Catrgory.NotificationSetup,
                        action: GAConst.Action.NotificationSetup.RegisterSNSFailure, label: "\(deviceTokenString),\(userData)")
                    
                    Log.debug("Result = \(task.result),Error: \(error)")
                    return task
                }
                
                /// Response new endpointArn
                let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                
                Log.debug("Created endpointArn: \(createEndpointResponse.endpointArn)")
                if let endpointArn = createEndpointResponse.endpointArn {
                    UserDefaultsUtils.setSNSEndpointArn(endpointArn)
                    
                    self.updateEndpoint(deviceTokenString, endpointArn:endpointArn, userData: customUserData)
                }
                
                return task
            })
            
            Log.exit()
            return myTask
            
        } else {
            
            Log.exit()
            return nil
        }
    }
    
}