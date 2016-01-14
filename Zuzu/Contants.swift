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
    
    // MARK: My Collection
    static let MYCOLLECTION_MAX_SIZE = 60
    
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