//
//  UserInfo.swift
//  Zuzu
//
//  Created by eechih on 12/30/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper


class UserProfile: NSObject, Mappable {
    
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