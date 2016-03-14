//
//  ZuzuServiceMapper.swift
//  Zuzu
//
//  Created by Harry Yeh on 3/8/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper
import SwiftyJSON


private let Log = Logger.defaultLogger

class ZuzuServiceMapper: NSObject, Mappable {
    
    var userId: String?
    var status: String?
    var totalSecond: Int?
    var remainingSecond: Int?
    var startTime: NSDate?
    var expireTime: NSDate?
    var validPurchaseCount: Int?
    var invalidPurchaseCount: Int?
    
    override init() {
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        userId                  <-  map["user_id"]
        status                  <-  map["status"]
        totalSecond             <-  map["total_second"]
        remainingSecond         <-  map["remaining_second"]
        startTime               <-  (map["start_time"], timeTransform)
        expireTime              <-  (map["expire_time"], timeTransform)
        validPurchaseCount      <-  map["valid_purchase_count"]
        invalidPurchaseCount    <-  map["invalid_purchase_count"]
    }
    
    //
    let timeTransform = TransformOf<NSDate, String>(fromJSON: { (values: String?) -> NSDate? in
        if let dateString = values {
            return CommonUtils.getUTCDateFromString(dateString)
        }
        return nil
    }, toJSON: { (values: NSDate?) -> String? in
        if let date = values {
            return CommonUtils.getUTCStringFromDate(date)
        }
        return nil
    })
    
}
