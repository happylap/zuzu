//
//  CoreDataManagerExtend.swift
//  Zuzu
//
//  Created by eechih on 2015/11/11.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import CoreData

extension CoreDataManager {
    
    /**
     Simple interface for deleting one or more managed objects from a persistent store.
     @param        objects Managed object(s) to delete.
     @discussion   This method does not save the changes to the managed object context.
     */
    func delete(objects: NSManagedObject...) {
        for object in objects {
            self.managedObjectContext.deleteObject(object)
        }
    }
    
    
    /**
     Simple interface for deleting one or more managed objects from a persistent store by using its identifier.
     @param        identifiers Identifier of managed object(s) to delete.
     @discussion   This method does not save the changes to the managed object context.
     */
    func delete(identifiers: NSManagedObjectID...) {
        for identifier in identifiers {
            let object = self.managedObjectContext.objectRegisteredForID(identifier)
            if object != nil {
                delete(object!)
            }
        }
    }
}