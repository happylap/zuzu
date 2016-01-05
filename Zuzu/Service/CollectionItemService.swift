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
import ObjectMapper

class CollectionItemService: NSObject
{
    let dao = CollectionHouseItemDao.sharedInstance
    
    let datasetName = "MyCollection"
    
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
    
    func synchronize() {
        if let dataset = self.getDataset() {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            dataset.synchronize().continueWithBlock {
                (task) -> AnyObject! in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                return nil
            }
        }
    }
    
    func syncFromCloud() {
//        synchronize()
//        
//        if let dataset = self.getDataset() {
//            if let temp = dataset.getAllRecords() as? [AWSCognitoRecord] {
//                dao.deleteAll()
//                self.dao.commit()
//                
//                let records: [AWSCognitoRecord] = temp.filter {
//                    return $0.dirty || ($0.data.string() != nil && $0.data.string().characters.count != 0)
//                }
//                for record: AWSCognitoRecord in records {
//                    let JSONString = record.data.string()
//                    print("\(JSONString)")
//                    print("isDeleted: \(record.isDeleted())")
//                    if let item: CollectionHouseItem = Mapper<CollectionHouseItem>().map(JSONString) {
//                        print("\(item)")
//                        //self.dao.add(item, isCommit: true)
//                    }
//                }
//                self.dao.commit()
//            }
//        }
    }
    
    func syncAddOrUpdateToCloud(id: String) {
        if let item: CollectionHouseItem = self.getItem(id) {
            /*
            if let jsonString = Mapper().toJSONString(item) {
                NSLog("%@ jsonString: \(jsonString)", self)
                if let dataset: AWSCognitoDataset = self.getDataset() {
                    //dataset.setString(value, forKey: item.id)
                    dataset.setString(jsonString, forKey: item.id)
                    synchronize()
                }
            }
            */
            if let dataset: AWSCognitoDataset = self.getDataset() {
                dataset.setString(Mapper().toJSONString(item), forKey: item.id)
                synchronize()
            }
            
        }
    }
    
    func syncDeleteToCloud(id: String) {
        if let dataset: AWSCognitoDataset = self.getDataset() {
            dataset.removeObjectForKey(id)
            synchronize()
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