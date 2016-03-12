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

private let Log = Logger.defaultLogger

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
        
        Log.debug("\(self) addNote")
        
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
        Log.debug("\(self) getNoteListByHouseId: \(houseId)")
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.Note.rawValue)
        
        let findByIdPredicate = NSPredicate(format: "houseId == %@", houseId)
        fetchRequest.predicate = findByIdPredicate
        
        //fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [Note]
    }
    
    func getNoteById(id: String) -> AnyObject? {
        Log.debug("\(self) getNoteById: \(id)")
        
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
        Log.debug("\(self) deleteById: \(id)")
        
        if let entity = self.getNoteById(id) {
            if let obj: NSManagedObject = entity as? NSManagedObject {
                CoreDataManager.shared.deleteEntity(obj)
                CoreDataManager.shared.save()
            }
        }
    }
    
    func deleteByHouseId(houseId: String) {
        Log.debug("\(self) deleteByHouseId: \(houseId)")
        
        if let result = self.getNoteListByHouseId(houseId) {
            for item in result {
                CoreDataManager.shared.deleteEntity(item)
            }
            CoreDataManager.shared.save()
        }
    }
    
}