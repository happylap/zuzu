//
//  ConfigLoader.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/12/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON

private let Log = Logger.defaultLogger

public struct ConfigLoader {
    
    static private var regionDic : [Int : City]?
    static private var cityList : [City]?
    
    static let CodeToCityMap:[Int : City] =  {
        if(regionDic == nil) {
            ConfigLoader.initCityData()
        }
        return regionDic!
    }()
    
    static let SortedCityList:[City] = {
        if(cityList == nil) {
            ConfigLoader.initCityData()
        }
        return cityList!
    }()
    
    // MARK: - Private Utils
    
    private static func initCityData() {
        
        regionDic = [Int : City]()
        cityList = [City]()
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            ///Load all city regions from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                Log.debug("Cities = \(cities.count)")
                
                for cityJsonObj in cities {
                    let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    let regions = cityJsonObj["region"].arrayValue
                    
                    ///Init Region Table data
                    var regionList:[Region] = [Region]()
                    
                    regionList.append(Region.allRegions)///All region
                    
                    for region in regions {
                        if let regionDic = region.dictionary {
                            for key in regionDic.keys {
                                regionList.append(Region(code: regionDic[key]!.intValue, name: key))
                            }
                        }
                    }
                    
                    let city = City(code: code, name: name, regions: regionList)
                    
                    regionDic?[code] = city
                    cityList?.append(city)
                }
                
            } catch let error as NSError{
                
                Log.debug("Cannot load area json file \(error.localizedDescription)")
                
            }
            
        }
    }
    
    private static func loadCityRegionData() -> [Int : City] {
        
        var cityRegions = [Int : City]()
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            ///Load all city regions from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                Log.debug("Cities = \(cities.count)")
                
                for cityJsonObj in cities {
                    let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    let regions = cityJsonObj["region"].arrayValue
                    
                    ///Init Region Table data
                    var regionList:[Region] = [Region]()
                    
                    regionList.append(Region.allRegions)///All region
                    
                    for region in regions {
                        if let regionDic = region.dictionary {
                            for key in regionDic.keys {
                                regionList.append(Region(code: regionDic[key]!.intValue, name: key))
                            }
                        }
                    }
                    
                    let city = City(code: code, name: name, regions: regionList)
                    
                    cityRegions[code] = city
                }
                
            } catch let error as NSError{
                
                Log.debug("Cannot load area json file \(error.localizedDescription)")
                
            }
            
        }
        
        return cityRegions
    }
    
    static func loadAdvancedFilters() ->  [FilterSection]{
        return ConfigLoader.loadFilterData("resultFilters", criteriaLabel: "advancedFilters")
    }
    
    static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [FilterSection]{
        
        var resultSections = [FilterSection]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let groupList = json[criteriaLabel].arrayValue
                
                Log.debug("\(criteriaLabel) = \(groupList.count)")
                
                for groupJson in groupList {
                    let section = groupJson["section"].stringValue
                    
                    if let itemList = groupJson["groups"].array {
                        
                        let allFilters = itemList.map({ (itemJson) -> FilterGroup in
                            let groupId = itemJson["id"].stringValue
                            let label = itemJson["label"].stringValue
                            let type = itemJson["displayType"].intValue
                            let choiceType = ChoiceType(rawValue: itemJson["choiceType"].stringValue)
                            let logicType = LogicType(rawValue: itemJson["logicType"].stringValue)
                            let commonKey = itemJson["filterKey"].stringValue
                            
                            
                            if let filters = itemJson["filters"].array {
                                ///DetailView
                                
                                let filters = filters.enumerate().map({ (index, filterJson) -> Filter in
                                    let label = filterJson["label"].stringValue
                                    var value = filterJson["filterValue"].stringValue
                                    
                                    /// TODO: Handle the special case for shortest_lease
                                    /// We'll define a new json format for range value
                                    /// Make the filterValue independent of Solr format
                                    if(commonKey == "shortest_lease") {
                                        value = "[0 TO \(value)]"
                                    }
                                    
                                    if let key = filterJson["filterKey"].string {
                                        return Filter(label: label, key: key, value: value, order: index)
                                    } else {
                                        return Filter(label: label, key: commonKey, value: value, order: index)
                                    }
                                })
                                
                                let filterGroup = FilterGroup(id: groupId, label: label,
                                    type: DisplayType(rawValue: type)!,
                                    filters: filters)
                                
                                filterGroup.logicType = logicType
                                filterGroup.choiceType = choiceType
                                
                                return filterGroup
                                
                            } else {
                                ///SimpleView
                                
                                let value = itemJson["filterValue"].stringValue
                                
                                let filterGroup = FilterGroup(id: groupId, label: label,
                                    type: DisplayType(rawValue: type)!,
                                    filters: [Filter(label: label, key: commonKey, value: value)])
                                
                                return filterGroup
                                
                            }
                        })
                        
                        resultSections.append(FilterSection(label: section, filterGroups: allFilters))
                        
                    }
                    
                    
                }
                
            } catch let error as NSError{
                
                Log.debug("Cannot load json file \(error.localizedDescription)")
                
            }
        }
        
        return resultSections
    }
}