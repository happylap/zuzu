//
//  NoteDal.swift
//  Zuzu
//
//  Created by eechih on 2015/10/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import Dollar

class NoteDao: NSObject {
    
    // Utilize Singleton pattern by instanciating NoteDao only once.
    class var sharedInstance: NoteDao {
        struct Singleton {
            static let instance = NoteDao()
        }
        
        return Singleton.instance
    }
    
    // MARK: Create
    
    func addNote(house: House, noteDesc: String) {
        
        NSLog("%@ addNote", self)
        
        let context = CoreDataManager.shared.managedObjectContext
        
        let model = NSEntityDescription.entityForName(EntityTypes.Note.rawValue, inManagedObjectContext: context)
        
        let note = Note(entity: model!, insertIntoManagedObjectContext: context)
        
        if model != nil {
            note.title = noteDesc
            note.desc = noteDesc
            note.createDate = NSDate()
            note.houseId = house.id
            CoreDataManager.shared.save()
        }
    }
    
    // MARK: Read
    
    func getNoteListByHouseId(houseId: String) -> [Note]? {
        NSLog("%@ getNoteListByHouseId: \(houseId)", self)
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.Note.rawValue)
        
        let findByIdPredicate = NSPredicate(format: "houseId == %@", houseId)
        fetchRequest.predicate = findByIdPredicate
        
        //fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [Note]
    }
    
    func getNoteById(id: String) -> AnyObject? {
        NSLog("%@ getNoteById: \(id)", self)
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.Note.rawValue)
        
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate
        
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest)
        
        if let first = fetchedResults?.first {
            return first
        }
        return nil
    }
    
    // MARK: Delete
    
    func deleteById(id: String) {
        NSLog("%@ deleteById: \(id)", self)
        
        if let entity = self.getNoteById(id) {
            if let obj: NSManagedObject = entity as? NSManagedObject {
                CoreDataManager.shared.deleteEntity(obj)
                CoreDataManager.shared.save()
            }
        }
    }
    
    func deleteByHouseId(houseId: String) {
        NSLog("%@ deleteByHouseId: \(houseId)", self)
        
        if let result = self.getNoteListByHouseId(houseId) {
            for item in result {
                if let obj: NSManagedObject = item as? NSManagedObject {
                    CoreDataManager.shared.deleteEntity(obj)
                }
            }
            CoreDataManager.shared.save()
        }
    }
    
}