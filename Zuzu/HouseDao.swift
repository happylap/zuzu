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


class HouseDal: NSObject {

    func addHouseList(items: [AnyObject]) {
        for house in items {
            
            self.addHouse(house, save: false)
        }
        
        CoreDataManager.shared.save()
    }
    
    
    func addHouse(obj: AnyObject, save: Bool) {
        
        
        let context=CoreDataManager.shared.managedObjectContext
        
        
        let model = NSEntityDescription.entityForName("House", inManagedObjectContext: context)
        
        let house = House(entity: model!, insertIntoManagedObjectContext: context)
        
        if model != nil {
            //var article = model as Article;
            self.obj2ManagedObject(obj, house: house)
            
            if(save)
            {
                CoreDataManager.shared.save()
                
            }
        }
    }
    
    func deleteAll() {
        CoreDataManager.shared.deleteTable("House")
    }
    
    func save() {
        let context=CoreDataManager.shared.managedObjectContext
        do {
            try context.save()
        } catch _ {
        }
    }
    
    func getHouseList() -> [AnyObject]? {
        
        let request = NSFetchRequest(entityName: "House")
        let sort1=NSSortDescriptor(key: "lastCommentTime", ascending: false)
        
        // var sort2=NSSortDescriptor(key: "postId", ascending: false)
        request.fetchLimit = 30
        request.sortDescriptors = [sort1]
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        let result = CoreDataManager.shared.executeFetchRequest(request)
        return result
    }
    
    
    func obj2ManagedObject(obj: AnyObject, house: House) -> House {
        
        var data = JSON(obj)
        
        let title = data["title"].string!
        
        house.title = title
        
        //  println(post)
        return house;
    }

    
    
}