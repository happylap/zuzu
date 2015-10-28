//
//  House.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

@objc(House)
public class House: NSManagedObject {
    
    /* Mandatory Fields */
    @NSManaged var id: String
    @NSManaged var link: String         //
    @NSManaged var mobileLink: String
    @NSManaged var title: String
    @NSManaged var addr: String
    @NSManaged var city: Int
    @NSManaged var purposeType: Int
    @NSManaged var houseType: Int
    @NSManaged var price: Int

    /* Optional Fields */
    @NSManaged var region: Int
    @NSManaged var community: String?
    @NSManaged var size: Int
    @NSManaged var totalFloor: Int
    @NSManaged var floor: [Int]?
    @NSManaged var numBedroom: Int
    @NSManaged var numTing: Int
    @NSManaged var numPatio: Int
    @NSManaged var orientation: Int
    @NSManaged var wallMtl: String?
    @NSManaged var parkingLot: Bool
    @NSManaged var parkingType: Int
    @NSManaged var readyDate: NSDate?
    @NSManaged var shortestLease: Int
    
    /* Money Related */
    @NSManaged var priceIncl: [Int]?
    @NSManaged var otherExpense: [Int]?
    @NSManaged var mgmtFee: Int
    @NSManaged var hasMgmtFee: Bool
    @NSManaged var deposit: String?
    
    /* Limitations */
    @NSManaged var allowPet: Bool
    @NSManaged var allowCooking: Bool
    @NSManaged var restrProfile: String?
    @NSManaged var restrSex: Int
    
    /* Extra Benefits */
    @NSManaged var furniture: [Int]?
    @NSManaged var facility: [Int]?
    @NSManaged var surrounding: [Int]?
    @NSManaged var nearbyBus: String?
    @NSManaged var nearbyTrain: String?
    @NSManaged var nearbyMrt: String?
    @NSManaged var nearbyThsr: String?
    
    /* Sales Agent Info */
    @NSManaged var agent: String?
    @NSManaged var agentType: Int
    @NSManaged var phone: [String]?
    
    /* Extra Description */
    @NSManaged var desc: String?
    @NSManaged var img: [String]?
    @NSManaged var postTime: NSDate?
    @NSManaged var coordinate: String?
    
}