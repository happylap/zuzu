//
//  HouseDal.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import Dollar

extension Optional {
    
    func valueOrDefault(defaultValue: Wrapped) -> Wrapped {
        switch(self) {
        case .None:
            return defaultValue
        case .Some(let value):
            return value
        }
    }
}


class HouseDao: NSObject {
    
    // Utilize Singleton pattern by instanciating HouseDao only once.
    class var sharedInstance: HouseDao {
        struct Singleton {
            static let instance = HouseDao()
        }
        
        return Singleton.instance
    }
    
    // MARK: Create
    
    func addHouseList(items: [AnyObject]) {
        for item in items {
            self.addHouse(item, save: false)
        }
        
        CoreDataManager.shared.save()
    }
    
    
    func addHouse(obj: AnyObject, save: Bool) {
        if let houseId = obj.valueForKey("id") as? String {
            if self.isExist(houseId) {
                return
            }
            
            NSLog("%@ addHouse", self)
            
            let context=CoreDataManager.shared.managedObjectContext
            
            let model = NSEntityDescription.entityForName(EntityTypes.House.rawValue, inManagedObjectContext: context)
            
            let house = House(entity: model!, insertIntoManagedObjectContext: context)
            house.collectTime = NSDate()
            
            if model != nil {
                //var article = model as Article;
                self.obj2ManagedObject(obj, house: house)
                
                if (save) {
                    CoreDataManager.shared.save()
                }
            }
        }
    }
    
    // MARK: Read
    
    func isExist(id: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        let findByIdPredicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = findByIdPredicate
        let count = CoreDataManager.shared.countForFetchRequest(fetchRequest)
        return count > 0
    }
    
    func getHouseList() -> [House]? {
        NSLog("%@ getHouseList", self)
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        //let sort1 = NSSortDescriptor(key: "lastCommentTime", ascending: false)
        
        //fetchRequest.fetchLimit = 30
        //fetchRequest.sortDescriptors = [sort1]
        //        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [House]
    }
    
    func getHouseById(id: String) -> House? {
        NSLog("%@ getHouseById: \(id)", self)
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        
        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate
        
        // Execute fetch request
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [House]
        
        //print(fetchedResults)
        
        if let first = fetchedResults?.first {
            return first
        }
        
        return nil
    }
    
    func getHouseIdList() -> [String]? {
        var result: [String] = []
        if let houseList = self.getHouseList() {
            result = []
            for house: House in houseList {
                result.append(house.id)
            }
        }
        return result
    }
    
    // MARK: Update
    
    func updateByObjectId(objectId: NSManagedObjectID, dataToUpdate: [String: AnyObject]) {
        if let house = CoreDataManager.shared.get(objectId) {
            for (key, value) in dataToUpdate {
                if let _ = house.valueForKey(key) {
                    house.setValue(value, forKey: key)
                }
            }
            CoreDataManager.shared.save()
        }
    }
    
    // MARK: Delete
    
    func deleteByObjectId(objectId: NSManagedObjectID) {
        NSLog("%@ deleteByObjectId: \(objectId)", self)
        CoreDataManager.shared.delete(objectId)
        CoreDataManager.shared.save()
    }
    
    func deleteById(id: String) {
        NSLog("%@ deleteById: \(id)", self)
        if let house = self.getHouseById(id) {
            CoreDataManager.shared.deleteEntity(house)
            CoreDataManager.shared.save()
        }
    }
    
    func deleteAll() {
        CoreDataManager.shared.deleteTable(EntityTypes.House.rawValue)
    }
    
    func obj2ManagedObject(obj: AnyObject, house: House) -> House {
        
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
        let usage = data["purpose_type"].int32Value
        let type = data["house_type"].int32Value
        let price = data["price"].int32Value
        
        /* Optional Fields */
        let region = data["region"].int32Value
        let community = data["community"].stringValue
        let size = data["size"].int32Value
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
        let source = data["source"].int32Value
        
        house.id = id
        house.link = link
        house.mobileLink = mobileLink
        house.title = title
        house.addr = addr
        house.city = city
        house.usage = usage
        house.type = type
        house.price = price
        
        house.region = region
        house.community = community
        house.size = size
        house.totalFloor = totalFloor
        house.floor = floor
        house.numBedroom = numBedroom
        house.numTing = numTing
        house.numPatio = numPatio
        house.orientation = orientation
        house.wallMtl = wallMtl
        house.parkingLot = parkingLot
        house.parkingType = parkingType
        house.readyDate = readyDate
        house.shortestLease = shortestLease
        
        house.priceIncl = priceIncl
        house.otherExpense = otherExpense
        house.mgmtFee = mgmtFee
        house.hasMgmtFee = hasMgmtFee
        house.deposit = deposit
        
        house.allowPet = allowPet
        house.allowCooking = allowCooking
        house.restrProfile = restrProfile
        house.restrSex = restrSex
        
        house.furniture = furniture
        house.facility = facility
        //house.surrounding = surrounding
        house.nearbyBus = nearbyBus
        house.nearbyTrain = nearbyTrain
        house.nearbyMrt = nearbyMrt
        house.nearbyThsr = nearbyThsr
        
        house.agent = agent
        house.agentType = agentType
        house.phone = phone
        
        house.desc = desc
        house.img = img
        house.postTime = postTime
        house.coordinate = coordinate
        house.source = source
        
        house.contacted = false
//        house.notes = NSOrderedSet()
        
        return house
    }
}