//
//  SearchHistoryDataStore.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

protocol SearchCriteriaDataStore: class {
    func saveSearchCriteria(criteria: SearchCriteria)
    func loadSearchCriteria() -> SearchCriteria?
    func clear()
}

/// Data Store for Search Criteria
class UserDefaultsSearchCriteriaDataStore: SearchCriteriaDataStore {

    static let instance = UserDefaultsSearchCriteriaDataStore()

    static let userDefaultsKey = "SearchCriteria"

    class func getInstance() -> UserDefaultsSearchCriteriaDataStore {
        return UserDefaultsSearchCriteriaDataStore.instance
    }

    func saveSearchCriteria(criteria: SearchCriteria) {
        //Save selection to user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(criteria)
        userDefaults.setObject(data, forKey: UserDefaultsSearchCriteriaDataStore.userDefaultsKey)
    }

    func loadSearchCriteria() -> SearchCriteria? {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsSearchCriteriaDataStore.userDefaultsKey) as? NSData

        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? SearchCriteria
    }

    func clear() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsSearchCriteriaDataStore.userDefaultsKey)
    }
}

/// Data Store for Radar Criteria
class UserDefaultsRadarCriteriaDataStore: SearchCriteriaDataStore {

    static let instance = UserDefaultsRadarCriteriaDataStore()

    static let userDefaultsKey = "RadarCriteria"

    class func getInstance() -> UserDefaultsRadarCriteriaDataStore {
        return UserDefaultsRadarCriteriaDataStore.instance
    }

    func saveSearchCriteria(criteria: SearchCriteria) {
        //Save selection to user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(criteria)
        userDefaults.setObject(data, forKey: UserDefaultsRadarCriteriaDataStore.userDefaultsKey)
    }

    func loadSearchCriteria() -> SearchCriteria? {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsRadarCriteriaDataStore.userDefaultsKey) as? NSData

        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? SearchCriteria
    }

    func clear() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsRadarCriteriaDataStore.userDefaultsKey)
    }
}
