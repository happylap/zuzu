//
//  NotificationHouseItemDao.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

class NotificationHouseItemDao: AbstractHouseItemDao
{
    class var sharedInstance: NotificationHouseItemDao {
        struct Singleton {
            static let instance = NotificationHouseItemDao()
        }
        
        return Singleton.instance
    }
    
    // MARK: - AbstractHouseItemDao overriding function

    override var entityName: String{
        return EntityTypes.NotificationHouseItem.rawValue
    }
    
    override func add(jsonObj: AnyObject, isCommit: Bool) -> AbstractHouseItem? {
        if let notificationItem = super.add(jsonObj, isCommit: false) as? NotificationHouseItem{
            notificationItem.isRead = false
            notificationItem.notificationTime = NSDate()
            
            if (isCommit == true) {
                self.commit()
            }
            
            return notificationItem
        }
        
        return nil
    }
}