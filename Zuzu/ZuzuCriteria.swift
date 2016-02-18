//
//  RadarCriteria.swift
//  Zuzu
//
//  Created by eechih on 2/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import Foundation
import ObjectMapper
import SwiftyJSON


private let Log = Logger.defaultLogger

class ZuzuCriteria: NSObject, Mappable {
    
    static let filterSections:[FilterSection] = ConfigLoader.loadAdvancedFilters()
    static let codeToCityMap:[Int : City] = ConfigLoader.CodeToCityMap
    
    var userId: String?
    var criteriaId: String?
    var enabled: Bool?
    var expireTime: NSDate?
    var appleProductId: String?
    var criteria: SearchCriteria?
    
    override init() {
    }
    
    required init?(_ map: Map) {
        
    }
    
    // Mappable
    func mapping(map: Map) {
        userId              <-  map["user_id"]
        criteriaId          <-  map["criteria_id"]
        enabled             <-  map["enabled"]
        expireTime          <- (map["expire_time"], expireTimeTransform)
        appleProductId      <-  map["apple_product_id"]
        criteria            <- (map["filters"], criteriaTransform)
    }
    
    
    
    // MARK - Transforms

    //
    let expireTimeTransform = TransformOf<NSDate, String>(fromJSON: { (values: String?) -> NSDate? in
            if let dateString = values {
                return CommonUtils.getStandardDateFromString(dateString)
            }
            return nil
        }, toJSON: { (values: NSDate?) -> String? in
            if let date = values {
                return CommonUtils.getStandardStringFromDate(date)
            }
            return nil
    })

    
    //
    let criteriaTransform = TransformOf<SearchCriteria, [String: AnyObject]>(fromJSON: { (values: [String: AnyObject]?) -> SearchCriteria? in
            return ZuzuCriteria.criteriaFromJSON(values)
        }, toJSON: { (values: SearchCriteria?) -> [String: AnyObject]? in
            return ZuzuCriteria.criteriaToJSON(values)
    })
    
    
    
    // MARK - Static Functions
    
    static func criteriaFromJSON(JSONDict: [String: AnyObject]?) -> SearchCriteria? {
        
        if let JSONDict = JSONDict, let dataFromString = JSONDict["value"]?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            
            let json = JSON(data: dataFromString)
            
            // 地區
            var selectedCities = [City]()
            for (_, cityJson):(String, JSON) in json["city"] {
                
                let cityCode = cityJson["code"].intValue
                
                if let city = codeToCityMap[cityCode] {
                    
                    var selectedRegions = [Region]()
                    
                    if cityJson["regions"].arrayValue.isEmpty {
                        selectedRegions.append(Region.allRegions)
                    }
                
                    for (_, regionJson):(String, JSON) in cityJson["regions"] {
                        
                        let regionCode = regionJson.intValue
                        
                        if let region = city.regions.filter({$0.code == regionCode}).first {
                            selectedRegions.append(Region(code: region.code, name: region.name))
                        }
                    }
                    
                    selectedCities.append(City(code: city.code, name: city.name, regions: selectedRegions))
                }
            }
            
            // 用途
            let types = json["purpose_type"]["value"].arrayObject as? [Int]
            
            // 租金範圍
            let price:(Int, Int) = (json["price"]["from"].intValue, json["price"]["to"].intValue)
            
            // 坪數範圍
            let size:(Int, Int) = (json["size"]["from"].intValue, json["size"]["to"].intValue)
            
            Log.debug("cities: \(selectedCities)")
            Log.debug("types: \(types)")
            Log.debug("price: \(price)")
            Log.debug("size: \(size)")
            
            
            // Collect all FilterGroup
            var filterGroups: [FilterGroup] = [FilterGroup]()
            for filterSection in ZuzuCriteria.filterSections {
                for filterGroup in filterSection.filterGroups {
                    filterGroups.append(filterGroup)
                }
            }
            
            
            var selectedFilterGroups = [FilterGroup]()
            
            for filterGroup: FilterGroup in filterGroups {
                
                // 排除 "不限" Filter
                let filters = filterGroup.filters.filter({ (filter) -> Bool in
                    return filter.key != "unlimited"
                })
                
                var selectedFilters = [Filter]()
                
                // Special: 交通站點 (捷運, 公車, 火車, 高鐵)
                if filterGroup.id == "public_trans" {
                    
                    for filter: Filter in filters {
                        if json[filter.key].stringValue == "true" {
                            selectedFilters.append(filter)
                            continue
                        }
                    }
                }
                
                // Type: 附車位, 不要地下室, 不要頂樓加蓋, 可養寵物, 可開伙
                if filterGroup.type == DisplayType.SimpleView {
                    
                    for filter: Filter in filters {
                
                        // Special: 不要地下室
                        if filter.key == "floor" && json["basement"].stringValue == "false" {
                            selectedFilters.append(filter)
                            continue
                        }
                        
                        if json[filter.key].stringValue == filter.value {
                            selectedFilters.append(filter)
                        }
                    }
                }
                
                // Type: 房客性別, 最短租期
                if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.SingleChoice {
                    
                    for filter: Filter in filters {
                        
                        // Special: 最短租期
                        if filter.key == "shortest_lease" && filter.value.rangeOfString(json[filter.key].stringValue) != nil {
                            selectedFilters.append(filter)
                            continue
                        }
                        
                        if json[filter.key].stringValue == filter.value {
                            selectedFilters.append(filter)
                        }
                    }
                }
                
                // Type: 型態, 格局, 經辦人, 房客身分, 附傢俱, 附設備, 周邊機能
                if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.MultiChoice {
                    
                    if let filterKey = filters.first?.key,
                        let jsonValueArray = json[filterKey]["value"].arrayObject as? [Int] {
                            
                            for filter: Filter in filters {
                            
                                // Special: 格局 (5房以上)
                                if filter.key == "num_bedroom" && filter.value == "[5 TO *]" && jsonValueArray.contains(5) {
                                    selectedFilters.append(filter)
                                    continue
                                }
                                
                                if let filterValue: Int = Int(filter.value) {
                                    if jsonValueArray.contains(filterValue) {
                                        selectedFilters.append(filter)
                                    }
                                }
                            }
                        
                    }
                }
                
                if selectedFilters.count > 0 {
                    filterGroup.filters = selectedFilters
                    selectedFilterGroups.append(filterGroup)
                }
            }
            
            for filterGroup in selectedFilterGroups {
                Log.debug("filterGroup: \(filterGroup)")
            }
            
            let criteria = SearchCriteria()
            criteria.region = selectedCities
            criteria.types = types
            criteria.price = price
            criteria.size = size
            criteria.filterGroups = selectedFilterGroups
            
            return criteria
        }
        
        return nil
    }
    
    static func criteriaToJSON(criteria: SearchCriteria?) -> [String: AnyObject]? {
        
        if let criteria = criteria {
            
            var JSONDict = [String: AnyObject]()
            
            // 地區
            if let cities = criteria.region {
                var results = [[String: AnyObject]]()
                
                for city: City in cities {
                    
                    var regionCodes = [Int]()
                    for region: Region in city.regions {
                        
                        // Ignore 全區
                        if region.code != 0 {
                            regionCodes.append(region.code)
                        }
                    }
                    
                    results.append(["code": city.code, "regions": regionCodes])
                }
                
                JSONDict["city"] = results
            }
            
            // 用途
            if let purposeTypes = criteria.types {
                JSONDict["purpose_type"] = ["operator": "OR", "value": purposeTypes]
            }
            
            // 租金範圍
            if let (from, to) = criteria.price {
                JSONDict["price"] = ["from": from, "to": to]
            }
            
            // 坪數範圍
            if let (from, to) = criteria.size {
                JSONDict["size"] = ["from": from, "to": to]
            }
            
            
            if let filterGroups = criteria.filterGroups {
                
                for filterGroup: FilterGroup in filterGroups {
                    
                    // Type: 附車位, 不要地下室, 不要頂樓加蓋, 可養寵物, 可開伙
                    if filterGroup.type == DisplayType.SimpleView {
                        if let filterKey: String = filterGroup.filters.first?.key {
                            // Special: 不要地下室
                            if filterKey == "floor" {
                                JSONDict["basement"] = false
                                continue
                            }
                        
                            if let firstValue = filterGroup.filters.first?.value {
                                if firstValue == "true" {
                                    JSONDict[filterKey] = true
                                    continue
                                } else if firstValue == "false" {
                                    JSONDict[filterKey] = false
                                    continue
                                }
                            }
                        }
                    }
                    
                    // Type: 房客性別, 最短租期
                    if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.SingleChoice {
                        if let filterKey: String = filterGroup.filters.first?.key,
                            let firstValue = filterGroup.filters.first?.value {
                                
                                // Special: 最短租期
                                if filterKey == "shortest_lease" {
                                    
                                    if let value = firstValue.stringByReplacingOccurrencesOfString("]", withString: "").stringByReplacingOccurrencesOfString("[", withString: "").componentsSeparatedByString(" ").last {
                                        if let intValue = Int(value) {
                                            JSONDict[filterKey] = intValue
                                            continue
                                        }
                                    }
                                }
                                
                                if let value = Int(firstValue) {
                                    JSONDict[filterKey] = value
                                    continue
                                }
                        }
                    }
                    
                    // Type: 型態, 格局, 經辦人, 房客身分, 附傢俱, 附設備, 周邊機能, 交通站點
                    if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.MultiChoice {
                        
                        if let filterKey: String = filterGroup.filters.first?.key,
                            let logicType = filterGroup.logicType?.rawValue {
                                
                                var valueArray = [Int]()
                                
                                for filter: Filter in filterGroup.filters {
                                    
                                    // 忽略 "不限" Filter
                                    if filter.key == "unlimited" {
                                        continue
                                    }
                                    
                                    // Special: 交通站點 (捷運, 公車, 火車, 高鐵)
                                    if ["nearby_mrt", "nearby_bus", "nearby_train", "nearby_thsr"].contains(filter.key) {
                                        JSONDict[filter.key] = true
                                        continue
                                    }
                                    
                                    // Special: 格局 (5房以上)
                                    if filter.key == "num_bedroom" && filter.value == "[5 TO *]" {
                                        valueArray.append(5)
                                        continue
                                    }
                                    
                                    if let value: Int = Int(filter.value) {
                                        valueArray.append(value)
                                    }
                                }
                                
                                if valueArray.count > 0 {
                                    JSONDict[filterKey] = ["operator":  logicType, "value": valueArray]
                                }
                            
                        }
                    }
                }
            }
            
            return JSONDict
        }
        
        return nil
    }
    
}

