//
//  HouseDataRequester.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON

struct SolrConst {
    
    static let DefaultPhraseSlope = 2
    
    struct Server {
        static let SCHEME = "http"
        static let HOST = "solr.zuzu.com.tw"
        static let PORT = 8983
        static let PATH = "/solr/rhc/select"
        static let HTTP_METHOD = "GET"
    }
    
    struct Query {
        static let MAIN_QUERY = "q"
        static let FILTER_QUERY = "fq"
        static let FILTER_LIST = "fl"
        static let WRITER_TYPE = "wt"
        static let INDENT = "indent"
        static let START = "start"
        static let ROW = "rows"
        static let SORTING = "sort"
    }
    
    struct Operator {
        static let OR = "OR"
        static let AND = "AND"
    }
    
    struct Filed {
        static let ID = "id"
        static let TITLE = "title"
        static let ADDR = "addr"
        static let PURPOSE_TYPE = "purpose_type"
        static let HOUSE_TYPE = "house_type"
        static let PRICE = "price"
        static let SIZE = "size"
        static let SOURCE = "source"
        static let CITY = "city"
        static let REGION = "region"
        static let IMG_LIST = "img"
    }
    
    struct Format {
        static let JSON = "json"
    }
    
}

class HouseItem:NSObject, NSCoding {
    
    class Builder: NSObject {
        
        private var id: String?
        private var title: String?
        private var addr: String?
        private var houseType: Int?
        private var purposeType: Int?
        private var price: Int?
        private var size: Float?
        private var source: Int?
        private var desc: String?
        private var imgList: [String]?
        
        private func validateParams() -> Bool{
            return (self.id != nil) && (self.title != nil)
                && (self.price != nil) && (self.size != nil)
        }
        
        init(id:String) {
            self.id = id
        }
        
        func addTitle(title:String) -> Builder {
            self.title = title
            return self
        }
        
        func addAddr(addr:String) -> Builder {
            self.addr = addr
            return self
        }
        
        func addHouseType(type:Int) -> Builder {
            self.houseType = type
            return self
        }
        
        func addPurposeType(usage:Int) -> Builder {
            self.purposeType = usage
            return self
        }
        
        func addPrice(price:Int) -> Builder {
            self.price = price
            return self
        }
        
        func addSize(size:Float) -> Builder {
            self.size = size
            return self
        }
        
        func addSource(source:Int) -> Builder {
            self.source = source
            return self
        }
        
        func addDesc(desc:String) -> Builder {
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
    let houseType: Int
    let purposeType: Int
    let price: Int
    let source: Int
    let size: Float
    let desc: String?
    let imgList: [String]?
    
    
    private init(builder: Builder){
        /// Assign default value for mandatory fields
        /// cause we don't want some exceptions happen in the App because of some incorrect data in the backend
        self.id = builder.id ?? ""
        self.title = builder.title ?? ""
        self.addr = builder.addr ?? ""
        self.houseType = builder.houseType ?? 0
        self.purposeType = builder.purposeType ?? 0
        self.price = builder.price ?? 0
        self.size = builder.size ?? 0
        self.source = builder.source ?? 0
        self.desc = builder.desc
        self.imgList = builder.imgList
        
        super.init()
    }
    
    required convenience init?(coder decoder: NSCoder) {
        
        let id  = decoder.decodeObjectForKey("id") as? String ?? ""
        let title = decoder.decodeObjectForKey("title") as? String ?? ""
        let addr = decoder.decodeObjectForKey("addr") as? String ?? ""
        let houseType = decoder.decodeIntegerForKey("houseType") as Int
        let purposeType = decoder.decodeIntegerForKey("purposeType") as Int
        let price = decoder.decodeIntegerForKey("price") as Int
        let size = decoder.decodeFloatForKey("size") as Float
        let source = decoder.decodeIntegerForKey("source") as Int
        let desc = decoder.decodeObjectForKey("desc") as? String ?? ""
        let imgList = decoder.decodeObjectForKey("imgList") as? [String] ?? [String]()
        
        let builder: Builder = Builder(id: id)
            .addTitle(title)
            .addAddr(addr)
            .addHouseType(houseType)
            .addPurposeType(purposeType)
            .addPrice(price)
            .addSize(size)
            .addSource(source)
            .addDesc(desc)
            .addImageList(imgList)
        
        self.init(builder: builder)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(id, forKey:"id")
        aCoder.encodeObject(title, forKey:"title")
        aCoder.encodeObject(addr, forKey:"addr")
        aCoder.encodeInteger(houseType, forKey:"houseType")
        aCoder.encodeInteger(purposeType, forKey:"purposeType")
        aCoder.encodeInteger(price, forKey:"price")
        aCoder.encodeFloat(size, forKey:"size")
        aCoder.encodeInteger(source, forKey:"source")
        aCoder.encodeObject(desc, forKey:"desc")
        aCoder.encodeObject(imgList, forKey:"imgList")
    }
    
}

public class HouseDataRequester: NSObject, NSURLConnectionDelegate {
    
    private static let fieldList = [SolrConst.Filed.ID, SolrConst.Filed.TITLE, SolrConst.Filed.ADDR, SolrConst.Filed.HOUSE_TYPE, SolrConst.Filed.PURPOSE_TYPE, SolrConst.Filed.PRICE, SolrConst.Filed.SIZE,SolrConst.Filed.SOURCE, SolrConst.Filed.IMG_LIST]
    
    private static let requestTimeout = 15.0
    private static let instance = HouseDataRequester()
    
    let urlComp = NSURLComponents()
    
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
    
    func searchById(houseId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        
        var queryitems:[NSURLQueryItem] = []
        
        queryitems.append(NSURLQueryItem(name: SolrConst.Query.MAIN_QUERY, value: "\(SolrConst.Filed.ID):\(houseId)"))
        
        queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: SolrConst.Format.JSON))
        queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))
        
        urlComp.queryItems = queryitems
        performSearch(urlComp, handler: handler)
    }
    
    func searchByCriteria(criteria: SearchCriteria, start: Int, row: Int,
        handler: (totalNum: Int, result: [HouseItem]?, error: NSError?) -> Void) {
            
            let keyword: String? = criteria.keyword
            let area: [City]? = criteria.region
            let price: (Int, Int)? = criteria.price
            let size: (Int, Int)? = criteria.size
            let types: [Int]? = criteria.types
            let sorting: String? = criteria.sorting
            let filters: [String:String]? = criteria.filters
            
            var queryitems:[NSURLQueryItem] = []
            var mainQueryStr:String = "*:*"
            
            // Main Query String (Keyword)
            if let keywordStr = keyword{
                if(keywordStr.characters.count > 0) {
                    let escapedStr = String(format: "\"%@\"~%d", StringUtils.escapeForSolrString(keywordStr), SolrConst.DefaultPhraseSlope)
                    mainQueryStr =
                        "title:\(escapedStr) \(SolrConst.Operator.OR) " +
                        "desc:\(escapedStr) \(SolrConst.Operator.OR) " +
                        "addr:\(escapedStr) \(SolrConst.Operator.OR) " +
                    "community:\(escapedStr)"
                }
            }
            
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.MAIN_QUERY, value: mainQueryStr))
            
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
                    }).joinWithSeparator(" \(SolrConst.Operator.OR) ")
                    
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
                    let allRegionsStr = allRegions.joinWithSeparator(" \(SolrConst.Operator.OR) ")
                    areaConditionStr.append("\(SolrConst.Filed.REGION):(\(allRegionsStr))")
                }
                
                //Compose whole area condition string
                if (areaConditionStr.count > 0) {
                    queryitems.append( NSURLQueryItem(
                        name: SolrConst.Query.FILTER_QUERY,
                        value:areaConditionStr.joinWithSeparator(" \(SolrConst.Operator.OR) "))
                    )
                }
            }
            
            // Purpose Type
            if let typeList = types {
                
                let typeStrList = typeList.map({ (type) -> String in
                    String(type)
                })
                
                let key = SolrConst.Filed.PURPOSE_TYPE
                let value = typeStrList.joinWithSeparator(" \(SolrConst.Operator.OR) ")
                
                queryitems.append( NSURLQueryItem(
                    name: SolrConst.Query.FILTER_QUERY,
                    value:"\(key):(\(value))")
                )
            }
            
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
            
            // Filters
            if let filters = filters {
                for (key, value) in filters {
                    queryitems.append(
                        NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(key):\(value)"))
                }
            }
            
            // Sorting
            if let sorting = sorting {
                queryitems.append(NSURLQueryItem(name: SolrConst.Query.SORTING, value: sorting))
            }
            
            // Field List
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.FILTER_LIST, value: HouseDataRequester.fieldList.joinWithSeparator(",")))
            
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: SolrConst.Format.JSON))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.START, value: String(start)))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.ROW, value: String(row)))
            
            urlComp.queryItems = queryitems
            
            performSearch(urlComp, handler: handler)
    }
    
    private func performSearch(urlComp: NSURLComponents,
        handler: (totalNum: Int, result: [HouseItem]?, error: NSError?) -> Void){
            
            var houseList = [HouseItem]()
            
            if let fullURL = urlComp.URL {
                
                print("fullURL: \(fullURL.absoluteString)")
                
                let request = NSMutableURLRequest(URL: fullURL)
                request.timeoutInterval = HouseDataRequester.requestTimeout
                
                request.HTTPMethod = SolrConst.Server.HTTP_METHOD

                let plainLoginString = (SecretConst.SolrQuery as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                
                if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {
                    
                    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                    
                } else {
                    NSLog("Unable to do Basic Authorization")
                }
                
                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue()){
                        (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                        
                        if(error != nil){
                            NSLog("HTTP request error = %ld, desc = %@", error!.code, error!.localizedDescription)
                            handler(totalNum: 0, result: nil, error: error)
                            return
                        }
                        
                        if(data == nil) {
                            NSLog("HTTP no data")
                            handler(totalNum: 0, result: nil, error: NSError(domain: "No data", code: 0, userInfo: nil))
                            return
                        }
                        
                        let jsonResult = JSON(data: data!)
                        
                        if let response = jsonResult["response"].dictionary {
                            
                            let numOfRecord = response["numFound"]?.intValue ?? 0
                            
                            if let itemList = response["docs"]?.arrayValue {
                                
                                for house in itemList {
                                    let id = house["id"].string ?? ""
                                    let title = house["title"].string ?? ""
                                    let addr = house["addr"].string ?? ""
                                    let houseType = house["house_type"].int ?? 0
                                    let purpose = house["purpose_type"].int ?? 0
                                    let price = house["price"].int ?? 0
                                    let size = house["size"].float ?? 0
                                    let source = house["source"].int  ?? 1
                                    let imgList = house["img"].array?.map({ (jsonObj) -> String in
                                        return jsonObj.stringValue
                                    })
                                    
                                    NSLog("houseItem: \(id)")
                                    
                                    let house:HouseItem = HouseItem.Builder(id: id)
                                        .addTitle(title)
                                        .addAddr(addr)
                                        .addHouseType(houseType)
                                        .addPurposeType(purpose)
                                        .addPrice(price)
                                        .addSize(size)
                                        .addSource(source)
                                        .addImageList(imgList)
                                        .build()
                                    
                                    houseList.append(house)
                                }
                                
                                handler(totalNum: numOfRecord, result: houseList, error: nil)
                            } else {
                                assert(false, "Solr response error:\n \(jsonResult)")
                                handler(totalNum: 0, result: nil, error: NSError(domain: "Solr response error", code: 1, userInfo: nil))
                            }
                        } else {
                            assert(false, "Solr response error:\n \(jsonResult)")
                            handler(totalNum: 0, result: nil, error: NSError(domain: "Solr response error", code: 1, userInfo: nil))
                        }
                }
                
            }
    }
    
    
    private func performSearch(urlComp: NSURLComponents, handler: (result: AnyObject?, error: NSError?) -> Void){
        
        if let fullURL = urlComp.URL {
            
            print("fullURL: \(fullURL.absoluteString)")
            
            let request = NSMutableURLRequest(URL: fullURL)
            request.timeoutInterval = HouseDataRequester.requestTimeout
            
            request.HTTPMethod = SolrConst.Server.HTTP_METHOD
            
            let plainLoginString = (SolrConst.SolrSecret as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            
            if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {
                
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                
            } else {
                NSLog("Unable to do Basic Authorization")
            }
            
            NSURLConnection.sendAsynchronousRequest(
                request, queue: NSOperationQueue.mainQueue()){
                    (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                    
                    if(error != nil){
                        NSLog("HTTP request error = %ld, desc = %@", error!.code, error!.localizedDescription)
                        handler(result: nil, error: error)
                        return
                    }
                    
                    if(data == nil) {
                        NSLog("HTTP no data")
                        handler(result: nil, error: NSError(domain: "No data", code: 0, userInfo: nil))
                        return
                    }
                    
                    let jsonResult = JSON(data: data!)
                    
                    if let response = jsonResult["response"].dictionary {
                        
                        if let itemList = response["docs"]?.arrayObject {
                            handler(result: itemList.first, error: nil)
                        } else {
                            assert(false, "Solr response error:\n \(jsonResult)")
                            handler(result: nil, error: NSError(domain: "Solr response error", code: 1, userInfo: nil))
                        }
                    } else {
                        assert(false, "Solr response error:\n \(jsonResult)")
                        handler(result: nil, error: NSError(domain: "Solr response error", code: 1, userInfo: nil))
                    }
                    
            }
            
        }
    }
}