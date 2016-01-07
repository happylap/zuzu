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
    
    // MARK: Private methods for modify items
    
    private func _add(items: [AnyObject]) {
        self.dao.addAll(items)
        
        // Add item to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(false) {
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
    
    private func _update(id: String, dataToUpdate: [String: AnyObject]) {
        self.dao.updateByID(id, dataToUpdate: dataToUpdate)
        
        // Update item to Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(false) {
            if let item: CollectionHouseItem = self.getItem(id) {
                let JSONString = Mapper().toJSONString(item)
                dataset.setString(JSONString, forKey: id)
            }
            self._syncDataset(dataset)
        }
    }
    
    private func _delete(id: String) {
        self.dao.deleteByID(id)
        // Delete item from Cognito
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(false) {
            dataset.removeObjectForKey(id)
            self._syncDataset(dataset)
        }
    }
    
    // MARK: Dataset methods
    
    private func _syncDataset(dataset: AWSCognitoDataset){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            return nil
        }
    }
    
    private func _resyncMyCollectionDataSet(dataset: AWSCognitoDataset){
        var tasks: [AWSTask] = []
        
        tasks.append(dataset.synchronizeOnConnectivity())

        AWSTask(forCompletionOfAllTasks: tasks).continueWithBlock { (task) -> AnyObject! in
            
            self._isStillSync = false
            
            if self._isTimeout() == true{
                return nil
            }
            
            if task.error != nil{
                return nil
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                if let temp = dataset.getAllRecords() as? [AWSCognitoRecord] {
                    self.dao.deleteAll()
                    self.dao.commit()
                    let records: [AWSCognitoRecord] = temp.filter {
                    return $0.dirty || ($0.data.string() != nil && $0.data.string().characters.count != 0)
                    }
                    for record: AWSCognitoRecord in records {
                    let JSONString = record.data.string()
                    Mapper<CollectionHouseItem>().map(JSONString)
                    }
                    self.dao.commit()
                }
                
                self._stopLoading()
            }

            return nil
        }

    }
    
    private func _getDataSet() -> AWSCognitoDataset?{
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        for dataset in datasets {
            if dataset.name == self.datasetName {
                if let dataset = AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    return dataset
                }
            }
        }
        
        return nil
    }
    
    private func _openOrCreateDataset(forceResync: Bool) -> AWSCognitoDataset {
        var dataset = self._getDataSet()
        var resync = forceResync
        if dataset == nil{
            dataset = AWSCognito.defaultCognito().openOrCreateDataset(self.datasetName)
            var datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
            datasets.append(dataset!)
            if forceResync != true{
                return dataset!
            }
            resync = true
        }

        if resync == true{
            self._setTimeout()
            self._resyncMyCollectionDataSet(dataset!)
        }
        
        return dataset!
    }
    
    // MARK: Synchronize Timer
    var _timer: NSTimer?
    var _flag = true
    var _isStillSync = false

    func resetSynchronizeTimer() {
        self._timer?.invalidate()
        self._flag = false
        _timer = NSTimer.scheduledTimerWithTimeInterval(Constants.MYCOLLECTION_SYNCHRONIZE_INTERVAL_TIME, target: self, selector: "timeUp", userInfo: nil, repeats: true)
    }
    
    // timer selector method should not be private
    func timeUp() {
        self._timer?.invalidate()
        self._flag = true
    }

    func canSynchronize() -> Bool {
        return self._flag
    }

    // MARK: Synchronize Timeout
    var _timeoutInterval: NSTimer?
    var _timeoutFlag = false
    
    // timer selector method should not be private
    func timeout() {
        self._timeoutInterval?.invalidate()
        self._timeoutFlag = true
        self._stopLoading()
    }
    
    func _setTimeout(){
        self._timeoutFlag = false
        self._timeoutInterval?.invalidate()
        _timeoutInterval = NSTimer.scheduledTimerWithTimeInterval(Constants.MYCOLLECTION_SYNCHRONIZE_TIMEOUT_INTERVAL_TIME, target: self, selector: "timeout", userInfo: nil, repeats: true)
    }
    
    func _isTimeout() -> Bool {
        return self._timeoutFlag
    }
    
    // MARK: Loading methods
    
    private func _startLoading(theViewController: UIViewController){
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(theViewController.view)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.isSpin = true
    }
    
    private func _stopLoading(){
        if UIApplication.sharedApplication().networkActivityIndicatorVisible == true{
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        if self.isSpin == true{
            self.isSpin = false
            LoadingSpinner.shared.stop()
        }
    }
    
    // MARK: Public methods
    
    func synchronize(theViewController: UIViewController) {
        if !self.canSynchronize() {
            return
        }
        
        if self._isStillSync == true{
            //return
        }
        
        self._isStillSync = true
        self.resetSynchronizeTimer()
        
        self._startLoading(theViewController)
        self._openOrCreateDataset(true)
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