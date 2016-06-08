//
//  CollectionItemService.swift
//  Zuzu
//
//  Created by eechih on 1/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognito
import ObjectMapper

private let Log = Logger.defaultLogger

class NoteService: NSObject
{
    let dao = NoteDao.sharedInstance
    
    class var sharedInstance: NoteService {
        struct Singleton {
            static let instance = NoteService()
        }
        
        return Singleton.instance
    }
    
    func start() {
        Log.enter()
        let center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self,
                           selector: #selector(NoteService.didSyncFromCognitoNotification(_:)),
                           name: SyncFromCognitoNotification,
                           object:nil)
        Log.exit()
    }
    
    // MARK: Notifications
    
    func didSyncFromCognitoNotification(aNotification: NSNotification) {
        
        dispatch_async(dispatch_get_main_queue()) {
            Log.enter()
            
            if let modifyingKeys: [String] = aNotification.userInfo?["keys"] as? [String] {
                if modifyingKeys.count > 0 {
                    
                    if let dataset: AWSCognitoDataset = aNotification.object as? AWSCognitoDataset {
                        if dataset.name != CognitoDatasetType.Note.name() {
                            return
                        }
                        
                        if let temp = dataset.getAllRecords() as? [AWSCognitoRecord] {
                            let dirtyRecords: [AWSCognitoRecord] = temp.filter {
                                return $0.dirty || ($0.data.string() != nil && $0.data.string().characters.count != 0)
                            }
                            
                            var dirtyKeys: [String] = []
                            for dirtyRecord: AWSCognitoRecord in dirtyRecords {
                                dirtyKeys.append(dirtyRecord.recordId)
                            }
                            
                            // Delete collectionItem, if its id isn't exist dirtyKeys
                            if let notes = self.getAll() {
                                for note: Note in notes {
                                    let id = note.id
                                    if !dirtyKeys.contains(id) {
                                        Log.debug("Sync Note To CoreData >>> DeleteNoteByID: \(id)")
                                        self.dao.safeDeleteById(id)
                                    }
                                }
                            }
                            
                            // Delete collectionItem by modifyingKey
                            for modifyingKey: String in modifyingKeys {
                                Log.debug("Sync Note To CoreData >>> DeleteNoteByKey: \(modifyingKey)")
                                self.dao.safeDeleteById(modifyingKey)
                            }
                            
                            
                            // Add collectionItem if dirtyKey in modifyingKeys
                            for dirtyRecord: AWSCognitoRecord in dirtyRecords {
                                let dirtyKey = dirtyRecord.recordId
                                if modifyingKeys.contains(dirtyKey) {
                                    //Log.debug("%@ dirtyRecord: \(dirtyRecord)", self)
                                    
                                    let JSONString = dirtyRecord.data.string()
                                    let note: Note? = Mapper<Note>().map(JSONString)
                                    
                                    if note != nil {
                                        Log.debug("Sync Note To CoreData >>> AddNote ID: \(note!.id)")
                                    }
                                }
                            }
                            
                            self.dao.commit()
                        }
                    }
                }
            }
            
            Log.exit()
        }

    }
    
    func addNote(houseId: String, title: String) {
        Log.enter()
        
        let id = NSUUID().UUIDString
        
        var obj = [String: AnyObject]()
        obj["id"] = id
        obj["title"] = title
        obj["houseId"] = houseId
        
        self.dao.add(obj, isCommit: true)
        
        if let note: Note = self.getNote(id) {
            if let JSONString = Mapper().toJSONString(note) {
                Log.debug("JSONString: \(JSONString)")
                CognitoSyncService.sharedInstance.doAdd(CognitoDatasetType.Note, key: id, value: JSONString)
            }
        }
        
        Log.exit()
    }
    
    func deleteNote(id: String) {
        Log.enter()
        self.dao.safeDeleteById(id)
        CognitoSyncService.sharedInstance.doDel(CognitoDatasetType.Note, key: id)
        Log.exit()
    }
    
    func getNote(id: String) -> Note? {
        Log.enter()
        let note = self.dao.get(id)
        Log.debug("return \(note)")
        return note
    }
    
    func getAll(houseId: String) -> [Note]? {
        Log.enter()
        return self.dao.getByHouseId(houseId)
    }
    
    func getAll() -> [Note]?{
        return self.dao.getAll()
    }
    
    func hasNote(houseId: String) -> Bool {
        Log.enter()
        
        var has = false
        if let notes = self.getAll(houseId) {
            if notes.count > 0 {
                has = true
            }
        }
        
        Log.debug("return \(has)")
        return has
    }
    
    func isExist(id: String) -> Bool{
        Log.enter()
        let existed = self.dao.isExist(id)
        Log.debug("return \(existed)")
        return existed
    }
    
}