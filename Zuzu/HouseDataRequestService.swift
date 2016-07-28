//
//  HouseDataRequester.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON

private let Log = Logger.defaultLogger

struct SolrConst {

    static let DefaultFacetLimit = 400
    static let DefaultPhraseSlope = 2

    struct Server {
        static let SCHEME = "http"

        #if DEBUG
        static let HOST = HostConstStage.SolrHost
        static let PORT = HostConstStage.SolrPort
        static let PATH = HostConstStage.SolrPath
        #else
        static let HOST = HostConst.SolrHost
        static let PORT = HostConst.SolrPort
        static let PATH = HostConst.SolrPath
        #endif

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
        static let FACET = "facet"
        static let FACET_FIELD = "facet.field"
        static let FACET_LIMIT = "facet.limit"
        static let FACET_SORT = "facet.sort"
    }

    struct Operator {
        static let OR = "OR"
        static let AND = "AND"
    }

    struct Field {
        static let ID = "id"
        static let TITLE = "title"
        static let ADDR = "addr"
        static let PURPOSE_TYPE = "purpose_type"
        static let HOUSE_TYPE = "house_type"
        static let PREVIOUS_PRICE = "previous_price"
        static let PRICE = "price"
        static let SIZE = "size"
        static let SOURCE = "source"
        static let CITY = "city"
        static let REGION = "region"
        static let IMG_LIST = "img"
        static let PARENT = "parent"
        static let CHILDREN = "children"
    }

    struct Format {
        static let JSON = "json"
    }

}

class HouseItem: NSObject, NSCoding {

    class Builder: NSObject {

        private var id: String?
        private var title: String?
        private var addr: String?
        private var houseType: Int?
        private var purposeType: Int?
        private var previousPrice: Int?
        private var price: Int?
        private var size: Float?
        private var source: Int?
        private var desc: String?
        private var imgList: [String]?
        private var children: [String]?

        private func validateParams() -> Bool {
            return (self.id != nil) && (self.title != nil)
                && (self.price != nil) && (self.size != nil)
        }

        init(id: String) {
            self.id = id
        }

        func addTitle(title: String) -> Builder {
            self.title = title
            return self
        }

        func addAddr(addr: String) -> Builder {
            self.addr = addr
            return self
        }

        func addHouseType(type: Int) -> Builder {
            self.houseType = type
            return self
        }

        func addPurposeType(usage: Int) -> Builder {
            self.purposeType = usage
            return self
        }

        func addPreviousPrice(previousPrice: Int?) -> Builder {
            self.previousPrice = previousPrice
            return self
        }

        func addPrice(price: Int) -> Builder {
            self.price = price
            return self
        }

        func addSize(size: Float) -> Builder {
            self.size = size
            return self
        }

        func addSource(source: Int) -> Builder {
            self.source = source
            return self
        }

        func addDesc(desc: String) -> Builder {
            self.desc = desc
            return self
        }

        func addImageList(imgList: [String]?) -> Builder {
            self.imgList = imgList
            return self
        }

        func addChildren(children: [String]?) -> Builder {
            self.children = children
            return self
        }

        func build() -> HouseItem {
            assert(validateParams(), "Incorrect HouseItem building params")
            return HouseItem(builder: self)
        }
    }

    /// HouseItem Members
    let id: String
    let title: String
    let addr: String
    let houseType: Int
    let purposeType: Int
    let previousPrice: Int?
    let price: Int
    let source: Int
    let size: Float
    let desc: String?
    let imgList: [String]?
    let children: [String]?

    private init(builder: Builder) {
        /// Assign default value for mandatory fields
        /// cause we don't want some exceptions happen in the App because of some incorrect data in the backend
        self.id = builder.id ?? ""
        self.title = builder.title ?? ""
        self.addr = builder.addr ?? ""
        self.houseType = builder.houseType ?? 0
        self.purposeType = builder.purposeType ?? 0
        self.previousPrice = builder.previousPrice
        self.price = builder.price ?? 0
        self.size = builder.size ?? 0
        self.source = builder.source ?? 0
        self.desc = builder.desc
        self.imgList = builder.imgList
        self.children = builder.children

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
        let children = decoder.decodeObjectForKey("children") as? [String] ?? [String]()

        var previousPrice: Int?
        if decoder.decodeObjectForKey("previousPrice") != nil {
            previousPrice = decoder.decodeIntegerForKey("previous_price") as Int
        }

        let builder: Builder = Builder(id: id)
            .addTitle(title)
            .addAddr(addr)
            .addHouseType(houseType)
            .addPurposeType(purposeType)
            .addPreviousPrice(previousPrice)
            .addPrice(price)
            .addSize(size)
            .addSource(source)
            .addDesc(desc)
            .addImageList(imgList)
            .addChildren(children)

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
        aCoder.encodeObject(children, forKey:"children")
        if let pPrice = previousPrice {
            aCoder.encodeInteger(pPrice, forKey: "previousPrice")
        }
    }

}

typealias onQueryComplete = (totalNum: Int, result: [HouseItem]?, facetResult: [String: Int]?, error: NSError?) -> Void

public class HouseDataRequestService: NSObject, NSURLConnectionDelegate {

    private static let defaultFieldList = [SolrConst.Field.ID, SolrConst.Field.TITLE, SolrConst.Field.ADDR, SolrConst.Field.HOUSE_TYPE, SolrConst.Field.PURPOSE_TYPE, SolrConst.Field.PREVIOUS_PRICE, SolrConst.Field.PRICE, SolrConst.Field.SIZE, SolrConst.Field.SOURCE, SolrConst.Field.IMG_LIST, SolrConst.Field.CHILDREN]

    private static let requestTimeout = 15.0
    private static let instance = HouseDataRequestService()

    let urlComp = NSURLComponents()

    public static func getInstance() -> HouseDataRequestService {
        return instance
    }

    // Designated initializer
    private override init() {
        super.init()

        urlComp.scheme = SolrConst.Server.SCHEME
        urlComp.host = SolrConst.Server.HOST
        urlComp.port = SolrConst.Server.PORT
        urlComp.path = SolrConst.Server.PATH
    }

    // MARK: - Public House Item Query APIs

    // Search house items by an item Id
    func searchById(houseId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {

        var queryitems: [NSURLQueryItem] = []

        queryitems.append(NSURLQueryItem(name: SolrConst.Query.MAIN_QUERY, value: "\(SolrConst.Field.ID):\(houseId)"))

        queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: SolrConst.Format.JSON))
        queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))

        urlComp.queryItems = queryitems
        performSearch(urlComp, handler: handler)
    }

    // Search house items by an list of item Ids
    func searchByIds(houseIds: [String], fieldList: [String] = defaultFieldList,
        onCompleteHandler: onQueryComplete) {

            var queryitems: [NSURLQueryItem] = []

            // Main Query String (Keyword)
            var mainQuery: [String] = [String]()

            mainQuery.appendContentsOf(
                houseIds.map({ (houseId) -> String in
                    return "id:\(houseId)"
                })
            )

            queryitems.append(NSURLQueryItem(name: SolrConst.Query.MAIN_QUERY, value:mainQuery.joinWithSeparator(" \(SolrConst.Operator.OR) ")))

            // Field List
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.FILTER_LIST, value: fieldList.joinWithSeparator(",")))

            queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: SolrConst.Format.JSON))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.START, value: "0"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.ROW, value: String(houseIds.count)))
            //queryitems.append(NSURLQueryItem(name: SolrConst.Query.ROW, value: "20")) // for test

            urlComp.queryItems = queryitems
            performSearch(urlComp, onCompleteHandler: onCompleteHandler)
    }

    // Search house items by an set of criteria
    func searchByCriteria(criteria: SearchCriteria, fieldList: [String] = defaultFieldList,
        start: Int, row: Int, allowDuplicate: Bool = false, facetField: String? = nil,
        onCompleteHandler: onQueryComplete) {

            let keyword: String? = criteria.keyword
            let area: [City]? = criteria.region
            let price: (Int, Int)? = criteria.price
            let size: (Int, Int)? = criteria.size
            let types: [Int]? = criteria.types
            let sorting: String? = criteria.sorting
            let filters: [String:String]? = criteria.filters

            var queryitems: [NSURLQueryItem] = []
            var mainQueryStr: String = "*:*"

            // Main Query String (Keyword)
            if let keywordStr = keyword {
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

                    areaConditionStr.append("\(SolrConst.Field.CITY):(\(allCitiesStr))")
                }

                //Handle Regions
                let cityWithRegions = selectedCity.filter({ (city: City) -> Bool in
                    return !city.regions.contains(Region.allRegions)
                })

                var allRegions: [String] = [String]()

                for city in cityWithRegions {
                    allRegions.appendContentsOf(
                        city.regions.map({ (region) -> String in
                            return "\(region.code)"
                        })
                    )
                }

                if(allRegions.count > 0) {
                    let allRegionsStr = allRegions.joinWithSeparator(" \(SolrConst.Operator.OR) ")
                    areaConditionStr.append("\(SolrConst.Field.REGION):(\(allRegionsStr))")
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

                let key = SolrConst.Field.PURPOSE_TYPE
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
                    NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(SolrConst.Field.PRICE):[\(priceFrom) TO \(priceTo)]"))
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
                    NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(SolrConst.Field.SIZE):[\(sizeFrom) TO \(sizeTo)]"))
            }

            // Filters
            if let filters = filters {
                for (key, value) in filters {
                    queryitems.append(
                        NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "\(key):\(value)"))
                }
            }

            // Remove Duplicate
            if(!allowDuplicate) {
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FILTER_QUERY, value: "-\(SolrConst.Field.PARENT):*"))
            }

            // Facet Setting
            if let facetField = facetField {
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FACET, value: "true"))
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FACET_LIMIT, value: String(SolrConst.DefaultFacetLimit)))
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FACET_SORT, value: "count"))
                queryitems.append(
                    NSURLQueryItem(name: SolrConst.Query.FACET_FIELD, value: facetField))

            }

            // Sorting
            if let sorting = sorting {
                queryitems.append(NSURLQueryItem(name: SolrConst.Query.SORTING, value: sorting))
            }

            // Field List
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.FILTER_LIST, value: fieldList.joinWithSeparator(",")))

            queryitems.append(NSURLQueryItem(name: SolrConst.Query.WRITER_TYPE, value: SolrConst.Format.JSON))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.INDENT, value: "true"))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.START, value: String(start)))
            queryitems.append(NSURLQueryItem(name: SolrConst.Query.ROW, value: String(row)))

            urlComp.queryItems = queryitems

            performSearch(urlComp, onCompleteHandler: onCompleteHandler)
    }

    private func performSearch(urlComp: NSURLComponents,
        onCompleteHandler: onQueryComplete) {

            var houseList = [HouseItem]()
            var numOfRecord: Int = 0
            var facetFieldResult: [String: Int]?

            if let fullURL = urlComp.URL {

                Log.debug("fullURL: \(fullURL.absoluteString)")

                let request = NSMutableURLRequest(URL: fullURL)
                request.timeoutInterval = HouseDataRequestService.requestTimeout

                request.HTTPMethod = SolrConst.Server.HTTP_METHOD

                let plainLoginString = (SecretConst.SolrQuery as NSString).dataUsingEncoding(NSUTF8StringEncoding)

                if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {

                    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

                } else {
                    Log.debug("Unable to do Basic Authorization")
                }

                NSURLConnection.sendAsynchronousRequest(
                    request, queue: NSOperationQueue.mainQueue()) {
                        (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in

                        if let error = error {
                            Log.debug("HTTP request error = \(error.code), desc = \(error.localizedDescription)")
                            onCompleteHandler(totalNum: 0, result: nil, facetResult: nil, error: error)
                            return
                        }

                        if(data == nil) {
                            Log.debug("HTTP no data")
                            onCompleteHandler(totalNum: 0, result: nil, facetResult: nil, error: NSError(domain: "No data", code: 0, userInfo: nil))
                            return
                        }

                        let jsonResult = JSON(data: data!)

                        if let response = jsonResult["response"].dictionary,
                            let numFound = response["numFound"]?.int,
                            let itemList = response["docs"]?.array {

                                // Update number of items
                                numOfRecord = numFound

                                for house in itemList {
                                    let id = house["id"].string ?? ""
                                    let title = house["title"].string ?? ""
                                    let addr = house["addr"].string ?? ""
                                    let houseType = house["house_type"].int ?? 0
                                    let purpose = house["purpose_type"].int ?? 0
                                    let previousPrice = house["previous_price"].int
                                    let price = house["price"].int ?? 0
                                    let size = house["size"].float ?? 0
                                    let source = house["source"].int  ?? 1

                                    let imgList = house["img"].array?.map({ (jsonObj) -> String in
                                        return jsonObj.stringValue
                                    })

                                    let children = house["children"].array?.map({ (jsonObj) -> String in
                                        return jsonObj.stringValue
                                    })

                                    Log.debug("houseItem: \(id)")

                                    let house: HouseItem = HouseItem.Builder(id: id)
                                        .addTitle(title)
                                        .addAddr(addr)
                                        .addHouseType(houseType)
                                        .addPurposeType(purpose)
                                        .addPreviousPrice(previousPrice)
                                        .addPrice(price)
                                        .addSize(size)
                                        .addSource(source)
                                        .addImageList(imgList)
                                        .addChildren(children)
                                        .build()

                                    houseList.append(house)
                                }

                        } else {
                            assert(false, "Solr response error:\n \(jsonResult)")
                            onCompleteHandler(totalNum: 0, result: nil, facetResult: nil, error: NSError(domain: "Solr response error", code: 1, userInfo: nil))
                        }

                        /// Check facet
                        if let facetCounts = jsonResult["facet_counts"].dictionary {
                            if let facetFields = facetCounts["facet_fields"]?.dictionary {

                                if let queryItem = urlComp.queryItems?.filter({ (queryItem) -> Bool in
                                    return (queryItem.name == SolrConst.Query.FACET_FIELD)
                                }).first {

                                    if let facetFieldName = queryItem.value,
                                        let facetCountArray = facetFields[facetFieldName]?.arrayValue {

                                            facetFieldResult = [String: Int]()

                                            for (index, item) in facetCountArray.enumerate() {
                                                if(index % 2 == 0) {
                                                    facetFieldResult![item.stringValue] = facetCountArray[index + 1].intValue
                                                }
                                            }
                                    }
                                }
                            }
                        }

                        /// Invoke onCompleteHandler as final response
                        onCompleteHandler(totalNum: numOfRecord, result: houseList, facetResult: facetFieldResult, error: nil)
                }

            }
    }


    private func performSearch(urlComp: NSURLComponents, handler: (result: AnyObject?, error: NSError?) -> Void) {

        if let fullURL = urlComp.URL {

            Log.debug("fullURL: \(fullURL.absoluteString)")

            let request = NSMutableURLRequest(URL: fullURL)
            request.timeoutInterval = HouseDataRequestService.requestTimeout

            request.HTTPMethod = SolrConst.Server.HTTP_METHOD

            let plainLoginString = (SecretConst.SolrQuery as NSString).dataUsingEncoding(NSUTF8StringEncoding)

            if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {

                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

            } else {
                Log.debug("Unable to do Basic Authorization")
            }

            NSURLConnection.sendAsynchronousRequest(
                request, queue: NSOperationQueue.mainQueue()) {
                    (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in

                    if let error = error {
                        Log.debug("HTTP request error = \(error.code), desc = \(error.localizedDescription)")
                        handler(result: nil, error: error)
                        return
                    }

                    if(data == nil) {
                        Log.debug("HTTP no data")
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
