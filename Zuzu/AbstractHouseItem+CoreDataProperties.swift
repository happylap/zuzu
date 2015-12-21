//
//  AbstractHouseItem+CoreDataProperties.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AbstractHouseItem {

    @NSManaged var addr: String?
    @NSManaged var agent: String?
    @NSManaged var agentType: NSNumber?
    @NSManaged var allowCooking: NSNumber?
    @NSManaged var allowPet: NSNumber?
    @NSManaged var city: NSNumber?
    @NSManaged var community: String?
    @NSManaged var coordinate: String?
    @NSManaged var deposit: String?
    @NSManaged var desc: String?
    @NSManaged var facility: NSObject?
    @NSManaged var floor: NSObject?
    @NSManaged var furniture: NSObject?
    @NSManaged var hasMgmtFee: NSNumber?
    @NSManaged var id: String?
    @NSManaged var img: NSObject?
    @NSManaged var link: String?
    @NSManaged var mgmtFee: NSNumber?
    @NSManaged var mobileLink: String?
    @NSManaged var nearbyBus: String?
    @NSManaged var nearbyMrt: String?
    @NSManaged var nearbyThsr: String?
    @NSManaged var nearbyTrain: String?
    @NSManaged var numBedroom: NSNumber?
    @NSManaged var numPatio: NSNumber?
    @NSManaged var numTing: NSNumber?
    @NSManaged var orientation: NSNumber?
    @NSManaged var otherExpense: NSObject?
    @NSManaged var parkingLot: NSNumber?
    @NSManaged var parkingType: NSNumber?
    @NSManaged var phone: NSObject?
    @NSManaged var postTime: NSDate?
    @NSManaged var price: NSNumber?
    @NSManaged var priceIncl: NSObject?
    @NSManaged var readyDate: NSDate?
    @NSManaged var region: NSNumber?
    @NSManaged var restrProfile: String?
    @NSManaged var restrSex: NSNumber?
    @NSManaged var shortestLease: NSNumber?
    @NSManaged var size: NSNumber?
    @NSManaged var source: NSNumber?
    @NSManaged var surrounding: NSObject?
    @NSManaged var title: String?
    @NSManaged var totalFloor: NSNumber?
    @NSManaged var type: NSNumber?
    @NSManaged var usage: NSNumber?
    @NSManaged var wallMtl: String?

}
