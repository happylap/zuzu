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
        
        
        if let id = obj.valueForKey("id") as? String {
            if self.isExist(id) {
                return
            }
            
            NSLog("%@ addHouse", self)
            
            let context=CoreDataManager.shared.managedObjectContext
            
            let model = NSEntityDescription.entityForName(EntityTypes.House.rawValue, inManagedObjectContext: context)
            
            let house = House(entity: model!, insertIntoManagedObjectContext: context)
            
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
    
    func isExist(id: NSString) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        let findByIdPredicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = findByIdPredicate
        let count = CoreDataManager.shared.countForFetchRequest(fetchRequest)
        return count > 0
    }
    
    func getHouseList() -> [AnyObject]? {
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        //let sort1 = NSSortDescriptor(key: "lastCommentTime", ascending: false)
        
        //fetchRequest.fetchLimit = 30
        //fetchRequest.sortDescriptors = [sort1]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        // Execute fetch request
        return CoreDataManager.shared.executeFetchRequest(fetchRequest)
    }
    
    func getHouseList2() -> [House]? {
        NSLog("%@ getHouseList2", self)
        
        var results: [House]?
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        //let sort1 = NSSortDescriptor(key: "lastCommentTime", ascending: false)
        
        //fetchRequest.fetchLimit = 30
        //fetchRequest.sortDescriptors = [sort1]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        CoreDataManager.shared.managedObjectContext.performBlockAndWait {
            var fetchError:NSError?
            
            do {
                results = try CoreDataManager.shared.managedObjectContext.executeFetchRequest(fetchRequest) as? [House]
            } catch let error as NSError {
                fetchError = error
                results = nil
            } catch {
                fatalError()
            }
            if let error = fetchError {
                print("Warning!! \(error.description)")
            }
        }
        return results
    }
    
    func getHouseList3() -> [House]? {
        NSLog("%@ getHouseList3", self)
        
        var result: [House]? = [House]()
        
        let fetchedResult = self.getHouseList()
        
        if fetchedResult != nil {
            for item in fetchedResult! {
                let houseItem = House()
                
                houseItem.title = item.valueForKey("title") as? String ?? ""
                houseItem.price = item.valueForKey("price") as? Int ?? 0
                houseItem.addr = item.valueForKey("addr") as? String ?? ""
                result?.append(houseItem)
            }
        }
        return result
    }
    
    func getHouseById(id: NSString) -> AnyObject? {
        NSLog("%@ getHouseById: \(id)", self)
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        
        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate
        
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        // Execute fetch request
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest)
        
        //print(fetchedResults)
        
        if let first = fetchedResults?.first {
            return first
        }
        
        return nil
    }
    
    // MARK: Delete
    
    func deleteById(id: NSString) {
        NSLog("%@ deleteById: \(id)", self)
        if let item = self.getHouseById(id) {
            print(item)
            if let obj: NSManagedObject = item as? NSManagedObject {
                CoreDataManager.shared.deleteEntity(obj)
                CoreDataManager.shared.save()
            }
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
        let city = data["city"].intValue
        let usage = data["purpose_type"].intValue
        let type = data["house_type"].intValue
        let price = data["price"].intValue
        
        /* Optional Fields */
        let region = data["region"].intValue
        let community = data["community"].stringValue
        let size = data["size"].intValue
        let totalFloor = data["total_floor"].intValue
        let floor = data["floor"].arrayObject as? [Int] ?? [Int]()
        let numBedroom = data["num_bedroom"].intValue
        let numTing = data["num_ting"].intValue
        let numPatio = data["num_patio"].intValue
        let orientation = data["orientation"].intValue
        let wallMtl = data["wall_mtl"].stringValue
        let parkingLot = data["parking_lot"].boolValue
        let parkingType = data["parkingType"].intValue
        let readyDate: NSDate? = dateFormatter.dateFromString(data["ready_date"].stringValue)
        let shortestLease = data["shortest_lease"].intValue
        
        /* Money Related */
        let priceIncl = data["price_incl"].arrayObject as? [Int] ?? [Int]()
        let otherExpense = data["other_expense"].arrayObject as? [Int] ?? [Int]()
        let mgmtFee = data["mgmt_fee"].intValue
        let hasMgmtFee = data["has_mgmt_fee"].boolValue
        let deposit = data["deposit"].stringValue
        
        /* Limitations */
        let allowPet = data["allow_pet"].boolValue
        let allowCooking = data["allow_cooking"].boolValue
        let restrProfile = data["restr_profile"].stringValue
        let restrSex = data["restr_sex"].intValue
        
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
        let agentType = data["agent_type"].intValue
        let phone = data["phone"].arrayObject as? [String] ?? [String]()
        
        /* Extra Description */
        let desc = data["desc"].stringValue
        let img = data["img"].arrayObject as? [String] ?? [String]()
        let postTime: NSDate? = dateFormatter.dateFromString(data["post_time"].stringValue)
        let coordinate = data["coordinate"].stringValue
        
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
        
        return house
    }
}