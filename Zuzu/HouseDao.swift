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
        let link = data["link"].stringValue
        let mobileLink = data["mobileLink"].stringValue
        let title = data["title"].stringValue
        let addr = data["addr"].stringValue
        let city = data["city"].intValue
        let usage = data["purpose_type"].intValue
        let type = data["house_type"].intValue
        let price = data["price"].intValue
        
        let size = data["size"].intValue
        let desc = data["desc"].stringValue
        
        let img = data["img"].arrayObject as? [String] ?? [String]()
        
        house.id = id
        house.link = link
        house.mobileLink = mobileLink
        house.title = title
        house.addr = addr
        house.city = city
        house.usage = usage
        house.type = type
        house.price = price
        
        house.size = size
        house.desc = desc
        house.img = img
        
        return house
    }
}