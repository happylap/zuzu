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
    
    var dataset: AWSCognitoDataset?
    
    var isSpin = false
    
    var entityName: String{
        return self.dao.entityName
    }
    
    class var sharedInstance: CollectionItemService {
        struct Singleton {
            static let instance = CollectionItemService()
        }
        return Singleton.instance
    }
    
    // MARK: Private methods
    
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
            
            // Synchronize to AWS
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
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
            
            // Synchronize to AWS
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
        }
    }
    
    func _delete(id: String) {
        self.dao.deleteByID(id)
        
        // Delete item from Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset() {
            dataset.removeObjectForKey(id)
        
            // Synchronize to AWS
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
        }
    }
    
    func _initMyCollectionDataSet(){
        
        var datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        
        if self.dataset == nil{
            datasets.append(AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName))
        }
        
        var tasks: [AWSTask] = []
        
        for dataset in datasets {
            if dataset.name == self.datasetName {
                tasks.append(AWSCognito.defaultCognito().openOrCreateDataset(dataset.name).synchronizeOnConnectivity())
            }
        }
        
        AWSTask(forCompletionOfAllTasks: tasks).continueWithBlock { (task) -> AnyObject! in
            return AWSCognito.defaultCognito().refreshDatasetMetadata()
            }.continueWithBlock { (task) -> AnyObject! in
                dispatch_async(dispatch_get_main_queue()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    if task.error != nil {
                        //self.errorAlert(task.error.description)
                    } else {
                        datasets = AWSCognito.defaultCognito().listDatasets()
                        
                        for dataset: AnyObject in datasets {
                            let datasetMetadata: AWSCognitoDatasetMetadata = dataset as! AWSCognitoDatasetMetadata
                            if datasetMetadata.name == self.datasetName {
                                if let dataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetMetadata.name) {
                                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                                    self.dataset = dataset
                                    if let temp = dataset.getAllRecords() as? [AWSCognitoRecord] {
                                        self.dao.deleteAll()
                                        
                                        let records: [AWSCognitoRecord] = temp.filter {
                                            return $0.dirty || ($0.data.string() != nil && $0.data.string().characters.count != 0)
                                        }
                                        for record: AWSCognitoRecord in records {
                                            let JSONString = record.data.string()
                                            Mapper<CollectionHouseItem>().map(JSONString)
                                        }
                                        self.dao.commit()
                                    }
                                }
                            }
                        }
                    }
                    
                    if UIApplication.sharedApplication().networkActivityIndicatorVisible == true{
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                    
                    if self.isSpin == true{
                        self.isSpin = false
                        LoadingSpinner.shared.stop()
                    }
                }
                return nil
        }
        
    }
    
    func _openOrCreateDataset() -> AWSCognitoDataset? {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        
        for dataset: AnyObject in datasets {
            let datasetMetadata: AWSCognitoDatasetMetadata = dataset as! AWSCognitoDatasetMetadata
            if datasetMetadata.name == self.datasetName {
                if let _dataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetMetadata.name) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.dataset = _dataset
                }
            }
        }
        
        if self.dataset == nil {
            self._initMyCollectionDataSet()
        }
        
        return self.dataset
    }
    
    // MARK: Synchronize Timer
    
    var _timer: NSTimer?
    var _flag = true
    
    func _timeUp() {
        self._timer?.invalidate()
        self._flag = true
    }
    
    func resetSynchronizeTimer() {
        self._timer?.invalidate()
        self._flag = false
        _timer = NSTimer.scheduledTimerWithTimeInterval(Constants.COGNITO_SYNCHRONIZE_INTERVAL_TIME, target: self, selector: "_timeUp", userInfo: nil, repeats: true)
    }
    
    func canSynchronize() -> Bool {
        return self._flag
    }
    
    // MARK: Public methods
    
    func synchronize(theViewController: UIViewController) {
        if !self.canSynchronize() {
            return
        }
        
        self.resetSynchronizeTimer()
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(theViewController.view)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.isSpin = true
        
        self._initMyCollectionDataSet()
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