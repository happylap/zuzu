//
//  RadarDisplayItem.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/16.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class RadarDisplayItem: NSObject, NSCoding {
    
    static let labelMaker:LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
    let criteria:SearchCriteria
    
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
        
    init(criteria:SearchCriteria) {
        self.criteria = criteria
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        let criteria = decoder.decodeObjectForKey("criteria") as? SearchCriteria
                
        self.init(criteria: criteria!)
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(criteria, forKey: "criteria")

    }
}
