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
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: AmazonSNSService {
        struct Singleton {
            static let instance = AmazonSNSService()
        }
        
        return Singleton.instance
    }
    
    private struct AmazonSNSConstants {
        #if DEBUG
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS_SANDBOX/zuzurentals_development"
        #else
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS/zuzurentals"
        #endif
    }
    
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
    
    private func isNotificationTabSelected()-> Bool {
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController {
            
            return tabViewController.selectedIndex == MainTabConstants.NOTIFICATION_TAB_INDEX
            
        } else {
            return false
        }
        
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
                Log.debug("deviceTokenString is nil")
            }
        }else{
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
            appStateRaw = info["appState"] as? Int, appState = AppStateOnNotification(rawValue: appStateRaw),
            switchTab = info["switchTab"] as? Bool {
            
            Log.debug("appState = \(appState), switchTab = \(switchTab)")
            
            /// Check is logged in
            if(!AmazonClientManager.sharedInstance.isLoggedIn()) {
                
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
                    AppDelegate.updateTabBarBadge()
                    
                }
                
                break
            case .Background, .Foreground:
                
                if(notificationTab) {
                    
                    // Refresh data on notification view
                    NSNotificationCenter.defaultCenter().postNotificationName("receiveNotifyItemsOnNotifyTab", object: self)
                    
                } else {
                    
                    // Update Badge if not switching
                    if(!switchTab) {
                        AppDelegate.updateTabBarBadge()
                    }
                }
                
                break
            }
            
            /// Try switch to notification view if it's not selected
            if(switchTab) {
                AppDelegate.switchToNotificationTab()
            }
            
        } else {
            assert(false, "The user info for this notification is mandatory")
        }
        
        Log.exit()
    }
    
    private func registerSNSEndpoint(userId: String, deviceTokenString:String, endpointArn:String?) {
        Log.enter()
        if (!AmazonClientManager.sharedInstance.isCredentailsProviderExist()){
            Log.debug("Credebtial provider is nil, cannot register SNS")
            Log.exit()
            return
        }
        
        /// Create new endpoint
        if(endpointArn == nil) {
            self.createEndpoint(deviceTokenString, userData: userId)
            Log.exit()
            return
        }
        
        let sns = AWSSNS.defaultSNS()
        let request = AWSSNSGetEndpointAttributesInput()
        request.endpointArn = endpointArn
        sns.getEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
            
            /// Create new endpoint
            if task.error != nil {
                Log.debug("Error: \(task.error)")
                if task.error!.code == AWSSNSErrorType.NotFound.rawValue{
                    self.createEndpoint(deviceTokenString, userData:userId)
                }
                
                return nil
            }
            
            /// Update previous endpoint
            let getEndpointResponse = task.result as! AWSSNSGetEndpointAttributesResponse
            Log.debug("token: \(getEndpointResponse.attributes!["Token"])")
            Log.debug("Enabled: \(getEndpointResponse.attributes!["Enabled"])")
            Log.debug("CustomUserData: \(getEndpointResponse.attributes!["CustomUserData"])")
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
        
        Log.exit()
    }
    
    private func updateEndpoint(deviceTokenString: String, endpointArn:String, userData: String) {
        Log.enter()
        if (!AmazonClientManager.sharedInstance.isCredentailsProviderExist()){
            Log.debug("Credebtial provider is nil, cannot register SNS")
            Log.exit()
            return
        }
        
        let sns = AWSSNS.defaultSNS()
        let request = AWSSNSSetEndpointAttributesInput()
        Log.debug("endpointArn: \(request.endpointArn)")
        request.endpointArn = endpointArn
        request.attributes = [String:String]()
        request.attributes!["Token"] = deviceTokenString
        request.attributes!["Enabled"] = "true"
        request.attributes!["CustomUserData"] = userData
        
        Log.debug("endpointArn: \(request.endpointArn)")
        Log.debug("Token: \(request.attributes!["Token"])")
        Log.debug("Enabled: \(request.attributes!["Enabled"])")
        
        sns.setEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
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
    
    private func createEndpoint(deviceTokenString: String, userData: String?) {
        Log.enter()
        if (!AmazonClientManager.sharedInstance.isCredentailsProviderExist()){
            Log.debug("Credebtial provider is nil, cannot register SNS")
            Log.exit()
            return
        }
        
        if let customUserData = userData{
            let sns = AWSSNS.defaultSNS()
            let request = AWSSNSCreatePlatformEndpointInput()
            request.token = deviceTokenString
            request.customUserData = customUserData
            request.platformApplicationArn = AmazonSNSConstants.PLATFORM_APPLICATION_ARN
            sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    Log.debug("Error: \(task.error)")
                } else {
                    let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                    Log.debug("endpointArn: \(createEndpointResponse.endpointArn)")
                    if let endpointArn = createEndpointResponse.endpointArn{
                        UserDefaultsUtils.setSNSEndpointArn(endpointArn)
                    }
                }
                Log.exit()
                return nil
            })
        }
    }
    
}