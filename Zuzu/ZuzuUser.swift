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
    var userId: String!
    var registerTime: NSDate?
    
    var facebookEmail: String?
    var facebookId: String?
    var facebookName: String?
    var facebookFirstName: String?
    var facebookLastName: String?
    var facebookGender: String?
    
    override init() {
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        userId              <- map["user_id"]
        registerTime        <- (map["register_time"], DateTransform())
        facebookEmail       <- map["facebook_email"]
        facebookId          <- map["facebook_id"]
        facebookName        <- map["facebook_name"]
        facebookFirstName   <- map["facebook_first_name"]
        facebookLastName    <- map["facebook_last_name"]
        facebookGender      <- map["facebook_gender"]
    }
}
