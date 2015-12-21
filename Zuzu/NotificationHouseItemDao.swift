//
//  NotificationHouseItemDao.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

class NotificationHouseItemDao: HouseItemDaoTemplate
{
    class var sharedInstance: NotificationHouseItemDao {
        struct Singleton {
            static let instance = NotificationHouseItemDao()
        }
        
        return Singleton.instance
    }
    
    // MARK: - Override HouseItemDaoTemplate

    override var entityName: String{
        return EntityTypes.NotificationHouseItem.rawValue
    }
    
    override func add(jsonObj: AnyObject) {
        if let id = jsonObj.valueForKey("id") as? String {
            if self.isExist(id) {
                return
            }
            
            NSLog("%@ add notification item", self)
            
            let context=CoreDataManager.shared.managedObjectContext
            
            let model = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: context)
            
            let notificationItem = NotificationHouseItem(entity: model!, insertIntoManagedObjectContext: context)
            
            if model != nil {
                notificationItem.fromJSON(jsonObj)
                notificationItem.notificationTime = NSDate()
            }
        }
    }
}