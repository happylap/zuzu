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
import SwiftyJSON
import ObjectMapper
import SwiftDate
import AwesomeCache

private let Log = Logger.defaultLogger

class NoteService: NSObject
{
    let dao = NoteDao.sharedInstance
    
    let datasetName = "Note"
    
    var parentViewController: UIViewController?
    
    var entityName: String{
        return self.dao.entityName
    }
    
    struct NoteServiceConstants {
        static let NOTE_MAX_SIZE = 60
        static let SYNCHRONIZE_DELAY_FOR_ADD = 3.0  // Unit: second
        static let SYNCHRONIZE_DELAY = 1.0  // Unit: second
    }
    
    class var sharedInstance: NoteService {
        struct Singleton {
            static let instance = NoteService()
        }
        
        return Singleton.instance
    }
    
    func start() {
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.didFinishUserLoginNotification(_:)),
                                                         name: UserLoginNotification,
                                                         object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.startSynchronizeNotification(_:)),
                                                         name: AWSCognitoDidStartSynchronizeNotification,
                                                         object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.endSynchronizeNotification(_:)),
                                                         name: AWSCognitoDidEndSynchronizeNotification,
                                                         object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.failToSynchronizeNotification(_:)),
                                                         name: AWSCognitoDidFailToSynchronizeNotification,
                                                         object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.changeRemoteValueNotification(_:)),
                                                         name: AWSCognitoDidChangeRemoteValueNotification,
                                                         object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(NoteService.changeLocalValueFromRemoteNotification(_:)),
                                                         name: AWSCognitoDidChangeLocalValueFromRemoteNotification,
                                                         object:nil)
    }
    
    // MARK: Private methods for modify items
    
    func _add(obj: AnyObject) {
        Log.debug("_add: \(obj)")
        
        self.dao.addAll([obj])
        
        // Add note to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            
            let id = obj.valueForKey("id") as! String
            
            if let note: Note = self.getNote(id) {
                Log.debug("note: \(note)")
                
                let JSONString = Mapper().toJSONString(note)
                Log.debug("JSONString: \(JSONString)")
                
                dataset.setString(JSONString, forKey: id)
            }
            
            self._syncDataset(NoteServiceConstants.SYNCHRONIZE_DELAY_FOR_ADD)
        }
    }
    
    /*
    func _update(id: String, dataToUpdate: [String: AnyObject]) {
        self.dao.updateByID(id, dataToUpdate: dataToUpdate)
        
        // Update item to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            if let item: CollectionHouseItem = self.getItem(id) {
                let JSONString = Mapper().toJSONString(item)
                dataset.setString(JSONString, forKey: id)
            }
            self._syncDataset(NoteServiceConstants)
        }
    }
    */
    
    func _delete(id: String) {
        self.dao.safeDeleteById(id)
        
        // Delete item from Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            dataset.removeObjectForKey(id)
            self._syncDataset(NoteServiceConstants.SYNCHRONIZE_DELAY)
        }
    }
    
    // MARK: Dataset methods
    
    func _getDataSet() -> AWSCognitoDataset? {
        let datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        for dataset in datasets {
            if dataset.name == self.datasetName {
                if let dataset = AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName) {
                    return dataset
                }
            }
        }
        return nil
    }
    
    func _openOrCreateDataset() -> AWSCognitoDataset {
        var dataset = self._getDataSet()
        
        if dataset == nil{
            dataset = AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName)
            var datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
            datasets.append(dataset!)
        }
        
        return dataset!
    }
    
    
    // MARK: Notifications
    
    func didFinishUserLoginNotification(aNotification: NSNotification) {
        Log.debug("ZuzuApp didFinishUserLoginNotification")
        self._doSync()
    }
    
    func startSynchronizeNotification(aNotification: NSNotification) {
        Log.debug("AWSCognito startSynchronizeNotification")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func endSynchronizeNotification(aNotification: NSNotification) {
        Log.debug("AWSCognito endSynchronizeNotification")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func failToSynchronizeNotification(aNotification: NSNotification) {
        Log.debug("AWSCognito failToSynchronizeNotification")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func changeRemoteValueNotification(aNotification: NSNotification) {
        Log.debug("AWSCognito changeRemoteValueNotification")
        
    }
    
    func changeLocalValueFromRemoteNotification(aNotification: NSNotification) {
        Log.debug("AWSCognito changeRemoteValueNotification")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if self.parentViewController != nil {
                LoadingSpinner.shared.setImmediateAppear(true)
                LoadingSpinner.shared.setOpacity(0.3)
                LoadingSpinner.shared.startOnView(self.parentViewController!.view)
            }
            
            if let modifyingKeys: [String] = aNotification.userInfo?["keys"] as? [String] {
                if modifyingKeys.count > 0 {
                    
                    if let dataset: AWSCognitoDataset = aNotification.object as? AWSCognitoDataset {
                        if dataset.name != self.datasetName{
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
                            if let notes = self.getAll("") {
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
            
            if self.parentViewController != nil {
                LoadingSpinner.shared.stop()
            }
        }
    }
    
    // MARK: Private Synchronize Methods
    
    var _delay: Double?
    var _sycQueue = [Int]()
    var _syncTimer: NSTimer?
    
    func syncTimeUp() { //The timeUp function is a selector, which must be a public function
        self._syncTimer?.invalidate()
        self._sync()
    }
    
    func _sync(){
        if self._sycQueue.isEmpty{
            self._doSync()
        }else{
            self._sycQueue[0] = 1
        }
    }
    
    private func _doSync(){
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
                if !self._sycQueue.isEmpty {
                    self._sycQueue.removeAll()
                    self._syncDataset(NoteServiceConstants.SYNCHRONIZE_DELAY)
                }
                return nil
            }
        }
    }
    
    func _syncDataset(delay:Double) {
        self._syncTimer?.invalidate()
        _syncTimer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: #selector(NoteService.syncTimeUp), userInfo: nil, repeats: true)
    }
    
    
    // MARK: Public Modify methods
    func canAdd(houseId: String) -> Bool {
        return self.getAllCount(houseId) < NoteServiceConstants.NOTE_MAX_SIZE
    }
    
    func addNote(houseId: String, title: String) {
        Log.debug("addNote houseId=\(houseId), title=\(title)")
        if self.canAdd(houseId) {
            var jsonObj: [String : AnyObject] = [:]
            jsonObj["id"] = NSUUID().UUIDString
            jsonObj["title"] = title
            jsonObj["houseId"] = houseId
            self._add(jsonObj)
        }
    }
    
    func deleteNote(id: String) {
        self._delete(id)
    }
    
    func getNote(id:String) -> Note?{
        return self.dao.get(id)
    }
    
    func getAll(houseId: String) -> [Note]?{
        return self.dao.getByHouseId(houseId)
    }
    
    func getAllCount(houseId: String) -> Int {
        var count = 0
        if let items = self.getAll(houseId) {
            count = items.count
        }
        return count
    }
    
    func isExist(id: String) -> Bool{
        return self.dao.isExist(id)
    }
    
}