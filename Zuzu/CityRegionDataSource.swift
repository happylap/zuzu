//
//  CityRegionDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/19.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

protocol CityRegionDataStore: class {
    func saveSelectedCityRegions(cities: [City])
    func loadSelectedCityRegions() -> [City]?
}

class UserDefaultsCityRegionDataStore: CityRegionDataStore {
    
    static let instance = UserDefaultsCityRegionDataStore()
    
    static let userDefaultsKey = "selectedRegion"
    
    static func getInstance() -> UserDefaultsCityRegionDataStore {
        return UserDefaultsCityRegionDataStore.instance
    }
    
    func saveSelectedCityRegions(cities: [City]) {
        //Save selection to user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(cities)
        userDefaults.setObject(data, forKey: UserDefaultsCityRegionDataStore.userDefaultsKey)
    }
    
    func loadSelectedCityRegions() -> [City]? {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsCityRegionDataStore.userDefaultsKey) as? NSData
        
        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [City]
    }
}