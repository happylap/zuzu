//
//  ConfigLoader.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/12/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct ConfigLoader {
    
    static private var regionDic : [Int : City]?
    static private var cityList : [City]?
    
    static let RegionList:[Int : City] =  {
        ConfigLoader.initCityData()
        return regionDic!
    }()
    
    static let SortedCityList:[City] = {
        ConfigLoader.initCityData()
        return cityList!
    }()
    
    // MARK: - Private Utils
    
    private static func initCityData() {
        
        regionDic = regionDic ?? [Int : City]()
        cityList = cityList ?? [City]()
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            ///Load all city regions from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                NSLog("Cities = %d", cities.count)
                
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
                
                NSLog("Cannot load area json file %@", error)
                
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
                
                NSLog("Cities = %d", cities.count)
                
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
                
                NSLog("Cannot load area json file %@", error)
                
            }
            
        }
        
        return cityRegions
    }
}