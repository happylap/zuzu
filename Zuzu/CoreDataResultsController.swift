//
//  CoreDataResultsController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

private let Log = Logger.defaultLogger

class CoreDataResultsController: NSObject, TableResultsController, NSFetchedResultsControllerDelegate{
 
    class Builder: NSObject {
        
        private var entityName: String
        
        private var fetchRequest: NSFetchRequest?
        
        private var sortDescriptors = [NSSortDescriptor]?()
        
        private var predicate: NSPredicate?
        
        init(entityName: String) {
            self.entityName = entityName
            self.fetchRequest = NSFetchRequest(entityName: self.entityName)
        }
        
        func addSorting(field: String, ascending: Bool) -> Builder{
            let sort = NSSortDescriptor(key: field, ascending: ascending)
            if self.sortDescriptors == nil{
                self.sortDescriptors  = [NSSortDescriptor]()
            }
            
            self.sortDescriptors?.append(sort)
            
            return self
        }
        
        func predicateBy(format: String, arguments: [AnyObject]?) -> Builder{
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
            
            let controller = CoreDataResultsController(resultController: fetchController)
            controller.resultsController.delegate = controller
            
            return controller
        }
    }

    var resultsController: NSFetchedResultsController
    
    var resultsControllerDelegate: TableResultsControllerDelegate?
    
    private init(resultController: NSFetchedResultsController){
        self.resultsController = resultController
    }
    
    // MARK: - TableResultsController Function
    
    func refreshData(){
        do {
            try self.resultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            Log.debug("\(fetchError), \(fetchError.userInfo)")
        }
    }
    
    func getNumberOfSectionsInTableView() -> Int{
        return 1
    }
    
    func getNumberOfRowInSection(section: Int) -> Int{
        let sectionInfo = self.resultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject{
        return self.resultsController.objectAtIndexPath(indexPath)
    }
    
    func setDelegate(resultControllerDelegate: TableResultsControllerDelegate){
        self.resultsControllerDelegate = resultControllerDelegate
    }
    
    // MARK: - NSFetchedResultsControllerDelegate Function
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.resultsControllerDelegate?.controllerWillChangeContent(self)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        var changeType: TableResultsChangeType?
        switch type {
        case .Insert:
            changeType = TableResultsChangeType.Insert
        case .Delete:
            changeType = TableResultsChangeType.Delete
        case .Update:
            changeType = TableResultsChangeType.Update
        case .Move:
            changeType = TableResultsChangeType.Move
        }
        
        if changeType != nil{
            self.resultsControllerDelegate?.controller(self, didChangeObject: anObject, atIndexPath: indexPath, forChangeType: changeType!, newIndexPath: newIndexPath)
        }

    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.resultsControllerDelegate?.controllerDidChangeContent(self)
    }
    
}