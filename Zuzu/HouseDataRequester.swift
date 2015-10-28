//
//  HouseDataRequester.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct SolrConst {
    struct Server {
        static let SCHEME = "http"
        static let HOST = "ec2-52-76-69-228.ap-southeast-1.compute.amazonaws.com"
        static let PORT = 8983
        static let PATH = "/solr/rhc/select"
    }
    
    struct Query {
        static let MAIN_QUERY = "q"
        static let FILTER_QUERY = "fq"
        static let WRITER_TYPE = "wt"
        static let INDENT = "indent"
        static let START = "start"
        static let ROW = "rows"
        static let SORTING = "sort"
    }
    
    struct Filed {
        static let CITY = "city"
        static let REGION = "region"
        static let TYPE = "purpose_type"
        static let PRICE = "price"
        static let SIZE = "size"
    }
    
}

class HouseItem:NSObject, NSCoding {
    
    class Builder: NSObject {
        
        private var id: String?
        private var title: String?
        private var addr: String?
        private var type: Int?
        private var usage: Int?
        private var price: Int?
        private var size: Int?
        private var desc: String?
        private var imgList: [String]?
        
        private func validateParams() -> Bool{
            return (self.id != nil) && (self.title != nil)
                && (self.price != nil) && (self.size != nil)
        }
        
        init(id:String?) {
            self.id = id
        }
        
        func addTitle(title:String?) -> Builder {
            self.title = title
            return self
        }
        
        func addAddr(addr:String?) -> Builder {
            self.addr = addr
            return self
        }
        
        func addType(type:Int?) -> Builder {
            self.type = type
            return self
        }
        
        func addUsage(usage:Int?) -> Builder {
            self.usage = usage
            return self
        }
        
        func addPrice(price:Int?) -> Builder {
            self.price = price
            return self
        }
        
        func addSize(size:Int?) -> Builder {
            self.size = size
            return self
        }
        
        func addDesc(desc:String?) -> Builder {
            self.desc = desc
            return self
        }
        
        func addImageList(imgList: [String]?) -> Builder {
            self.imgList = imgList
            return self
        }
        
        func build() -> HouseItem {
            assert(validateParams(), "Incorrect HouseItem building params")
            return HouseItem(builder: self)
        }
    }
    
    /// House Item Members
    let id: String
    let title: String
    let addr: String
    let type: Int
    let usage: Int
    let price: Int
    let size: Int
    let desc: String?
    let imgList: [String]?
    
    
    private init(builder: Builder){
        /// Assign default value for mandatory fields
        /// cause we don't want the app exists because of some incorrect data in the backend
        self.id = builder.id ?? ""
        self.title = builder.title ?? ""
        self.addr = builder.addr ?? ""
        self.type = builder.type ?? 0
        self.usage = builder.usage ?? 0
        self.price = builder.price ?? 0
        self.size = builder.size ?? 0
        self.desc = builder.desc
        self.imgList = builder.imgList
        
        super.init()
    }
    
    required convenience init?(coder decoder: NSCoder) {
        
        let id  = decoder.decodeObjectForKey("id") as? String ?? ""
        let title = decoder.decodeObjectForKey("title") as? String ?? ""
        let addr = decoder.decodeObjectForKey("addr") as? String ?? ""
        let type = decoder.decodeIntegerForKey("type") as Int
        let usage = decoder.decodeIntegerForKey("usage") as Int
        let price = decoder.decodeIntegerForKey("price") as Int
        let size = decoder.decodeIntegerForKey("size") as Int
        let desc = decoder.decodeObjectForKey("desc") as? String ?? ""
        let imgList = decoder.decodeObjectForKey("imgList") as? [String] ?? [String]()
        
        let builder: Builder = Builder(id: id)
            .addTitle(title)
            .addAddr(addr)
            .addType(type)
            .addUsage(usage)
            .addPrice(price)
            .addSize(size)
            .addDesc(desc)
            .addImageList(imgList)
        
        self.init(builder: builder)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey:"id")
        aCoder.encodeObject(title, forKey:"title")
        aCoder.encodeObject(addr, forKey:"addr")
        aCoder.encodeInteger(type, forKey:"type")
        aCoder.encodeInteger(usage, forKey:"usage")
        aCoder.encodeInteger(price, forKey:"price")
        aCoder.encodeInteger(size, forKey:"size")
        aCoder.encodeObject(desc, forKey:"desc")
        aCoder.encodeObject(imgList, forKey:"imgList")
    }
    
}

public class HouseDataRequester: NSObject, NSURLConnectionDelegate {
    
    private static let requestTimeout = 15.0
    private static let instance = HouseDataRequester()
    
    let urlComp = NSURLComponents()
    var numOfRecord: Int?
    
    public static func getInstance() -> HouseDataRequester{
        return instance
    }
    
    // designated initializer
    public override init() {
        super.init()
        
        urlComp.scheme = SolrConst.Server.SCHEME
        urlComp.host = SolrConst.Server.HOST
        urlComp.port = SolrConst.Server.PORT
        urlComp.path = SolrConst.Server.PATH
    }
    
    func searchByCriteria(criteria: SearchCriteria, start: Int, row: Int,
        handler: (totalNum: Int?, result: [HouseItem], error: NSError?) -> Void) {
            
            let keyword: String? = criteria.keyword
            let area: [City]? = criteria.region
            let price: (Int, Int)? = criteria.price
            let size: (Int, Int)? = criteria.size
            let types: [Int]? = criteria.types
            let sorting: String? = criteria.sorting
            let filters: [String:String]? = criteria.filters
            
            var queryitems:[NSURLQueryItem] = []
            var mainQueryStr:String = "*:*"
            
            // Add query string
            if let keywordStr = keyword{
                if(keywordStr.characters.count > 0) {
                    let escapedStr = StringUtils.escapeForSolrString(keywordStr)
                    mainQueryStr = "title:\(escapedStr) OR desc:\(escapedStr)"
                }
            }
            
            // Region
            var areaConditionStr: [String] = [String]()
            
            if let selectedCity = area {
                
                //Handle Cities first
                let allCities = selectedCity.filter({ (city: City) -> Bool in
                    return city.regions.contains(Region.allRegions)
                })
                
                if(allCities.count > 0) {
                    let allCitiesStr = allCities.map({ (city) -> String in
                        return "\(city.code)"
                    }).joinWithSeparator(" OR ")
                    
                    areaConditionStr.append("\(SolrConst.Filed.CITY):(\(allCitiesStr))")
                }
                
                //Handle Regions
                let cityWithRegions = selectedCity.filter({ (city: City) -> Bool in
                    return !city.regions.contains(Region.allRegions)
                })
                
                var allRegions:[String] = [String]()
                
                for city in cityWithRegions {
                    allRegions.appendContentsOf(
                        city.regions.map({ (region) -> String in
                            return "\(region.code)"
                        })
                    )
                }
                
                if(allRegions.count > 0) {
                    let allRegionsStr = allRegions.joinWithSeparator(" OR ")
                    areaConditionStr.append("\(SolrConst.Filed.REGION):(\(allRegionsStr))")
                }
                
                //Compose whole area condition string
                if (areaConditionStr.count > 0) {
                    queryitems.append( NSURLQueryItem(
                        name: SolrConst.Query.FILTER_QUERY,
                        value:areaConditionStr.joinWithSeparator(" OR "))
                    )
                }
            }
            
            // Purpose Type
            if let typeList = types {
                
                for (index, type) in typeList.enumerate() {
                    if(index == 0) {
                        mainQueryStr += " AND \(SolrConst.Filed.TYPE):( \(type)"
                    } else {
                        mainQueryStr += " OR \(type)"
                    }
                    
                    if(index == typeList.count - 1) {
                        mainQueryStr += " )"
                    }
                }
                
            }
            
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.MAIN_QUERY, value: mainQueryStr))
            
            // Price
            if let priceRange = price {
                
                var priceFrom = "\(priceRange.0)"
                var priceTo = "\(priceRange.1)"
                
                if(priceRange.0 == CriteriaConst.Bound.LOWER_ANY) {
                    priceFrom = "*"
                } else if(priceRange.1 == CriteriaConst.Bound.UPPER_ANY) {
                    priceTo = "*"
                }
                
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(SolrConst.Filed.PRICE):[\(priceFrom) TO \(priceTo)]"))
            }
            
            // Size
            if let sizeRange = size {
                
                var sizeFrom = "\(sizeRange.0)"
                var sizeTo = "\(sizeRange.1)"
                
                if(sizeRange.0 == CriteriaConst.Bound.LOWER_ANY) {
                    sizeFrom = "*"
                } else if(sizeRange.1 == CriteriaConst.Bound.UPPER_ANY) {
                    sizeTo = "*"
                }
                
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(SolrConst.Filed.SIZE):[\(sizeFrom) TO \(sizeTo)]"))
            }
            
            //Filters
            if let filters = filters {
                for (key, value) in filters {
                    queryitems.append(
                        NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(key):\(value)"))
                }
            }
            
            //Sorting
            if let sorting = sorting {
                queryitems.append(NSURLQueryItem(name: SolrConst.Query.SORTING, value: sorting))
            }
            
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: "json"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.START, value: "\(start)"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.ROW, value: "\(row)"))
            
            urlComp.queryItems = queryitems
            
            performSearch(urlComp, handler: handler)
    }
    
    private func performSearch(urlComp: NSURLComponents,
        handler: (totalNum: Int?, result: [HouseItem], error: NSError?) -> Void){
            
            var houseList = [HouseItem]()
            
            if let fullURL = urlComp.URL {
                
                print("fullURL: \(fullURL.absoluteString)")
                
                let request = NSMutableURLRequest(URL: fullURL)
                request.timeoutInterval = HouseDataRequester.requestTimeout
                
                request.HTTPMethod = "GET"
                
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue()){
                        (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        do {
                            if(error != nil){
                                NSLog("HTTP request error = %ld, desc = %@", error!.code, error!.localizedDescription)
                                handler(totalNum: 0, result: houseList, error: error)
                                return
                            }
                            
                            if(data == nil) {
                                NSLog("HTTP no data")
                                return
                            }
                            
                            let jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! Dictionary<String, AnyObject>
                            
                            //NSLog("\(jsonResult)")
                            
                            if let response = jsonResult["response"] as? Dictionary<String, AnyObject> {
                                let itemList = response["docs"] as! Array<Dictionary<String, AnyObject>>
                                
                                self.numOfRecord = response["numFound"] as? Int
                                
                                for house in itemList {
                                    let id = house["id"]  as? String
                                    let title = house["title"] as? String
                                    let addr = house["addr"]  as? String
                                    let type = house["house_type"] as? Int
                                    let usage = house["purpose_type"] as? Int
                                    let price = house["price"] as? Int
                                    let size = house["size"] as? Int
                                    let desc = house["desc"]  as? String
                                    let imgList = house["img"] as? [String]
                                    
                                    NSLog("houseItem: \(id)")
                                    
                                    let house:HouseItem = HouseItem.Builder(id: id)
                                        .addTitle(title)
                                        .addAddr(addr)
                                        .addType(type)
                                        .addUsage(usage)
                                        .addPrice(price)
                                        .addSize(size)
                                        .addDesc(desc)
                                        .addImageList(imgList)
                                        .build()
                                    
                                    houseList.append(house)
                                }
                                
                                handler(totalNum: self.numOfRecord, result: houseList, error: nil)
                            } else {
                                assert(false, "Solr response error:\n \(jsonResult)")
                            }
                            
                        }catch let error as NSError{
                            handler(totalNum: 0, result: houseList, error: error)
                            NSLog("JSON parsing error = \(error)")
                        }
                }
                
            }
    }
}