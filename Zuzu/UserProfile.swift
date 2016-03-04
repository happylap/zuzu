//
//  UserInfo.swift
//  Zuzu
//
//  Created by eechih on 12/30/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

enum Provider: String {
    case FB, GOOGLE
}

class UserProfile: NSObject, NSCoding, Mappable {
    
    var provider: Provider?
    var id: String?
    var email: String?
    var name: String?
    var gender: String?
    var birthday: String?
    var pictureUrl: String?
    
    init(provider: Provider) {
        self.provider = provider
    }
    
    required init?(_ map: Map) {
        
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        if let provider = Provider(rawValue: decoder.decodeObjectForKey("provider") as? String ?? "") {
            
            let id = decoder.decodeObjectForKey("id") as? String
            let email = decoder.decodeObjectForKey("email") as? String
            let name = decoder.decodeObjectForKey("name") as? String
            let gender = decoder.decodeObjectForKey("gender") as? String
            let birthday = decoder.decodeObjectForKey("birthday") as? String
            let pictureUrl = decoder.decodeObjectForKey("pictureUrl") as? String
            
            self.init(provider: provider)
            self.id = id
            self.email = email
            self.name = name
            self.gender = gender
            self.birthday = birthday
            self.pictureUrl = pictureUrl
            
        } else {
            
            return nil
            
        }
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(provider?.rawValue, forKey: "provider")
        aCoder.encodeObject(id, forKey:"id")
        aCoder.encodeObject(email, forKey:"email")
        aCoder.encodeObject(name, forKey:"name")
        aCoder.encodeObject(gender, forKey:"gender")
        aCoder.encodeObject(birthday, forKey:"birthday")
        aCoder.encodeObject(pictureUrl, forKey:"pictureUrl")
    }
    
    // Mappable
    func mapping(map: Map) {
        provider          <- map["provider"]
        id          <- map["id"]
        email       <- map["email"]
        name   <- map["name"]
        gender      <- map["gender"]
        birthday    <- (map["birthday"])
        pictureUrl    <- (map["pictureUrl"])
    }
    
    override var description: String {
        let string = "UserData: id = \(id)\n email = \(email)\n name = \(name)\n gender = \(gender)\n birthday = \(birthday)\n pictureUrl = \(pictureUrl)"
        return string
    }
}