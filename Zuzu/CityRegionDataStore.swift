//
//  CityRegionDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/19.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class Region: NSObject, NSCoding {
    var code:Int
    var name:String
    
    init(code:Int, name: String) {
        self.code = code
        self.name = name
    }
    
    convenience required init?(coder decoder: NSCoder) {
        let code = decoder.decodeIntegerForKey("code") as Int
        let name = decoder.decodeObjectForKey("name") as? String ?? ""
        
        self.init(code: code, name: name)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        return (object as? Region)?.code == code
    }
    
    //    override var hashValue : Int {
    //        get {
    //            return code.hashValue
    //        }
    //    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(code, forKey:"code")
        aCoder.encodeObject(name, forKey:"name")
    }
    
    override var description: String {
        let string = "Region: code = \(code), name = \(name)"
        return string
    }
}

//func ==(lhs: Region, rhs: Region) -> Bool {
//    return  lhs.hashValue == rhs.hashValue
//}

class City: NSObject, NSCoding {
    var code:Int
    var name:String
    var regions:[Region]
    
    init(code:Int, name: String, regions:[Region]) {
        self.code = code
        self.name = name
        self.regions = regions
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        let code = decoder.decodeIntegerForKey("code") as Int
        let name = decoder.decodeObjectForKey("name") as? String ?? ""
        let regions = decoder.decodeObjectForKey("regions") as? [Region] ?? [Region]()
        
        self.init(code: code, name: name, regions: regions)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        return (object as? City)?.code == code
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(code, forKey:"code")
        aCoder.encodeObject(name, forKey:"name")
        aCoder.encodeObject(regions, forKey:"regions")
    }
    
    override var description: String {
        let string = "City: code = \(code), name = \(name), regions = \(regions)"
        return string
    }
}

protocol CityRegionDataStore: class {
    func saveSelectedCityRegions(cities: [City])
    func loadSelectedCityRegions() -> [City]?
    func clearSelectedCityRegions()
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
    
    func clearSelectedCityRegions() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsCityRegionDataStore.userDefaultsKey)
    }
}