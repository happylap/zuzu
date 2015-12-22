//
//  CollectionHouseItemDao.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

class CollectionHouseItemDao: AbstractHouseItemDao
{
    class var sharedInstance: CollectionHouseItemDao {
        struct Singleton {
            static let instance = CollectionHouseItemDao()
        }
        
        return Singleton.instance
    }
    
    // MARK: - AbstractHouseItemDao overriding function
    
    override var entityName: String{
        return EntityTypes.CollectionHouseItem.rawValue
    }
    
    // Only add item, but not commit to DB
    override func add(jsonObj: AnyObject) {
        if let id = jsonObj.valueForKey("id") as? String {
            if self.isExist(id) {
                return
            }
            
            NSLog("%@ add notification item", self)
            
            let context=CoreDataManager.shared.managedObjectContext
            
            let model = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: context)
            
            let collectionItem = CollectionHouseItem(entity: model!, insertIntoManagedObjectContext: context)
            
            if model != nil {
                collectionItem.fromJSON(jsonObj)
            }
        }
    }
}
