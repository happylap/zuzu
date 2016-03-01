//
//  ZuzuUser.swift
//  Zuzu
//
//  Created by eechih on 2/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

class ZuzuUser: NSObject, Mappable {
    var id: String!
    var registerTime: NSDate?
    var provider: String?
    var email: String?
    var name: String?
    var gender: String?
    var birthday: NSDate?
    var pictureUrl: String?
    
    override init() {
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        id                  <- map["user_id"]
        registerTime        <- (map["register_time"], timeTransform)
        provider            <- map["provider"]
        email               <- map["email"]
        name                <- map["name"]
        gender              <- map["gender"]
        birthday            <- (map["birthday"], timeTransform)
        pictureUrl          <- map["picture_url"]
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
