//
//  NotificationFacadeService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

class NotificationItemService: NSObject {
    
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
    
    func add(item:NotifyItem, isCommit: Bool){
        if let newItem = self.dao.add(item.id){
            newItem.img = []
            if let firtImg = item.firstImgUrl{
                newItem.img!.append(firtImg)
            }
            
            newItem.price = item.price
            newItem.size = item.size
            newItem.houseType = item.houseType
            newItem.purposeType = item.purposeType
            newItem.title = item.title
            newItem.addr = item.addr
            newItem.postTime = item.postTime
            newItem.isRead = item.isRead
            
            if (isCommit == true) {
                self.dao.commit()
            }
        }
        
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
    
    func removeExtra(isCommit: Bool){
        if let notifyItems = self.getAll(){
            if notifyItems.count > 200{
                for (index, item) in notifyItems.enumerate() {
                    if index >= 200{
                        Log.debug("Delete Item: \(item)")
                        self.dao.deleteByID(item.id)
                    }
                }
                
                if isCommit == true{
                    self.dao.commit()
                }
            }
        }
        
    }
    
    func isExist(id: String) -> Bool{
        return self.dao.isExist(id)
    }
    
    
}