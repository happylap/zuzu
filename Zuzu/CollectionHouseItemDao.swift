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
    
    override func add(jsonObj: AnyObject, isCommit: Bool) -> CollectionHouseItem? {
        if let collectItem = super.add(jsonObj, isCommit: false) as? CollectionHouseItem{
            collectItem.contacted = false
            collectItem.collectTime = NSDate()
            
            if (isCommit == true) {
                self.commit()
            }
            
            return collectItem
        }
        
        return nil
    }
    
    func getCollectionIdList() -> [String]? {
        var result: [String] = []
        if let allItems = self.getAll() {
            for item: AbstractHouseItem in allItems {
                result.append(item.id)
            }
        }
        return result
    }
}
