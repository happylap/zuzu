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


    var entityName: String {
        return EntityTypes.Note.rawValue
    }

    // MARK: Create

    func addAll(notes: [AnyObject]) {
        for note in notes {
            self.add(note, isCommit: false)
        }

        self.commit()
    }

    func add(jsonObj: AnyObject, isCommit: Bool) -> Note? {

        Log.debug("\(self) add \(jsonObj)")

        if let id = jsonObj.valueForKey("id") as? String {
            if self.isExist(id) {
                Log.debug("Existed note id: \(id)")
                return nil
            }

            let context=CoreDataManager.shared.managedObjectContext

            let model = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: context)

            let note = Note(entity: model!, insertIntoManagedObjectContext: context)

            if model != nil {
                note.fromJSON(jsonObj)
                if (isCommit == true) {
                    self.commit()
                }
                return note
            }
        }

        return nil
    }

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

    func isExist(id: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate
        let count = CoreDataManager.shared.countForFetchRequest(fetchRequest)
        return count > 0
    }

    func getAll() -> [Note]? {
        Log.enter()
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [Note]
    }

    func get(id: String) -> Note? {
        Log.debug("\(self) get: \(id)")
        // Create request on House entity
        let fetchRequest = NSFetchRequest(entityName: self.entityName)

        // Add a predicate to filter by houseId
        let findByIdPredicate = NSPredicate(format: "id == %@", id)
        fetchRequest.predicate = findByIdPredicate

        // Execute fetch request
        let fetchedResults = CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [Note]

        //print(fetchedResults)

        if let first = fetchedResults?.first {
            return first
        }

        return nil
    }


    func getByHouseId(houseId: String) -> [Note]? {
        Log.debug("\(self) getByHouseId: \(houseId)")

        let fetchRequest = NSFetchRequest(entityName: self.entityName)

        let findByIdPredicate = NSPredicate(format: "houseId == %@", houseId)
        fetchRequest.predicate = findByIdPredicate

        //fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType

        return CoreDataManager.shared.executeFetchRequest(fetchRequest) as? [Note]
    }

    // MARK: Delete

    // MARK: Delete Function
    func deleteById(id: String) {
        Log.debug("\(self) deleteById: \(id)")
        if let note = self.get(id) {
            CoreDataManager.shared.deleteEntity(note)
            self.commit()
        }
    }

    func deleteByHouseId(houseId: String) {
        Log.debug("\(self) deleteByHouseId: \(houseId)")

        if let notes = self.getByHouseId(houseId) {
            for note in notes {
                CoreDataManager.shared.deleteEntity(note)
            }
            CoreDataManager.shared.save()
        }
    }

    func safeDeleteById(id: String) {
        if self.isExist(id) {
            self.deleteById(id)
        }
    }

    // MARK: Commit Function
    func commit() {
        CoreDataManager.shared.save()
    }

}
