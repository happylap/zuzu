//
//  SearchHistoryDataStore.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

//func encode<T>(var value: T) -> NSData {
//    return withUnsafePointer(&value) { p in
//        NSData(bytes: p, length: sizeofValue(value))
//    }
//}
//
//func decode<T>(data: NSData) -> T {
//    let pointer = UnsafeMutablePointer<T>.alloc(sizeof(T.Type))
//    data.getBytes(pointer, length: sizeof(T.Type))
//
//    return pointer.move()
//}

public enum SearchType:Int {
    case HistoricalSearch = 0
    case SavedSearch = 1
}

class SearchCriteria: NSObject, NSCoding {
    var keyword:String?
    var region: [City]?
    var price:(Int, Int)?
    var size:(Int, Int)?
    var types: [Int]?
    
    convenience required init?(coder decoder: NSCoder) {
        
        self.init()
        
        keyword = decoder.decodeObjectForKey("keyword") as? String
        region = decoder.decodeObjectForKey("region") as? [City]
        
        let hasPrice = decoder.decodeBoolForKey("hasPrice")
        if(hasPrice) {
            let priceMin = decoder.decodeIntegerForKey("priceMin")
            let priceMax = decoder.decodeIntegerForKey("priceMax")
            price = (priceMin, priceMax)
        }
        
        let hasSize = decoder.decodeBoolForKey("hasSize")
        
        if(hasSize) {
            let sizeMin = decoder.decodeIntegerForKey("sizeMin")
            let sizeMax = decoder.decodeIntegerForKey("sizeMax")
            size = (sizeMin, sizeMax)
        }
        
        types = decoder.decodeObjectForKey("types") as? [Int]
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(keyword, forKey: "keyword")
        aCoder.encodeObject(region, forKey:"region")
        
        if(price != nil) {
            aCoder.encodeBool(true, forKey: "hasPrice")
            aCoder.encodeInteger(price!.0, forKey:"priceMin")
            aCoder.encodeInteger(price!.1, forKey:"priceMax")
        } else {
            aCoder.encodeBool(false, forKey: "hasPrice")
        }
        
        if(size != nil) {
            aCoder.encodeBool(true, forKey: "hasSize")
            aCoder.encodeInteger(size!.0, forKey:"sizeMin")
            aCoder.encodeInteger(size!.1, forKey:"sizeMax")
        } else {
            aCoder.encodeBool(false, forKey: "hasSize")
        }
        
        aCoder.encodeObject(types, forKey:"types")
    }
}

class SearchItem: NSObject, NSCoding {
    
    let criteria:SearchCriteria
    
    let type:SearchType
    
    var title:String {
        get{
            var resultStr = "不限地區"
            var titleStr = [String]()
            var regionStr = [String]()
            
            if let cities = criteria.region {
                
                if(cities.count == 1) {
                    
                    let city = cities[cities.startIndex]
                    
                    for region in city.regions {
                        regionStr.append( "\(region.name)")
                    }
                    
                    resultStr = "\(city.name) (\(regionStr.prefix(3).joinWithSeparator("，")))"
                    
                } else {
                    for city in cities {
                        
                        if(city.regions.count == 0) {
                            continue
                        }
                        
                        if(city.regions.contains(Region.allRegions)) {
                            titleStr.append( "\(city.name) (\(Region.allRegions.name))")
                        } else {
                            titleStr.append( "\(city.name) (\(city.regions.count))")
                        }
                    }
                }
            }
            
            if(titleStr.count > 0) {
                resultStr = titleStr.joinWithSeparator("，")
            }
            
            return resultStr
        }
    }
    
    var detail:String {
        get{
            var result = ""
            var titleStr = [String]()
            var typeStr = [String]()
            
            if let usageType = criteria.types {
                for type in usageType.sort() {
                    switch type {
                    case CriteriaConst.PrimaryType.FULL_FLOOR:
                        typeStr.append("整層住家")
                    case CriteriaConst.PrimaryType.HOME_OFFICE:
                        typeStr.append("住辦")
                    case CriteriaConst.PrimaryType.ROOM_NO_TOILET:
                        typeStr.append("雅房")
                    case CriteriaConst.PrimaryType.SUITE_COMMON_AREA:
                        typeStr.append("分租套房")
                    case CriteriaConst.PrimaryType.SUITE_INDEPENDENT:
                        typeStr.append("獨立套房")
                    default: break
                    }
                }
                
                result = typeStr.joinWithSeparator("/ ")
            }
            
            result += "\n"
            
            if let priceRange = criteria.price {
                
                assert(priceRange.0 != CriteriaConst.Bound.LOWER_ANY || priceRange.1 != CriteriaConst.Bound.UPPER_ANY
                    , "SearchCriteria.price should be set to nil if there is no limit on lower & upper bounds")
                
                if(priceRange.0 == CriteriaConst.Bound.LOWER_ANY) {
                    
                    titleStr.append("\(priceRange.1) 元以下")
                } else if(priceRange.1 == CriteriaConst.Bound.UPPER_ANY) {
                    
                    titleStr.append("\(priceRange.0) 元以上")
                } else {
                    
                    titleStr.append("\(priceRange.0) - \(priceRange.1) 元")
                }
            } else {
                titleStr.append("不限租金")
            }
            
            if let sizeRange = criteria.size {
                
                assert(sizeRange.0 != CriteriaConst.Bound.LOWER_ANY || sizeRange.1 != CriteriaConst.Bound.UPPER_ANY
                    , "SearchCriteria.size should be set to nil if there is no limit on lower & upper bounds")
                
                if(sizeRange.0 == CriteriaConst.Bound.LOWER_ANY) {
                    
                    titleStr.append("\(sizeRange.1) 坪以下")
                } else if(sizeRange.1 == CriteriaConst.Bound.UPPER_ANY) {
                    
                    titleStr.append("\(sizeRange.0) 坪以上")
                } else {
                    
                    titleStr.append("\(sizeRange.0) - \(sizeRange.1) 坪")
                }
            } else {
                titleStr.append("不限坪數")
            }
            
            return result + titleStr.joinWithSeparator("，")
        }
    }
    
    init(criteria:SearchCriteria, type:SearchType) {
        self.criteria = criteria
        self.type = type
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        let criteria = decoder.decodeObjectForKey("criteria") as? SearchCriteria
        
        let typeInt = decoder.decodeIntegerForKey("type")
        
        let type = SearchType(rawValue: typeInt)
        
        self.init(criteria: criteria!, type: type!)
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(criteria, forKey: "criteria")
        aCoder.encodeInteger(type.rawValue, forKey:"type")
    }
}

protocol SearchHistoryDataStore: class {
    func saveSearchItems(entries: [SearchItem])
    func loadSearchItems() -> [SearchItem]?
    func clearSearchItems()
}

class UserDefaultsSearchHistoryDataStore: SearchHistoryDataStore {
    
    static let instance = UserDefaultsSearchHistoryDataStore()
    
    static let userDefaultsKey = "searchHistory"
    
    static func getInstance() -> UserDefaultsSearchHistoryDataStore {
        return UserDefaultsSearchHistoryDataStore.instance
    }
    
    func saveSearchItems(entries: [SearchItem]) {
        //Save selection to user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(entries)
        userDefaults.setObject(data, forKey: UserDefaultsSearchHistoryDataStore.userDefaultsKey)
    }
    
    func loadSearchItems() -> [SearchItem]? {
        //Load selection from user defaults
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsSearchHistoryDataStore.userDefaultsKey) as? NSData
        
        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [SearchItem]
    }
    
    func clearSearchItems() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsSearchHistoryDataStore.userDefaultsKey)
    }
}