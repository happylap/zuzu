//
//  CoreDataResultsController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

class CoreDataResultsController: NSObject{
 
    class Builder: NSObject {
        
        private var entityName: String
        
        private var fetchRequest: NSFetchRequest?
        
        private var sortDescriptors = [NSSortDescriptor]?()
        
        private var predicate: NSPredicate?
        
        init(entityName: String) {
            self.entityName = entityName
            self.fetchRequest = NSFetchRequest(entityName: self.entityName)
        }
        
        func addSortingField(field: String, ascending: Bool) -> Builder{
            let sort = NSSortDescriptor(key: field, ascending: ascending)
            if self.sortDescriptors == nil{
                self.sortDescriptors  = [NSSortDescriptor]()
            }
            
            self.sortDescriptors?.append(sort)
            
            return self
        }
        
        func predicate(format: String, arguments: [AnyObject]?) -> Builder{
            self.predicate = NSPredicate(format: format, argumentArray: arguments)
            return self
        }
        
        func build() -> CoreDataResultsController {
            assert(self.fetchRequest != nil, "Fetch Request for entity \(self.entityName) cannot be nil")
            
            if self.sortDescriptors != nil{
                self.fetchRequest!.sortDescriptors = self.sortDescriptors!
            }

            if self.predicate != nil{
                self.fetchRequest!.predicate = self.predicate!
            }
            
            let fetchController = NSFetchedResultsController(fetchRequest: self.fetchRequest!, managedObjectContext: CoreDataManager.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            
            return CoreDataResultsController(resultController: fetchController)
        }
    }

    var resultController: NSFetchedResultsController
    
    private init(resultController: NSFetchedResultsController){
        self.resultController = resultController
    }
    
    
    func refresh(){
        do {
            try self.resultController.performFetch()
        } catch {
            let fetchError = error as NSError
            NSLog("\(fetchError), \(fetchError.userInfo)", self)
        }
    }
    
    func getNumberOfSectionsInTableView() -> Int{
        return 1
    }
    
    func getNumberOfRowInSection(section: Int) -> Int{
        let sectionInfo = self.resultController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject{
        return resultController.objectAtIndexPath(indexPath)
    }
    
}