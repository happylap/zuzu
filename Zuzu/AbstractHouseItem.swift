//
//  AbstractHouseItem.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

@objc(AbstractHouseItem)
class AbstractHouseItem: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    
    func fromJSON(obj: AnyObject)
    {
        let houseItem = self
        var data = JSON(obj)
        
        //print(data)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"//this your string date format
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        
        /* Mandatory Fields */
        let id = data["id"].stringValue
        let link = data["link"].stringValue
        let mobileLink = data["mobile_link"].stringValue
        let title = data["title"].stringValue
        let addr = data["addr"].stringValue
        let city = data["city"].int32Value
        let purposeType = data["purpose_type"].int32Value
        let houseType = data["house_type"].int32Value
        let price = data["price"].int32Value
        let region = data["region"].int32Value
        let size = data["size"].int32Value
        let source = data["source"].int32Value
        
        /* Optional Fields */
        let community = data["community"].stringValue
        let totalFloor = data["total_floor"].int32Value
        let floor = data["floor"].arrayObject as? [Int] ?? [Int]()
        let numBedroom = data["num_bedroom"].int32Value
        let numTing = data["num_ting"].int32Value
        let numPatio = data["num_patio"].int32Value
        let orientation = data["orientation"].int32Value
        let wallMtl = data["wall_mtl"].stringValue
        let parkingLot = data["parking_lot"].boolValue
        let parkingType = data["parkingType"].int32Value
        let readyDate: NSDate? = dateFormatter.dateFromString(data["ready_date"].stringValue)
        let shortestLease = data["shortest_lease"].int32Value
        
        /* Money Related */
        let priceIncl = data["price_incl"].arrayObject as? [Int] ?? [Int]()
        let otherExpense = data["other_expense"].arrayObject as? [Int] ?? [Int]()
        let mgmtFee = data["mgmt_fee"].int32Value
        let hasMgmtFee = data["has_mgmt_fee"].boolValue
        let deposit = data["deposit"].stringValue
        
        /* Limitations */
        let allowPet = data["allow_pet"].boolValue
        let allowCooking = data["allow_cooking"].boolValue
        let restrProfile = data["restr_profile"].stringValue
        let restrSex = data["restr_sex"].int32Value
        
        /* Extra Benefits */
        let furniture = data["furniture"].arrayObject as? [Int] ?? [Int]()
        let facility = data["facility"].arrayObject as? [Int] ?? [Int]()
        let surrounding = data["surrounding"].arrayObject as? [Int] ?? [Int]()
        let nearbyBus = data["nearby_bus"].stringValue
        let nearbyTrain = data["nearby_train"].stringValue
        let nearbyMrt = data["nearby_mrt"].stringValue
        let nearbyThsr = data["nearby_thsr"].stringValue
        
        /* Sales Agent Info */
        let agent = data["agent"].stringValue
        let agentType = data["agent_type"].int32Value
        let phone = data["phone"].arrayObject as? [String] ?? [String]()
        
        /* Extra Description */
        let desc = data["desc"].stringValue
        let img = data["img"].arrayObject as? [String] ?? [String]()
        let postTime: NSDate? = dateFormatter.dateFromString(data["post_time"].stringValue)
        let coordinate = data["coordinate"].stringValue
        
        
        houseItem.id = id
        houseItem.link = link
        houseItem.mobileLink = mobileLink
        houseItem.title = title
        houseItem.addr = addr
        houseItem.city = city
        houseItem.purposeType = purposeType
        houseItem.houseType = houseType
        houseItem.price = price
        
        houseItem.region = region
        houseItem.community = community
        houseItem.size = size
        houseItem.totalFloor = totalFloor
        houseItem.floor = floor
        houseItem.numBedroom = numBedroom
        houseItem.numTing = numTing
        houseItem.numPatio = numPatio
        houseItem.orientation = orientation
        houseItem.wallMtl = wallMtl
        houseItem.parkingLot = parkingLot
        houseItem.parkingType = parkingType
        houseItem.readyDate = readyDate
        houseItem.shortestLease = shortestLease
        
        houseItem.priceIncl = priceIncl
        houseItem.otherExpense = otherExpense
        houseItem.mgmtFee = mgmtFee
        houseItem.hasMgmtFee = hasMgmtFee
        houseItem.deposit = deposit
        
        houseItem.allowPet = allowPet
        houseItem.allowCooking = allowCooking
        houseItem.restrProfile = restrProfile
        houseItem.restrSex = restrSex
        
        houseItem.furniture = furniture
        houseItem.facility = facility
        //house.surrounding = surrounding
        houseItem.nearbyBus = nearbyBus
        houseItem.nearbyTrain = nearbyTrain
        houseItem.nearbyMrt = nearbyMrt
        houseItem.nearbyThsr = nearbyThsr
        
        houseItem.agent = agent
        houseItem.agentType = agentType
        houseItem.phone = phone
        
        houseItem.desc = desc
        houseItem.img = img
        houseItem.postTime = postTime
        houseItem.coordinate = coordinate
        houseItem.source = source
    }

}
