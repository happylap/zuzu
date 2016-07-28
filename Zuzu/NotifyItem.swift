//
//  NotifyItemVO.swift
//  Zuzu
//
//  Created by eechih on 2/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON
import ObjectMapper

class NotifyItem: NSObject, Mappable {

    var id: String!
    var title: String!
    var addr: String!
    var purposeType: Int32!
    var houseType: Int32!
    var price: Int32!
    var size: Float!
    var firstImgUrl: String?
    var postTime: NSDate?
    var isRead: Bool!

    override init() {
        super.init()
    }

    required init?(_ map: Map) {

    }

    func mapping(map: Map) {
        id          <-  map["item_id"]
        title       <-  map["title"]
        addr        <-  map["addr"]
        houseType   <- (map["house_type"], TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        purposeType <- (map["purpose_type"], TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        price       <- (map["price"], TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        size        <-  map["size"]
        firstImgUrl <-  map["first_img_url"]
        postTime    <- (map["post_time"], UTCDateTransform)
        isRead      <-  map["_read"]

//        "notify_time" : "2016-01-27T18:55:16Z",
//        "criteria_id" : "1453647277020",
//        "user_id" : "test",
    }

    //
    let UTCDateTransform = TransformOf<NSDate, String>(fromJSON: { (values: String?) -> NSDate? in
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
