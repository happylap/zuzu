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

struct HouseItemDocument {
    
    struct Sorting {
        static let sortAsc = "asc"
        static let sortDesc = "desc"
    }
    
    static let price:String = "price"
    static let size:String = "size"
    static let postTime:String = "post_time"
}

class SearchCriteria: NSObject, NSCoding {
    var keyword:String?
    var region: [City]?
    var price:(Int, Int)?
    var size:(Int, Int)?
    var types: [Int]?
    var sorting:String?
    
    ///Additional Filters [Field:Value]
    var filters: [String : String]?
    
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
    
    func isEmpty() ->Bool {
        
        return (keyword == nil)
            && (region == nil)
            && (price == nil)
            && (size == nil)
            && (types == nil)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let targetObj = object as? SearchCriteria {
            
            var isEqual = true
            
            isEqual = isEqual && (self.keyword == targetObj.keyword)
            
            if let region1 = self.region, let region2 = targetObj.region {
                
                    if region1.count != region2.count {
                        
                         isEqual = isEqual && false
                        
                    } else {
                        
                        for city1 in region1 {
                            if let index = region2.indexOf(city1) {
                                let city2 = region2[index]
                                
                                isEqual = isEqual && (city1.regions == city2.regions)
                                
                            } else {
                                
                                isEqual = isEqual && false
                            }
                        }
                        
                    }
                    
            } else {
                isEqual = isEqual && (self.region == nil && targetObj.region == nil)
            }
            
            
            isEqual = isEqual && (self.price == targetObj.price)
            
            isEqual = isEqual && (self.size == targetObj.size)
            
            isEqual = isEqual && (self.types == targetObj.types)
            
            return isEqual
        }
        return false
    }
}

func ==<T: Equatable>(lhs: [T]?, rhs: [T]?) -> Bool {
    switch (lhs,rhs) {
    case (.Some(let lhs), .Some(let rhs)):
        return lhs == rhs
    case (.None, .None):
        return true
    default:
        return false
    }
}

func == <T:Equatable> (tuple1:(T,T)?,tuple2:(T,T)?) -> Bool {
    switch (tuple1,tuple2) {
    case (.Some(let tuple1), .Some(let tuple2)):
        return (tuple1.0 == tuple2.0) && (tuple1.1 == tuple2.1)
    case (.None, .None):
        return true
    default:
        return false
    }
}

class SearchItem: NSObject, NSCoding {
    
    static let labelMaker:LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
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
            
            if let purposeType = criteria.types {
                for type in purposeType.sort() {
                    
                    if let typeString = SearchItem.labelMaker.fromCodeForField("purpose_type", code: type) {
                        typeStr.append(typeString)
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