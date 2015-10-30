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
    
    // MARK: Read
    
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
    
    func getHouseById(id: NSString) -> House? {
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        
        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = findByIdPredicate
        
        // Execute fetch request
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest)
        
        if fetchedResults?.count != 0 {
            
            if let fetchedHouse: House = fetchedResults![0] as? House {
                return fetchedHouse
            }
        }
        return nil
        
    }
    
    // MARK: Delete
    
    func deleteById(id: NSString) {
        if let house = self.getHouseById(id) {
            NSLog("delete data id: \(house.id)")
            CoreDataManager.shared.deleteEntity(house)
            CoreDataManager.shared.save()
        }
    }
    
    func deleteAll() {
        CoreDataManager.shared.deleteTable(EntityTypes.House.rawValue)
    }
    
    func obj2ManagedObject(obj: AnyObject, house: House) -> House {
        
        var data = JSON(obj)
        
        let id = data["id"].stringValue
        let title = data["title"].stringValue
        let img = data["img"].arrayObject as? [String] ?? [String]()
        let price = data["price"].intValue
        let addr = data["addr"].stringValue
        
//        let id = house["id"]  as? String
//        let title = house["title"] as? String
//        let addr = house["addr"]  as? String
//        let type = house["house_type"] as? Int
//        let usage = house["purpose_type"] as? Int
//        let price = house["price"] as? Int
//        let size = house["size"] as? Int
//        let desc = house["desc"]  as? String
//        let imgList = house["img"] as? [String]
        
        house.id = id
        house.title = title
        house.img = img
        house.price = price
        house.addr = addr
//        
//        house.img = [String]()
////        
//        for (_, subJson) in img.enumerate() {
//            house.img?.append(subJson.stringValue)
//        }
        
        return house
    }
}