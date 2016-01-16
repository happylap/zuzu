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

class CollectionItemService: NSObject
{
    let dao = CollectionHouseItemDao.sharedInstance
    
    let datasetName = "MyCollection"
    
    var parentViewController: UIViewController?
    
    var entityName: String{
        return self.dao.entityName
    }
    
    struct CollectionItemConstants {
        static let MYCOLLECTION_MAX_SIZE = 60
        static let ENTER_TIMER_INTERVAL = 300.0  // Unit: second
        static let SYNCHRONIZE_DELAY_FOR_ADD = 3.0  // Unit: second
        static let SYNCHRONIZE_DELAY = 1.0  // Unit: second
    }
    
    class var sharedInstance: CollectionItemService {
        struct Singleton {
            static let instance = CollectionItemService()
        }
        
        Singleton.instance.registerAWSCognitoNotifications()
        
        return Singleton.instance
    }
    
    // MARK: Private methods for modify items
    
    func _add(items: [AnyObject]) {
        self.dao.addAll(items)
        
        // Add item to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            for obj in items {
                let id = obj.valueForKey("id") as! String
                if let item: CollectionHouseItem = self.getItem(id) {
                    let JSONString = Mapper().toJSONString(item)
                    dataset.setString(JSONString, forKey: id)
                }
            }
            self._syncDataset(CollectionItemConstants.SYNCHRONIZE_DELAY_FOR_ADD)
        }
    }
    
    func _update(id: String, dataToUpdate: [String: AnyObject]) {
        self.dao.updateByID(id, dataToUpdate: dataToUpdate)
        
        // Update item to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            if let item: CollectionHouseItem = self.getItem(id) {
                let JSONString = Mapper().toJSONString(item)
                dataset.setString(JSONString, forKey: id)
            }
            self._syncDataset(CollectionItemConstants.SYNCHRONIZE_DELAY)
        }
    }
    
    func _delete(id: String) {
        self.dao.safeDeleteByID(id)
        // Delete item from Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            dataset.removeObjectForKey(id)
            self._syncDataset(CollectionItemConstants.SYNCHRONIZE_DELAY)
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
    
    
    // MARK: AWSCognito Notifications
    
    var registerAWSCognitoNotification = false
    
    func registerAWSCognitoNotifications() {
        
        if registerAWSCognitoNotification == true {
            return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "startSynchronizeNotification:",
            name: AWSCognitoDidStartSynchronizeNotification,
            object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "endSynchronizeNotification:",
            name: AWSCognitoDidEndSynchronizeNotification,
            object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "failToSynchronizeNotification:",
            name: AWSCognitoDidFailToSynchronizeNotification,
            object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "changeRemoteValueNotification:",
            name: AWSCognitoDidChangeRemoteValueNotification,
            object:nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "changeLocalValueFromRemoteNotification:",
            name: AWSCognitoDidChangeLocalValueFromRemoteNotification,
            object:nil)
        
        registerAWSCognitoNotification = true
    }
    
    func startSynchronizeNotification(aNotification: NSNotification) {
        NSLog("%@ AWSCognito startSynchronizeNotification", self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func endSynchronizeNotification(aNotification: NSNotification) {
        NSLog("%@ AWSCognito endSynchronizeNotification", self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func failToSynchronizeNotification(aNotification: NSNotification) {
        NSLog("%@ AWSCognito failToSynchronizeNotification", self)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func changeRemoteValueNotification(aNotification: NSNotification) {
        NSLog("%@ AWSCognito changeRemoteValueNotification", self)
        
    }
    
    func changeLocalValueFromRemoteNotification(aNotification: NSNotification) {
        NSLog("%@ AWSCognito changeRemoteValueNotification", self)
 
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
                            if let collectionItems = self.getAll() {
                                for collectionItem: CollectionHouseItem in collectionItems {
                                    NSLog("%@ collectionItem title: \(collectionItem.title)", self)
                                    let id = collectionItem.id
                                    if !dirtyKeys.contains(id) {
                                        self.dao.safeDeleteByID(id)
                                    }
                                }
                            }
                            
                            // Delete collectionItem by modifyingKey
                            for modifyingKey: String in modifyingKeys {
                                self.dao.safeDeleteByID(modifyingKey)
                            }
                            
                            
                            // Add collectionItem if dirtyKey in modifyingKeys
                            for dirtyRecord: AWSCognitoRecord in dirtyRecords {
                                let dirtyKey = dirtyRecord.recordId
                                if modifyingKeys.contains(dirtyKey) {
                                    //NSLog("%@ dirtyRecord: \(dirtyRecord)", self)
                                    let JSONString = dirtyRecord.data.string()
                                    Mapper<CollectionHouseItem>().map(JSONString)
                                }
                            }
                            
                            self.dao.commit()
                        }
                    }
                }
            }
            LoadingSpinner.shared.stop()
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
                    self._syncDataset(CollectionItemConstants.SYNCHRONIZE_DELAY)
                }
                return nil
            }
        }
    }

    func _syncDataset(delay:Double) {
        self._syncTimer?.invalidate()
        _syncTimer = NSTimer.scheduledTimerWithTimeInterval(delay, target: self, selector: "syncTimeUp", userInfo: nil, repeats: true)
    }

    // MARK: Enter mycollection timer Methods
    
    var _enterTimer: NSTimer?
    var _canEnter = true
    
    func enterTimeUp() { //The timeUp function is a selector, which must be a public function
        self._enterTimer?.invalidate()
        self._canEnter = true
    }
    
    func resetEnterTimer() {
        self._enterTimer?.invalidate()
        self._canEnter = false
        self._enterTimer = NSTimer.scheduledTimerWithTimeInterval(CollectionItemConstants.ENTER_TIMER_INTERVAL, target: self, selector: "enterTimeUp", userInfo: nil, repeats: true)
    }
    
    func canSyncWhenEnter() -> Bool{
        return self._canEnter
    }
    
    // MARK: Public Sync methods
    func sync(){
        if self.canSyncWhenEnter(){
            self._syncDataset(0)
        }
        self.resetEnterTimer()
    }
    
    // MARK: Public Modify methods
    func canAdd() -> Bool {
        return self.getAllCount() < CollectionItemConstants.MYCOLLECTION_MAX_SIZE
    }
    
    func addItem(item: AnyObject) {
        if self.canAdd() {
            self._add([item])
        }
    }
    
    func addAll(items: [AnyObject]) {
        if self.canAdd() {
            self._add(items)
        }
    }
    
    func updateItem(item: CollectionHouseItem, dataToUpdate: [String: AnyObject]) {
        self._update(item.id, dataToUpdate: dataToUpdate)
    }
    
    func deleteItem(item: CollectionHouseItem) {
        self._delete(item.id)
    }
    
    func deleteItemById(id: String) {
        self._delete(id)
    }
    
    func getItem(id:String) -> CollectionHouseItem?{
        return self.dao.get(id) as? CollectionHouseItem
    }
    
    func getAll() -> [CollectionHouseItem]?{
        return self.dao.getAll() as? [CollectionHouseItem]
    }
    
    func getAllCount() -> Int {
        var count = 0
        if let items = self.getAll() {
            count = items.count
        }
        return count
    }
    
    func getIds() -> [String]? {
        var result: [String] = []
        if let allItems = self.getAll() {
            for item: AbstractHouseItem in allItems {
                result.append(item.id)
            }
        }
        return result
    }
    
    func isExist(id: String) -> Bool{
        return self.dao.isExist(id)
    }
    
    func updateContacted(id: String, contacted: Bool) {
        if let item = self.getItem(id) {
            CollectionItemService.sharedInstance.updateItem(item, dataToUpdate: ["contacted": contacted])
        }
    }
    
    func isContacted(id: String) -> Bool {
        if let item = self.getItem(id) {
            return item.contacted
        }
        return false
    }
    
    func isExistInSolr(id: String, theViewController: UIViewController?, handler: (isExist: Bool) -> Void) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if theViewController != nil {
            LoadingSpinner.shared.setImmediateAppear(true)
            LoadingSpinner.shared.setOpacity(0.3)
            LoadingSpinner.shared.startOnView(theViewController!.view)
        }
        
        HouseDataRequester.getInstance().searchById(id) {
            (result, error) -> Void in
            
            var isExist = true
            if result == nil && error == nil {
                isExist = false
            }
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            LoadingSpinner.shared.stop()
            handler(isExist: isExist)
        }
    }
    
    func isOffShelf(id: String, handler: (offShelf: Bool) -> Void) {
        if let collectionItem = self.getItem(id), let collectTime = collectionItem.collectTime {
            if collectTime.isToday() {
                handler(offShelf: false)
                return
            }
            
            self.getOffShelfIds() { (result) -> Void in
                var offShelf = false
                if let offShelfIds = result {
                    offShelf = !offShelfIds.contains(collectionItem.id)
                }
                handler(offShelf: offShelf)
            }
        }
    }
    
    let IDS_FOR_OFF_SHELF_CHECK = "IdsForOffShelfCheck"
    let UPDATE_DATE_FOR_OFF_SHELF_CHECK = "UpdateDtForOffShelfCheck"
    let userDefault = NSUserDefaults.standardUserDefaults()
    
    func getOffShelfIds(handler: (result: [String]?) -> Void) {
        if let ids = self.userDefault.objectForKey(self.IDS_FOR_OFF_SHELF_CHECK) as? [String],
            let updateDt = self.userDefault.objectForKey(self.UPDATE_DATE_FOR_OFF_SHELF_CHECK) as? NSDate {
            if updateDt.isToday() {
                handler(result: ids)
                return
            }
        }
        
        if let collectionIds: [String] = self.getIds() {
            HouseDataRequester.getInstance().searchByIds(collectionIds) { (totalNum, result, error) -> Void in
                
                if let remoteHouseItems = result {
                    var remoteHouseIds = [String]()
                    for remoteHouseItem in remoteHouseItems as [HouseItem] {
                        remoteHouseIds.append(remoteHouseItem.id)
                    }
                    
                    let nsArray: NSArray = NSArray(array: remoteHouseIds)
                    self.userDefault.setObject(nsArray, forKey: self.IDS_FOR_OFF_SHELF_CHECK)
                    self.userDefault.setObject(NSDate(), forKey: self.UPDATE_DATE_FOR_OFF_SHELF_CHECK)
                    self.userDefault.synchronize()
                    
                    handler(result: remoteHouseIds)
                }
                else {
                    if let offShelfIds = self.userDefault.objectForKey(self.IDS_FOR_OFF_SHELF_CHECK) as? [String] {
                        handler(result: offShelfIds)
                    } else {
                        handler(result: nil)
                    }
                }
            }
            return
        }
        
        handler(result: self.userDefault.objectForKey(self.IDS_FOR_OFF_SHELF_CHECK) as? [String])
    }
}