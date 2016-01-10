//
//  UserInfo.swift
//  Zuzu
//
//  Created by eechih on 12/30/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

class FBUserData: NSObject, Mappable {
    
    var facebookId: String?
    var facebookName: String?
    var facebookEmail: String?
    var facebookPictureUrl: String?
    var facebookFirstName: String?
    var facebookLastName: String?
    var facebookGender: String?
    var facebookBirthday: String?
    
    override init() {
        
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        facebookId          <- map["facebookId"]
        facebookName        <- map["facebookName"]
        facebookEmail       <- map["facebookEmail"]
        facebookFirstName   <- map["facebookFirstName"]
        facebookLastName    <- map["facebookLastName"]
        facebookGender      <- map["facebookGender"]
        facebookBirthday    <- (map["facebookBirthday"])
    }
}