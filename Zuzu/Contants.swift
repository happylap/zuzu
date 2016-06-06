//
//  Contants.swift
//  Zuzu
//
//  Created by eechih on 1/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSCore

// MARK: My Collection
struct CollectionConstants {

    static let MYCOLLECTION_MAX_SIZE = 60
    
}

// MARK: Constants for TagManager
struct TagConst {
    
    static let showADs = "showADs"
    
    static let showVideoADs = "videoAD"
    
    static let zuzuLogin = "zuzuLogin"
    
    static let freeTrial = "freeTrial"
    
}

// MARK: Constants for Criteria
struct CriteriaConst {
    
    /**
     "整層住家":0
     "獨立套房":1
     "分租套房":2
     "雅房":3
     "店面":4
     "攤位":5
     "辦公":6
     "住辦":7
     **/
    
    struct PrimaryType {
        static let FULL_FLOOR = 1
        static let SUITE_INDEPENDENT = 2
        static let SUITE_COMMON_AREA = 3
        static let ROOM_NO_TOILET = 4
        static let HOME_OFFICE = 8
    }
    
    /**
     "公寓": 1
     "電梯大樓": 2
     "透天厝": 3
     "別墅": 4
     **/
    
    struct HouseType {
        static let BUILDING_WITHOUT_ELEVATOR = 1
        static let BUILDING_WITH_ELEVATOR = 2
        static let INDEPENDENT_HOUSE = 3
        static let INDEPENDENT_HOUSE_WITH_GARDEN = 4
    }
    
    struct Bound {
        static let LOWER_ANY = -1
        static let UPPER_ANY = -1
    }
}