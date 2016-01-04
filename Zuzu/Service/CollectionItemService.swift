//
//  CollectionItemService.swift
//  Zuzu
//
//  Created by eechih on 1/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import AWSCore
import AWSCognito
import SwiftyJSON

class CollectionItemService: NSObject
{
    let dao = CollectionHouseItemDao.sharedInstance
    
    let datasetName = "MyCollection2"
    
    var dataset: AWSCognitoDataset?
    
    var entityName: String{
        return self.dao.entityName
    }
    
    class var sharedInstance: CollectionItemService {
        struct Singleton {
            static let instance = CollectionItemService()
        }
        
        Singleton.instance.getDataset()
        
        return Singleton.instance
    }
    
    func getDataset() -> AWSCognitoDataset? {
        
        if self.dataset != nil {
            return self.dataset
        }

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        
        for dataset: AnyObject in datasets {
            let datasetMetadata: AWSCognitoDatasetMetadata = dataset as! AWSCognitoDatasetMetadata
            if datasetMetadata.name == self.datasetName {
                if let _dataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetMetadata.name) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.dataset = _dataset
                    return _dataset
                }
            }
        }
        
        
        datasets.append(AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName))
        
        var tasks: [AWSTask] = []
        
        for dataset in datasets {
            tasks.append(AWSCognito.defaultCognito().openOrCreateDataset(dataset.name).synchronize())
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
                                }
                            }
                        }
                    }
                }
                return nil
        }
        
        return self.dataset
    }
    
    func synchronize(dataset: AWSCognitoDataset?) {
        
        if dataset != nil {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset!.synchronize().continueWithBlock {
                (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
        }
        else if let dataset: AWSCognitoDataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetName) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset.synchronize().continueWithBlock {
                (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
        } 
        
    }
    
    func syncFromCloud() {
        let dataset: AWSCognitoDataset? = AWSCognito.defaultCognito().openOrCreateDataset(datasetName)
        if let temp = dataset?.getAllRecords() as? [AWSCognitoRecord] {
            var records: [AWSCognitoRecord] = temp.filter {
                return $0.dirty || ($0.data.string() != nil && $0.data.string().characters.count != 0)
            }
            
            var items: [AnyObject] = []
            for record: AWSCognitoRecord in records {
                
                //items.append(JSON(data: record.data))
                
            }
            self.dao.addAll(items)
        }
    }
    
    func syncAddOrUpdateToCloud(id: String) {
        if let item: CollectionHouseItem = self.getItem(id) {
//            if let dataset: AWSCognitoDataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetName) {
//                dataset.setString(" harry test ", forKey: item.id)
//                synchronize(dataset)
//            }
            let value: String = item.toCognitoRecordValue()
            
            //let value = "harry test 333"
            if let dataset: AWSCognitoDataset = self.getDataset() {
                dataset.setString(value, forKey: item.id)
                synchronize(dataset)
                
            }
        }
    }
    
    func syncDeleteToCloud(id: String) {
//        if let dataset: AWSCognitoDataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetName) {
//            dataset.removeObjectForKey(id)
//            synchronize(dataset)
//        }
        
        if let dataset: AWSCognitoDataset = self.getDataset() {
            dataset.removeObjectForKey(id)
            synchronize(dataset)
        }
    }
    
    func addItem(item: AnyObject) {
        self.dao.add(item, isCommit: true)
        self.syncAddOrUpdateToCloud(item.valueForKey("id") as! String)
    }
    
    func addAll(items: [AnyObject]) {
        self.dao.addAll(items)
        for item in items {
            self.syncAddOrUpdateToCloud(item.valueForKey("id") as! String)
        }
    }
    
    func deleteItem(item: CollectionHouseItem) {
        self.dao.deleteByID(item.id)
        self.syncDeleteToCloud(item.id)
    }
    
    func deleteItemById(id: String) {
        self.dao.deleteByID(id)
        self.syncDeleteToCloud(id)
    }
    
    func updateItem(item: CollectionHouseItem, dataToUpdate: [String: AnyObject]) {
        self.dao.updateByID(item.id, dataToUpdate: dataToUpdate)
        self.syncAddOrUpdateToCloud(item.id)
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
    
    
}