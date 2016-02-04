//
//  RadarCriteria.swift
//  Zuzu
//
//  Created by eechih on 2/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import ObjectMapper

import Foundation
import ObjectMapper

class ZuzuCriteria: NSObject, Mappable {
    
    var userId: String?
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
        enabled             <-  map["enabled"]
        expireTime          <-  map["expire_time"]
        appleProductId      <-  map["apple_product_id"]
        criteria            <- (map["filetrs"], filtersTransform)
    }
    
    // MARK - Transforms
    
    //
    let filtersTransform = TransformOf<SearchCriteria, [String: AnyObject]>(fromJSON: { (values: [String: AnyObject]?) -> SearchCriteria? in
        if let values = values {
            return SearchCriteria()
        } else {
            return nil
        }
        }, toJSON: { (values: SearchCriteria?) -> [String: AnyObject]? in
            if let criteria = values {
                
                var filters = [String: AnyObject]()
                
                if let (from, to) = criteria.price {
                    filters["price"] = ["from": from, "to": to]
                }
                
                if let (from, to) = criteria.size {
                    filters["size"] = ["from": from, "to": to]
                }
                
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
                    
                    filters["city"] = results
                }
                
                if let purposeTypes = criteria.types {
                    filters["purpose_types"] = ["operator": "OR", "value": purposeTypes]
                }
                
                if let filterGroups = criteria.filterGroups {
                    
                    for filterGroup: FilterGroup in filterGroups {
                        
                        if let filterKey: String = filterGroup.filters.first?.key,
                            let firstValue = filterGroup.filters.first?.value {
                                
                                if filterKey == "floor" {
                                    filters["basement"] = "false"
                                }
                                
                                if filterKey == "shortest_lease" {
                                    //filters["shortest_lease"] = 180
                                }
                                
                                if filterGroup.type == DisplayType.SimpleView {
                                    filters[filterKey] = firstValue
                                }
                                
                                if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.SingleChoice {
                                    filters[filterKey] = firstValue
                                }
                                
                                if filterGroup.type == DisplayType.DetailView && filterGroup.choiceType == ChoiceType.MultiChoice {
                                    if let logicType = filterGroup.logicType?.rawValue {
                                        var values = [Int]()
                                        for filter: Filter in filterGroup.filters {
                                            if let value: Int = Int(filter.value) {
                                                values.append(value)
                                            }
                                        }
                                        filters[filterKey] = ["operator":  logicType, "value": values]
                                    }
                                }
                                
                        }
                    }
                }
                
                return filters
            } else {
                return nil
            }
    })
}