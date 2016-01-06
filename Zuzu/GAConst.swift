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
        static let Activity = "activity"
        
        ///MyCollection event
        static let MyCollection = "myCollection"
        
        ///SearchHouse event
        static let SearchHouse = "searchHouse"
        
        ///Filter event
        static let SmartFilter = "smartFilter"
        
        static let Filter = "filter"
        
        ///Sorting event
        static let Sorting = "sorting"
        
        ///Blocking event
        static let Blocking = "blocking"
        
        ///Error event
        static let Error = "error"
    }
    
    
    struct Action {
        
        struct Activity {
            
            static let History = "history"
            
            static let Contact = "contact"
            
            static let ViewSource = "viewSource"
            
            static let FanPage = "fanPage"
            
            static let ShareItemPrice = "shareItemPrice"
            
            static let ShareItemSize = "shareItemSize"
            
            static let ShareItemType = "shareItemType"
            
            static let ViewItemPrice = "viewItemPrice"
            
            static let ViewItemSize = "viewItemSize"
            
            static let ViewItemType = "viewItemType"
            
            static let ResetCriteria = "resetCriteria"
            
            static let ResetFilters = "resetFilters"
        }
        
        struct MyCollection {
            
            static let Login = "login"
            
            static let ViewItemPrice = "viewItemPrice"
            
            static let ViewItemSize = "viewItemSize"
            
            static let ViewItemType = "viewItemType"
            
            static let AddItemPrice = "addItemPrice"
            
            static let AddItemSize = "addItemSize"
            
            static let AddItemType = "addItemType"
            
            static let Delete = "delete"
        }
        
        struct SearchHouse {
            
            static let Keyword = "keyword"
            
            static let Region = "region"
            
            static let Type = "type"
            
            static let PriceMax = "priceMax"
            
            static let PriceMin = "priceMin"
            
            static let SizeMax = "sizeMax"
            
            static let SizeMin = "sizeMin"
            
            static let SearchResult = "SearchResult"
        }

        
        struct Blocking {
            
            static let NoSearchResult = "noSearchResult"
            
            static let LoginError = "loginError"
            
            static let LoginCancel = "loginCancel"
            
        }
        
        struct Error {
            
            static let SearchHouse = "searchHouse"
            
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
    }
    
}