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
    
    // NSCoding
    required init(coder aDecoder: NSCoder) {
        userId = aDecoder.decodeObjectForKey("userId") as? String
        status = aDecoder.decodeObjectForKey("status") as? String
        startTime = aDecoder.decodeObjectForKey("startTime") as? NSDate
        expireTime = aDecoder.decodeObjectForKey("expireTime") as? NSDate
        
        if(aDecoder.containsValueForKey("totalSecond")) {
            totalSecond = aDecoder.decodeIntegerForKey("totalSecond")
        }
        if(aDecoder.containsValueForKey("remainingSecond")) {
            remainingSecond = aDecoder.decodeIntegerForKey("remainingSecond")
        }
        if(aDecoder.containsValueForKey("validPurchaseCount")) {
            validPurchaseCount = aDecoder.decodeIntegerForKey("validPurchaseCount")
        }
        if(aDecoder.containsValueForKey("invalidPurchaseCount")) {
            invalidPurchaseCount = aDecoder.decodeIntegerForKey("invalidPurchaseCount")
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.userId, forKey: "userId")
        aCoder.encodeObject(self.status, forKey: "status")
        aCoder.encodeObject(self.startTime, forKey: "startTime")
        aCoder.encodeObject(self.expireTime, forKey: "expireTime")
        
        if let totalSecond = self.totalSecond {
            aCoder.encodeInteger(totalSecond, forKey: "totalSecond")
        }
        
        if let remainingSecond = self.remainingSecond {
            aCoder.encodeInteger(remainingSecond, forKey: "remainingSecond")
        }
        
        if let validPurchaseCount = self.validPurchaseCount {
            aCoder.encodeInteger(validPurchaseCount, forKey: "validPurchaseCount")
        }
        
        if let invalidPurchaseCount = self.invalidPurchaseCount {
            aCoder.encodeInteger(invalidPurchaseCount, forKey: "invalidPurchaseCount")
        }
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
