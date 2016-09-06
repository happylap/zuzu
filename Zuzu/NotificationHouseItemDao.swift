//
//  NotificationHouseItemDao.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

private let Log = Logger.defaultLogger

class NotificationHouseItemDao: AbstractHouseItemDao {
    class var sharedInstance: NotificationHouseItemDao {
        struct Singleton {
            static let instance = NotificationHouseItemDao()
        }

        return Singleton.instance
    }

    // MARK: - AbstractHouseItemDao overriding function

    override var entityName: String {
        return EntityTypes.NotificationHouseItem.rawValue
    }

    func add(id: String) -> NotificationHouseItem? {
        if self.isExist(id) {
            return nil
        }

        let context=CoreDataManager.shared.managedObjectContext

        let model = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: context)

        let item = NotificationHouseItem(entity: model!, insertIntoManagedObjectContext: context)

        if model != nil {
            item.id = id
            return item
        }

        return nil
    }

    override func add(jsonObj: AnyObject, isCommit: Bool) -> AbstractHouseItem? {
        if let notificationItem = super.add(jsonObj, isCommit: false) as? NotificationHouseItem {
            notificationItem.isRead = false
            notificationItem.notificationTime = NSDate()

            if (isCommit == true) {
                self.commit()
            }

            return notificationItem
        }

        return nil
    }

    override func getAll() -> [AbstractHouseItem]? {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        let sort = NSSortDescriptor(key: "postTime", ascending: false)
        var sortDescriptors = [NSSortDescriptor]()
        sortDescriptors.append(sort)
        fetchRequest.sortDescriptors = sortDescriptors
        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [AbstractHouseItem]
    }
}
