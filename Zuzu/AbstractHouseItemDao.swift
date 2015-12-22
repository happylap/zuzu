//
//  AbstractHouseItemDao
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

class AbstractHouseItemDao: NSObject
{
    // MARK: - Requird Override Function
    var entityName: String{
        preconditionFailure("entityName property must be overridden")
    }
    
    // Only add item, but not commit to DB
    func add(jsonObj: AnyObject) {
        preconditionFailure("This method must be overridden")
    }
    
    // MARK: - Read Function
    
    func isExist(id: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        let findByIdPredicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = findByIdPredicate
        let count = CoreDataManager.shared.countForFetchRequest(fetchRequest)
        return count > 0
    }
    
    // MARK: - Get Function
    
    func get(id: String) -> AbstractHouseItem? {
        NSLog("%@ get: \(id)", self)
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        
        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate
        
        // Execute fetch request
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [AbstractHouseItem]
        
        //print(fetchedResults)
        
        if let first = fetchedResults?.first {
            return first
        }
        
        return nil
    }
    
    func getAll() -> [AbstractHouseItem]? {
        NSLog("%@ getAll", self)
        
        let fetchRequest = NSFetchRequest(entityName: self.entityName)

        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [AbstractHouseItem]
    }
    
    // MARK: - Add Function
    
    func addAll(items: [AnyObject]){
        for item in items {
            self.add(item, isCommit: false)
        }
        
        self.commit()
    }
    
    func add(jsonObj: AnyObject, isCommit: Bool) {
        if let id = jsonObj.valueForKey("id") as? String {
            if self.isExist(id) {
                return
            }
            
            self.add(jsonObj)
            
            if (isCommit == true) {
                self.commit()
            }
        }
    }
    
    // MARK: Delete Function    
    func deleteByID(id: String) {
        NSLog("%@ deleteByID: \(id)", self)
        if let item = self.get(id) {
            CoreDataManager.shared.deleteEntity(item)
            self.commit()
        }
    }
    
    func deleteAll() {
        CoreDataManager.shared.deleteTable(self.entityName)
    }

    // MARK: Update Function
    
    func updateByObjectId(objectId: NSManagedObjectID, dataToUpdate: [String: AnyObject]) {
        if let item = CoreDataManager.shared.get(objectId) {
            for (key, value) in dataToUpdate {
                if let _ = item.valueForKey(key) {
                    item.setValue(value, forKey: key)
                }
            }
            CoreDataManager.shared.save()
        }
    }
    
    // MARK: Commit Function
    
    private func commit(){
        CoreDataManager.shared.save()
    }
}