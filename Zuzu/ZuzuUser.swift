//
//  ZuzuUser.swift
//  Zuzu
//
//  Created by eechih on 2/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

enum Provider: String {
    case FB, GOOGLE
}

class ZuzuUser: NSObject, NSCoding, Mappable {
    var id: String!
    var registerTime: NSDate?
    var email: String?
    var name: String?
    var gender: String?
    var birthday: NSDate?
    var pictureUrl: String?
    
    
    override init() {
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    
    convenience required init?(coder decoder: NSCoder) {
        
            let id = decoder.decodeObjectForKey("id") as? String
            let registerTime = decoder.decodeObjectForKey("registerTime") as? NSDate
            let email = decoder.decodeObjectForKey("email") as? String
            let name = decoder.decodeObjectForKey("name") as? String
            let gender = decoder.decodeObjectForKey("gender") as? String
            let birthday = decoder.decodeObjectForKey("birthday") as? NSDate
            let pictureUrl = decoder.decodeObjectForKey("pictureUrl") as? String
            
            self.init()
            self.registerTime = registerTime
            self.id = id
            self.email = email
            self.name = name
            self.gender = gender
            self.birthday = birthday
            self.pictureUrl = pictureUrl
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey:"id")
        aCoder.encodeObject(registerTime, forKey:"registerTime")
        aCoder.encodeObject(email, forKey:"email")
        aCoder.encodeObject(name, forKey:"name")
        aCoder.encodeObject(gender, forKey:"gender")
        aCoder.encodeObject(birthday, forKey:"birthday")
        aCoder.encodeObject(pictureUrl, forKey:"pictureUrl")
    }
    
    // Mappable
    func mapping(map: Map) {
        id                  <- map["user_id"]
        registerTime        <- (map["register_time"], timeTransform)
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
