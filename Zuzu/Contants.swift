//
//  Contants.swift
//  Zuzu
//
//  Created by eechih on 1/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSCore

// MARK: General Constants
internal let PhoneExtensionChar = ","
internal let DisplayPhoneExtensionChar = "轉"

// MARK: Radar
struct RadarConstants {

    /// The threshold of number of search result that we increment the trigger counter
    static let SUGGESTION_TRIGGER_INCREMENT_THRESHOLD = 100

    /// The min trigger count for prompting Radar functionality to the user
    static let SUGGESTION_TRIGGER_COUNT = 3

}

// MARK: My Collection
struct CollectionConstants {

    static let MYCOLLECTION_MAX_SIZE = 60

}

// MARK: Constants for TagManager
struct TagConst {

    static let showADs = "showADs"

    static let checkSource = "checkSource"

    static let showVideoADs = "videoAD"

    static let zuzuLogin = "zuzuLogin"

    static let freeTrial = "freeTrial"

    static let moverDisplay = "moverDisplay"

    static let moverMsg = "moverMsg"

    static let moverUrl = "moverUrl"

    static let tenantDisplay = "tenantDisplay"

    static let tenantTitle = "tenantTitle"

    static let tenantSubtitle = "tenantSubtitle"

    static let tenantUrl = "tenantUrl"

    static let serviceAgreementDisplay = "serviceAgreementDisplay"

    static let serviceAgreementTitle = "serviceAgreementTitle"

    static let serviceAgreementSubtitle = "serviceAgreementSubtitle"

    static let serviceAgreementSubtitle2 = "serviceAgreementSubtitle2"

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
        static let SUITE_GENERAL = 13
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

    struct Source {
        static let TYPE_591 = 1
        static let TYPE_HOUSEFUN = 2
        static let TYPE_RAKUYA = 3
        static let TYPE_SYNYI = 4
    }

    struct Bound {
        static let LOWER_ANY = -1
        static let UPPER_ANY = -1
    }
}
