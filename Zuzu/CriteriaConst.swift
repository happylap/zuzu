//
//  CriteriaConst.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/24.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


struct CriteriaConst {
    
    //    "整層住家":0,
    //    "獨立套房":1,
    //    "分租套房":2,
    //    "雅房":3,
    //    "店面":4,
    //    "攤位":5,
    //    "辦公":6,
    //    "住辦":7,
    
    struct PrimaryType {
        static let FULL_FLOOR = 1
        static let SUITE_INDEPENDENT = 2
        static let SUITE_COMMON_AREA = 3
        static let ROOM_NO_TOILET = 4
        static let HOME_OFFICE = 8
    }
    
    struct Bound {
        static let LOWER_ANY = -1
        static let UPPER_ANY = -2
    }
}
