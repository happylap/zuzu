//
//  CityRegionDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/19.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

protocol CityRegionDataSource: class {
    func setSelectedCityRegions(cities: [City])
    func getSelectedCityRegions() -> [City]?
}

class UserDefaultsCityRegionDataSource: CityRegionDataSource {
    
    static let instance = UserDefaultsCityRegionDataSource()
    
    static let userDefaultsKey = "selectedRegion"
    
    static func getInstance() -> UserDefaultsCityRegionDataSource {
        return UserDefaultsCityRegionDataSource.instance
    }
    
    func setSelectedCityRegions(cities: [City]) {
        //Save selection to user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(cities)
        userDefaults.setObject(data, forKey: UserDefaultsCityRegionDataSource.userDefaultsKey)
    }
    
    // MARK: - CityRegionDataSource
    func getSelectedCityRegions() -> [City]? {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsCityRegionDataSource.userDefaultsKey) as? NSData
        
        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [City]
    }
}