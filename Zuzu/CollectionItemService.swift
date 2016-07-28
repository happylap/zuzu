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

class CollectionItemService: NSObject {
    let dao = CollectionHouseItemDao.sharedInstance

    struct CollectionItemConstants {
        static let MYCOLLECTION_MAX_SIZE = 60
    }

    class var sharedInstance: CollectionItemService {
        struct Singleton {
            static let instance = CollectionItemService()
        }

        return Singleton.instance
    }

    func start() {
        let center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self,
                           selector: #selector(NoteService.didSyncFromCognitoNotification(_:)),
                           name: SyncFromCognitoNotification,
                           object:nil)
    }

    // MARK: Notifications

    func didSyncFromCognitoNotification(aNotification: NSNotification) {

        dispatch_async(dispatch_get_main_queue()) {
            Log.enter()

            if let modifyingKeys: [String] = aNotification.userInfo?["keys"] as? [String] {
                if modifyingKeys.count > 0 {

                    if let dataset: AWSCognitoDataset = aNotification.object as? AWSCognitoDataset {
                        if dataset.name != CognitoDatasetType.Collection.name() {
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
                                    let id = collectionItem.id
                                    if !dirtyKeys.contains(id) {
                                        Log.debug("Sync To CoreData >>> DeleteItemByID: \(id)")
                                        self.dao.safeDeleteByID(id)
                                    }
                                }
                            }

                            // Delete collectionItem by modifyingKey
                            for modifyingKey: String in modifyingKeys {
                                Log.debug("Sync To CoreData >>> DeleteItemByKey: \(modifyingKey)")
                                self.dao.safeDeleteByID(modifyingKey)
                            }


                            // Add collectionItem if dirtyKey in modifyingKeys
                            for dirtyRecord: AWSCognitoRecord in dirtyRecords {
                                let dirtyKey = dirtyRecord.recordId
                                if modifyingKeys.contains(dirtyKey) {
                                    //Log.debug("%@ dirtyRecord: \(dirtyRecord)", self)

                                    let JSONString = dirtyRecord.data.string()
                                    let collectionItem: CollectionHouseItem? = Mapper<CollectionHouseItem>().map(JSONString)

                                    if collectionItem != nil {
                                        Log.debug("Sync To CoreData >>> AddItem ID: \(collectionItem!.id)")
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

    // MARK: Public Modify methods
    func canAdd() -> Bool {
        return self.getAllCount() < CollectionItemConstants.MYCOLLECTION_MAX_SIZE
    }

    func addItem(obj: AnyObject) {
        Log.enter()

        if self.canAdd() {
            if let id = obj.valueForKey("id") as? String {
                self.dao.add(obj, isCommit: true)
                if let item: CollectionHouseItem = self.getItem(id) {
                    if let JSONString = Mapper().toJSONString(item) {
                        CognitoSyncService.sharedInstance.doAdd(CognitoDatasetType.Collection, key: id, value: JSONString)
                    }
                }
            }
        }
        Log.exit()
    }

    func updateItem(item: CollectionHouseItem, dataToUpdate: [String: AnyObject]) {
        Log.enter()

        let id = item.id

        self.dao.updateByID(id, dataToUpdate: dataToUpdate)

        if let item: CollectionHouseItem = self.getItem(id) {
            if let JSONString = Mapper().toJSONString(item) {
                CognitoSyncService.sharedInstance.doSet(CognitoDatasetType.Collection, key: id, value: JSONString)
            }
        }
        Log.exit()
    }

    func deleteItemById(id: String) {
        Log.enter()
        self.dao.safeDeleteByID(id)
        CognitoSyncService.sharedInstance.doDel(CognitoDatasetType.Collection, key: id)

        NoteService.sharedInstance.deleteByHouseId(id)
        Log.exit()
    }

    func getItem(id: String) -> CollectionHouseItem? {
        return self.dao.get(id) as? CollectionHouseItem
    }

    func getAll() -> [CollectionHouseItem]? {
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

    func isExist(id: String) -> Bool {
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

        HouseDataRequestService.getInstance().searchById(id) {
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

    // MARK: Check Off Shelf

    func isOffShelf(id: String, handler: (offShelf: Bool) -> Void) {

        let _cacheName: String = "OFF_SHELF_CACHE"
        let _cacheTime: Double = 12 * 60 * 60 //12 hours
        var _hitCache: Bool = false

        do {
            let cache = try Cache<NSString>(name: _cacheName)

            ///Return cached data if there is cached data
            if let result = cache.objectForKey(id) as? String {

                //Log.debug("Hit Cache for item: Id: \(id), OffShelf: \(result)")

                _hitCache = true

                var _offShelf: Bool = false
                if result == "Y" {
                    _offShelf = true
                }

                handler(offShelf: _offShelf)
            }

        } catch _ {
            Log.debug("Something went wrong with the cache")
        }

        if(!_hitCache) {
            Log.debug("HouseDataRequester SearchById: \(id)")

            HouseDataRequestService.getInstance().searchById(id) { (result, error) -> Void in

                if let error = error {
                    Log.debug("Cannot get remote data \(error.localizedDescription)")
                    handler(offShelf: false)
                    return
                }

                var _offShelf: Bool = false

                if result == nil {
                    _offShelf = true
                }

                ///Try to cache the house detail response
                do {
                    let cache = try Cache<NSString>(name: _cacheName)
                    let cacheData = _offShelf ? "Y" : "N"
                    cache.setObject(cacheData, forKey: id, expires: CacheExpiry.Seconds(_cacheTime))

                } catch _ {
                    Log.debug("Something went wrong with the cache")
                }

                //Log.debug("HouseDataRequester SearchById: \(id), OffShelf: \(_offShelf)")
                handler(offShelf: _offShelf)
            }
        }
    }

    func isPriceCut(id: String, handler: (priceCut: Bool) -> Void) {

        let _cacheName: String = "PRICE_CUT_CACHE"
        let _cacheTime: Double = 12 * 60 * 60 // 12 hours
        var _hitCache: Bool = false

        do {
            let cache = try Cache<NSString>(name: _cacheName)

            ///Return cached data if there is cached data
            if let result = cache.objectForKey(id) as? String {

                //Log.debug("Hit Cache for item: Id: \(id), PriceCut: \(result)")

                _hitCache = true

                var _priceCut: Bool = false
                if result == "Y" {
                    _priceCut = true
                }

                handler(priceCut: _priceCut)
            }

        } catch _ {
            Log.debug("Something went wrong with the cache")
        }

        if(!_hitCache) {
            Log.debug("HouseDataRequester SearchById: \(id)")

            HouseDataRequestService.getInstance().searchById(id) { (result, error) -> Void in

                if let error = error {
                    Log.debug("Cannot get remote data \(error.localizedDescription)")

                    handler(priceCut: false)
                    return
                }

                var _priceCut: Bool = false

                if let item = result,
                    let price = item.valueForKey("price") as? Int,
                    let previousPrice = item.valueForKey("previous_price") as? Int {
                        if price < previousPrice {
                            _priceCut = true
                        }
                }

                ///Try to cache the house detail response
                do {
                    let cache = try Cache<NSString>(name: _cacheName)
                    let cacheData = _priceCut ? "Y" : "N"
                    cache.setObject(cacheData, forKey: id, expires: CacheExpiry.Seconds(_cacheTime))

                } catch _ {
                    Log.debug("Something went wrong with the cache")
                }

                //Log.debug("HouseDataRequester SearchById: \(id), PriceCut: \(_priceCut)")
                handler(priceCut: _priceCut)
            }
        }
    }
}
