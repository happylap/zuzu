//
//  CognitoSyncService.swift
//  Zuzu
//
//  Created by Harry Yeh on 6/7/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognito
import SwiftyJSON
import ObjectMapper
import SwiftDate

private let Log = Logger.defaultLogger

enum CognitoDatasetType: String {
    case Collection = "MyCollection"
    case Note = "Note"

    func name() -> String {
        return self.rawValue
    }

    static let all = [Collection, Note]
}

protocol CognitoSynchronizeObserverDelegate:class {
    func onStartSynchronize()

    func onEndSynchronize()

    func onFailToSynchronize()
}

let SyncFromCognitoNotification = "SyncFromCognitoNotification"


class CognitoSyncService: NSObject {

    var delegates = [CognitoSynchronizeObserverDelegate]()

    var syncQueue = [CognitoDatasetType]()

    class var sharedInstance: CognitoSyncService {
        struct Singleton {
            static let instance = CognitoSyncService()
        }

        return Singleton.instance
    }

    func register(delegate: CognitoSynchronizeObserverDelegate) {
        self.delegates.append(delegate)
    }

    func start() {
        Log.enter()
        let center: NSNotificationCenter = NSNotificationCenter.defaultCenter()

        center.addObserver(self, selector: #selector(CognitoSyncService.didFinishUserLoginNotification(_:)),
                           name: UserLoginNotification,
                           object:nil)

        center.addObserver(self, selector: #selector(CognitoSyncService.startSynchronizeNotification(_:)),
                           name: AWSCognitoDidStartSynchronizeNotification,
                           object:nil)


        center.addObserver(self, selector: #selector(CognitoSyncService.endSynchronizeNotification(_:)),
                           name: AWSCognitoDidEndSynchronizeNotification,
                           object:nil)


        center.addObserver(self, selector: #selector(CognitoSyncService.failToSynchronizeNotification(_:)),
                           name: AWSCognitoDidFailToSynchronizeNotification,
                           object:nil)


        center.addObserver(self, selector: #selector(CognitoSyncService.changeRemoteValueNotification(_:)),
                           name: AWSCognitoDidChangeRemoteValueNotification,
                           object:nil)


        center.addObserver(self, selector: #selector(CognitoSyncService.changeLocalValueFromRemoteNotification(_:)),
                           name: AWSCognitoDidChangeLocalValueFromRemoteNotification,
                           object:nil)
        Log.exit()
    }


    func didFinishUserLoginNotification(aNotification: NSNotification) {
        Log.enter()
        self.doSyncAll()
        Log.exit()
    }

    func startSynchronizeNotification(aNotification: NSNotification) {
        Log.enter()

        if let datasetType = self._getDatasetType(aNotification) {
            self._appendToSyncQueue(datasetType)
        }

        if self.syncQueue.count == 1 {
            for delegate in delegates {
                Log.debug("delegate.onStartSynchronize")
                delegate.onStartSynchronize()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        Log.exit()
    }

    func endSynchronizeNotification(aNotification: NSNotification) {
        Log.enter()

        if let datasetType = self._getDatasetType(aNotification) {
            self._removeFromSyncQueue(datasetType)
        }

        if self.syncQueue.count == 0 {
            for delegate in delegates {
                Log.debug("delegate.onEndSynchronize")
                delegate.onEndSynchronize()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        Log.exit()
    }

    func failToSynchronizeNotification(aNotification: NSNotification) {
        Log.enter()

        if let datasetType = self._getDatasetType(aNotification) {
            self._removeFromSyncQueue(datasetType)
        }

        if self.syncQueue.count == 0 {
            for delegate in delegates {
                Log.debug("delegate.onEndSynchronize")
                delegate.onEndSynchronize()
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        Log.exit()
    }

    func changeRemoteValueNotification(aNotification: NSNotification) {
        Log.enter()
        Log.exit()
    }

    func changeLocalValueFromRemoteNotification(aNotification: NSNotification) {
        Log.enter()
        NSNotificationCenter.defaultCenter().postNotificationName(SyncFromCognitoNotification, object: aNotification.object,
                                                                  userInfo: aNotification.userInfo)
        Log.exit()
    }


    // MARK: Dataset methods

    func _getDatasetType(aNotification: NSNotification) -> CognitoDatasetType? {
        Log.enter()
        if let dataset: AWSCognitoDataset = aNotification.object as? AWSCognitoDataset {
            for datasetType in CognitoDatasetType.all {
                if datasetType.name() == dataset.name {
                    Log.debug("return \(datasetType)")
                    return datasetType
                }
            }
        }
        Log.debug("return nil")
        return nil
    }

    func _getDataSet(datasetType: CognitoDatasetType) -> AWSCognitoDataset? {
        Log.enter()
        let datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
        for dataset in datasets {
            if dataset.name == datasetType.name() {
                if let dataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetType.name()) {
                    Log.debug("return \(dataset)")
                    return dataset
                }
            }
        }
        Log.debug("return nil")
        return nil
    }

    func _openOrCreateDataset(datasetType: CognitoDatasetType) -> AWSCognitoDataset {
        Log.enter()
        var dataset = self._getDataSet(datasetType)

        if dataset == nil {
            dataset = AWSCognito.defaultCognito().openOrCreateDataset(datasetType.name())
            var datasets: [AnyObject] = AWSCognito.defaultCognito().listDatasets()
            datasets.append(dataset!)
        }

        Log.debug("return \(dataset)")
        return dataset!
    }

    func _appendToSyncQueue(datasetType: CognitoDatasetType) {
        Log.enter()
        if !self.syncQueue.contains(datasetType) {
            self.syncQueue.append(datasetType)
        }
        Log.debug("syncQueue count: \(self.syncQueue.count)")
    }

    func _removeFromSyncQueue(datasetType: CognitoDatasetType) {
        Log.enter()
        for (index, value) in self.syncQueue.enumerate() {
            if value == datasetType {
                self.syncQueue.removeAtIndex(index)
            }
        }
        Log.debug("syncQueue count: \(self.syncQueue.count)")
    }

    // MARK: Private methods

    func _sync(datasetType: CognitoDatasetType) {
        Log.enter()
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(datasetType) {
            dataset.synchronizeOnConnectivity().continueWithBlock { (task) -> AnyObject! in
                return nil
            }
        }
        Log.exit()
    }

    // MARK: Public methods

    func doSyncAll() {
        Log.enter()
        for datasetType in CognitoDatasetType.all {
            self._sync(datasetType)
        }
        Log.exit()
    }

    func doSync(datasetType: CognitoDatasetType) {
        Log.enter()
        self._sync(datasetType)
        Log.exit()
    }

    func doAdd(datasetType: CognitoDatasetType, key: String, value: String) {
        Log.enter()
        self.doSet(datasetType, key: key, value: value)
        Log.exit()
    }

    func doSet(datasetType: CognitoDatasetType, key: String, value: String) {
        Log.enter()
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(datasetType) {
            dataset.setString(value, forKey: key)
        }
        Log.exit()
    }

    func doDel(datasetType: CognitoDatasetType, key: String) {
        Log.enter()
        if let dataset: AWSCognitoDataset = self._openOrCreateDataset(datasetType) {
            dataset.removeObjectForKey(key)
        }
        Log.exit()
    }

}
