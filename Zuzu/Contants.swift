//
//  Contants.swift
//  Zuzu
//
//  Created by eechih on 1/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSCore


struct Constants {
    
    // MARK: Required: Amazon Cognito Configuration
    
    static let COGNITO_REGIONTYPE = AWSRegionType.APNortheast1
    static let COGNITO_IDENTITY_POOL_ID = "ap-northeast-1:7e09fc17-5f4b-49d9-bb50-5ca5a9e34b8a"

    static let MYCOLLECTION_SYNCHRONIZE_INTERVAL_TIME = 300.0  // Unit: second
    static let MYCOLLECTION_SYNCHRONIZE_TIMEOUT_INTERVAL_TIME = 50.0  // Unit: second
    
    // MARK: Optional: Enable Facebook Login
    
    /**
    * OPTIONAL: Enable FB Login
    *
    * To enable FB Login
    * 1. Add FacebookAppID in App plist file
    * 2. Add the appropriate URL handler in project (should match FacebookAppID)
    */
    
    
    /*******************************************
     * DO NOT CHANGE THE VALUES BELOW HERE
     */
        
    static let DEVICE_TOKEN_KEY = "DeviceToken"
    static let COGNITO_DEVICE_TOKEN_KEY = "CognitoDeviceToken"
    static let COGNITO_PUSH_NOTIF = "CognitoPushNotification"
    
}