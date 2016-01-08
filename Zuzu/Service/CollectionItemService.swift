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

class CollectionItemService: NSObject
{
    let dao = CollectionHouseItemDao.sharedInstance
    
    let datasetName = "MyCollection"
    
    var parentViewController: UIViewController?
    
    var entityName: String{
        return self.dao.entityName
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
            self._syncDataset(dataset)
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
            self._syncDataset(dataset)
        }
    }
    
    func _delete(id: String) {
        self.dao.safeDeleteByID(id)
        // Delete item from Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            dataset.removeObjectForKey(id)
            self._syncDataset(dataset)
        }
    }
    
    // MARK: Dataset methods
    
    func _syncDataset(dataset: AWSCognitoDataset) {
        dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
            return nil
        }
    }
    
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

    
    // MARK: Synchronize Timer
    var _timer: NSTimer?
    var _flag = true
    var _isStillSync = false
    
    func _timeUp() {
        self._timer?.invalidate()
        self._flag = true
    }
    
    func resetSynchronizeTimer() {
        self._timer?.invalidate()
        self._flag = false
        _timer = NSTimer.scheduledTimerWithTimeInterval(Constants.MYCOLLECTION_SYNCHRONIZE_INTERVAL_TIME, target: self, selector: "_timeUp", userInfo: nil, repeats: true)
    }
    
    func canSynchronize() -> Bool {
        return self._flag
    }
    
    
    // MARK: Public methods
    
    func synchronize(theViewController: UIViewController) {
        if !self.canSynchronize() {
            return
        }
        self.parentViewController = theViewController
        self.resetSynchronizeTimer()
        
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            self._syncDataset(dataset)
        }
    }
    
    func addItem(item: AnyObject) {
        self._add([item])
    }
    
    func addAll(items: [AnyObject]) {
        self._add(items)
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
}