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
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS_SANDBOX/zuzurentals_development"
    }
    
    // MARK: SNS Push Notifications
    func start(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUserLogin:", name: UserLoginNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDeviceTokenChange:", name: "deviceTokenChange", object: nil)
    }
    
    func handleUserLogin(notification: NSNotification) {
        Log.enter()
        print("\(notification.userInfo)")
        if let userData = notification.userInfo?["userData"] as? UserData{
            if let userId = userData.id{
                if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
                    let endpointArn = UserDefaultsUtils.getSNSEndpointArn()
                    self.registerSNSEndpoint(userId, deviceTokenString:deviceTokenString, endpointArn: endpointArn)
                }else{
                    Log.warning("deviceTokenString is nil")
                }
            }else{
                Log.error("userId is nil")
            }
        }
        else{
            Log.error("userData is nil")
        }
        Log.exit()
    }
 
    func handleDeviceTokenChange(notification: NSNotification) {
        Log.enter()
        if let userLoginData = AmazonClientManager.sharedInstance.userLoginData{
            if let userId = userLoginData.id{
                if let deviceTokenString = notification.userInfo?["deviceTokenString"] as? String{
                    let endpointArn = UserDefaultsUtils.getSNSEndpointArn()
                    self.registerSNSEndpoint(userId, deviceTokenString:deviceTokenString, endpointArn: endpointArn)
                }else{
                    Log.error("deviceTokenString is nil")
                }
                
            }
            else{
                Log.error("userId is nil")
            }
        }
        else{
            Log.warning("userLoginData is nil")
        }
        
        Log.exit()
    }
    
    func registerSNSEndpoint(userId: String, deviceTokenString:String, endpointArn:String?){
        Log.enter()
        if endpointArn != nil{
            let sns = AWSSNS.defaultSNS()
            let request = AWSSNSGetEndpointAttributesInput()
            request.endpointArn = endpointArn
            sns.getEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    Log.debug("Error: \(task.error)")
                    if task.error!.code == AWSSNSErrorType.NotFound.rawValue{
                        self.createEndpoint(deviceTokenString, userData:userId)
                    }
                } else {
                    let getEndpointResponse = task.result as! AWSSNSGetEndpointAttributesResponse
                    Log.debug("token: \(getEndpointResponse.attributes!["Token"])")
                    Log.debug("Enabled: \(getEndpointResponse.attributes!["Enabled"])")
                    Log.debug("CustomUserData: \(getEndpointResponse.attributes!["CustomUserData"])")
                    var isUpdate = false
                    if let lastToken = getEndpointResponse.attributes!["Token"] as? String{
                        if deviceTokenString != lastToken{
                            isUpdate = true
                        }
                    }
                    
                    if let enabled = getEndpointResponse.attributes!["Enabled"] as? Bool{
                        if enabled == false{
                            isUpdate = true
                        }
                    }
                    
                    var customUserData = getEndpointResponse.attributes!["CustomUserData"] as? String
                    if customUserData == nil{
                        customUserData = userId
                        isUpdate = true
                    }
                    
                    if isUpdate == true{
                        self.updateEndpoint(deviceTokenString, endpointArn:endpointArn!, userData: userId)
                    }
                }
                
                return nil
            })
        }else{
            self.createEndpoint(deviceTokenString, userData: userId)
        }

        Log.exit()
    }
    
    func updateEndpoint(deviceTokenString: String, endpointArn:String, userData: String){
        Log.enter()
        let sns = AWSSNS.defaultSNS()
        let request = AWSSNSSetEndpointAttributesInput()
        Log.debug("endpointArn: \(request.endpointArn)")
        request.endpointArn = endpointArn
        request.attributes = [NSObject:AnyObject]()
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
                Log.debug("update SNS endpoint successful")
            }
            Log.exit()
            return nil
        })
    }
    
    func createEndpoint(deviceTokenString: String, userData: String?){
        Log.enter()
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