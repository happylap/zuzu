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
        for house in items {
            self.addHouse(house, save: false)
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
    
    func getHouseList() -> Array<House> {
        var fetchedResults: Array<House> = Array<House>()
        
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        //let sort1 = NSSortDescriptor(key: "lastCommentTime", ascending: false)
        
        fetchRequest.fetchLimit = 30
        //fetchRequest.sortDescriptors = [sort1]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        // Execute fetch request
        do {
            fetchedResults = try CoreDataManager.shared.executeFetchRequest(fetchRequest) as! [House]
        } catch let fetchError as NSError {
            print("getHoustList error: \(fetchError.localizedDescription)")
            fetchedResults = Array<House>()
        }
        
        return fetchedResults
    }
    
    func getHouseById(houseId: NSString) -> Array<House> {
        var fetchedResults: Array<House> = Array<House>()
        
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        
        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id = %@", houseId)
        fetchRequest.predicate = findByIdPredicate
        
        // Execute fetch request
        do {
            fetchedResults = try CoreDataManager.shared.executeFetchRequest(fetchRequest) as! [House]
        } catch let fetchError as NSError {
            print("getHoustList error: \(fetchError.localizedDescription)")
            fetchedResults = Array<House>()
        }
        
        return fetchedResults
    }
    
    // MARK: Delete
    
    func deleteById(houseId: NSString) {
        let retrievedItems = self.getHouseById(houseId)
        
        for item in retrievedItems {
            self.delete(item)
        }
    }
    
    func deleteHouse(house: House) {
        CoreDataManager.shared.delete(house)
    }
    
    func deleteAll() {
        CoreDataManager.shared.deleteTable(EntityTypes.House.rawValue)
    }
    
    func obj2ManagedObject(obj: AnyObject, house: House) -> House {
        
        var data = JSON(obj)
        
        let id = data["id"].string!
        let title = data["title"].string!
        
        house.id = id
        house.title = title
        
        //  println(post)
        return house
    }
}