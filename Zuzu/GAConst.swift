//
//  GAConst.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/30.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct GAConst {
    
    struct Catrgory {
        ///Common UI event
        static let UIActivity = "activity"
        
        ///MyCollection event
        static let MyCollection = "myCollection"
        
        ///ZuzuRadarSetting event
        static let ZuzuRadarSetting = "zuzuRadarSetting"

        ///ZuzuRadarPurchase event
        static let ZuzuRadarPurchase = "zuzuRadarPurchase"
        
        ///ZuzuRadarNotification event
        static let ZuzuRadarNotification = "zuzuRadarNotification"
        
        ///Notification setup event
        static let NotificationSetup = "notificationSetup"
        
        ///Notification setup event
        static let NotificationStatus = "notificationStatus"
        
        ///SearchHouse event
        static let SearchHouse = "searchHouse"
        
        ///Filter event
        static let SmartFilter = "smartFilter"
        
        static let Filter = "filter"
        
        ///Sorting event
        static let Sorting = "sorting"
        
        static let DisplayAD = "displayAD"
        
        ///Blocking event
        static let Blocking = "blocking"
    }
    
    
    struct Action {
        
        struct UIActivity {
            
            static let History = "history"
            
            static let Contact = "contact"
            
            static let ViewSource = "viewSource"
            
            static let FanPage = "fanPage"
            
            static let RateUs = "rateUs"
            
            static let ShareItemPrice = "shareItemPrice"
            
            static let ShareItemSize = "shareItemSize"
            
            static let ShareItemType = "shareItemType"
            
            static let ViewItemPrice = "viewItemPrice"
            
            static let ViewItemSize = "viewItemSize"
            
            static let ViewItemType = "viewItemType"
            
            static let ResetCriteria = "resetCriteria"
            
            static let ResetFilters = "resetFilters"
            
            static let CurrentLocation = "currentLocation"
            
            static let Login = "login"
            
            static let ChangeRadarStatus = "changeRadarStatus"
        }
        
        struct MyCollection {
            
            static let ViewItemPrice = "viewItemPrice"
            
            static let ViewItemSize = "viewItemSize"
            
            static let ViewItemType = "viewItemType"
            
            static let AddItemPrice = "addItemPrice"
            
            static let AddItemSize = "addItemSize"
            
            static let AddItemType = "addItemType"
            
            static let Delete = "delete"
        }
        
        struct ZuzuRadarSetting {
            
            static let Region = "region"
            
            static let Type = "type"
            
            static let PriceMax = "priceMax"
            
            static let PriceMin = "priceMin"
            
            static let SizeMax = "sizeMax"
            
            static let SizeMin = "sizeMin"
            
            static let UpdateCriteriaSuccess = "updateCriteriaSuccess"
            
            static let UpdateCriteriaError = "updateCriteriaError"
        }
        
        struct ZuzuRadarPurchase {
            
            static let TryPurchase = "tryPurchase"
            
            static let MakePaymentSuccess = "makePaymentSuccess"
            
            static let MakePaymentFailure = "makePaymentFailure"
            
            static let SaveTransactionSuccess = "saveTransactionSuccess"
            
            static let SaveTransactionFailure = "saveTransactionFailure"
            
            static let ResumeTransactionSuccess = "resumeTransactionSuccess"
            
            static let ResumeTransactionFailure = "resumeTransactionFailure"
            
            static let SaveCriteriaSuccess = "saveCriteriaSuccess"
            
            static let SaveCriteriaError = "saveCriteriaError"
        }
        
        struct ZuzuRadarNotification {
            
            static let ReceiveNotification = "receiveNotification"
            
            static let ReadNotificationPrice = "readNotificationPrice"
            
            static let ReadNotificationSize = "readNotificationSize"
            
            static let ReadNotificationType = "readNotificationType"
        }
        
        struct NotificationSetup {

            static let DeviceTokenChangeSuccess = "deviceTokenChangeSuccess"
            
            static let DeviceTokenChangeFailure = "deviceTokenChangeFailure"
            
            static let CreateDeviceFailure = "createDeviceFailure"
            
            static let RegisterSNSNoCredential = "registerSNSNoCredential"
            
            static let RegisterSNSNoService = "registerSNSNoService"
            
            static let RegisterSNSNoUserId = "registerSNSNoUserId"
            
            static let RegisterSNSNoDeviceToken = "registerSNSNoDeviceToken"
            
            static let RegisterSNSFailure = "registerSNSFailure"
            
        }
        
        struct NotificationStatus {
            
            static let LocalNotificationDisabled = "localNotificationDisabled"
            
            static let PushNotificationNotRegistered = "pushNotificationNotRegistered"
            
            static let PushNotificationRegisteredNoSavedToken = "pushNotificationRegisteredNoSavedToken"
            
        }
        
        struct SearchHouse {
            
            static let Keyword = "keyword"
            
            static let Region = "region"
            
            static let Type = "type"
            
            static let PriceMax = "priceMax"
            
            static let PriceMin = "priceMin"
            
            static let SizeMax = "sizeMax"
            
            static let SizeMin = "sizeMin"
            
            static let SearchResult = "searchResult"
            
            static let FilteredResult = "filteredResult"
            
            static let LoadPage = "loadPage"
            
            static let DuplicateItemContinue = "duplicateItemContinue"
            
            static let DuplicateItemView = "duplicateItemView"
        }
        
        struct DisplayAD {
            
            static let Impression = "impression"
            
            static let Click = "click"
            
            static let Error = "error"
        }

        
        struct Blocking {
            
            static let NetworkError = "NetworkError" // Label = API name + error message
            
            static let NoSearchResult = "noSearchResult"
            
            static let LoginError = "loginError"
            
            static let LoginCancel = "loginCancel"
            
            static let loginReject = "loginReject"
            
            static let loginSkip = "loginSkip"
            
        }
    }
    
    struct Label {
        
        struct History {
            static let Load = "load"
            static let Save = "save"
        }
        
        struct Contact {
            static let Phone = "phone"
            static let Email = "email"
        }
        
        struct SearchResult {
            static let Number = "number"
        }
        
        struct LoginType {
            static let Facebook = "facebook"
            static let Google = "google"
        }
        
        struct DisplayAD {
            static let Vmfive = "vm5"
        }
    }
    
}