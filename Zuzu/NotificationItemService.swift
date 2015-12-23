//
//  NotificationFacadeService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class NotificationItemService: NSObject
{
    let dao = NotificationHouseItemDao.sharedInstance
    
    var entityName: String{
        return self.dao.entityName
    }
    
    class var sharedInstance: NotificationItemService {
        struct Singleton {
            static let instance = NotificationItemService()
        }
        
        return Singleton.instance
    }

    func addItem(jsonObj: AnyObject){
        self.dao.add(jsonObj, isCommit: true)
    }
    
    func addAll(items: [AnyObject]){
        self.dao.addAll(items)
    }
    
    func deleteItem(item: NotificationHouseItem){
        self.dao.deleteByID(item.id)
    }
    
    func updateItem(item: NotificationHouseItem, dataToUpdate: [String: AnyObject]){
        self.dao.updateByID(item.id, dataToUpdate: dataToUpdate)
    }

    func getItem(id:String) -> NotificationHouseItem?{
        return self.dao.get(id) as? NotificationHouseItem
    }
    
    func getAll() -> [NotificationHouseItem]?{
        return self.dao.getAll() as? [NotificationHouseItem]
    }
    
    func isExist(id: String) -> Bool{
        return self.dao.isExist(id)
    }

    
}