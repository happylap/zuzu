//
//  ZuzuUserMapper.swift
//  Zuzu
//
//  Created by Harry Yeh on 4/7/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

class ZuzuUserMapper: NSObject, Mappable {
    var userId: String?
    var registerTime: NSDate?
    var email: String?
    var name: String?
    var gender: String?
    var birthday: NSDate?
    var pictureUrl: String?
    var provider: String?
    var password: String?
    
    override init() {
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        userId              <- map["user_id"]
        registerTime        <- (map["register_time"], timeTransform)
        email               <- map["email"]
        name                <- map["name"]
        gender              <- map["gender"]
        birthday            <- (map["birthday"], timeTransform)
        pictureUrl          <- map["picture_url"]
        provider            <- map["provider"]
        password            <- map["password"]
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
    
    func toUser() -> ZuzuUser? {
        if let userId = self.userId, email = self.email {
            let user = ZuzuUser()
            user.id = userId
            user.email = email
            
            if let _provider = self.provider {
                if let provider = Provider(rawValue: _provider) {
                    user.provider = provider
                }
            }
            
            user.registerTime = self.registerTime
            user.name = self.name
            user.gender = self.gender
            user.birthday = self.birthday
            user.pictureUrl = self.pictureUrl
            return user
        }
        return nil
    }
    
    func fromUser(user: ZuzuUser) {
        self.provider = user.provider?.rawValue
        self.userId = user.id
        self.email = user.email
        self.registerTime = user.registerTime
        self.name = user.name
        self.gender = user.gender
        self.birthday = user.birthday
        self.pictureUrl = user.pictureUrl
    }
    
}
