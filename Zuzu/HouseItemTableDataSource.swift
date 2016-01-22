//
//  TableDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/8.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


//
//  LazyDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

/**
 The class is developed in a rush, need to refactor to a more common module
 
 1) highly coupled with other modules, can not work as standalone library
 2) It might block UI a little bit when loading data from storage
 */

private let Log = Logger.defaultLogger

public class HouseItemTableDataSource {
    
    struct Const {
        static let SAVE_PAGE_PREFIX = "page"
        static let START_PAGE = 1
        static let PAGE_SIZE = 10
    }
    
    var debugStr: String {
        
        get {
            let pageInfo = "Total Result: \(estimatedTotalResults)\n"
                + "Items Per Page: \(Const.PAGE_SIZE)\n"
                + "Last Page No: \(self.currentPage)\n"
                + "Total Items in Table: \(self.getSize())\n"
            
            
            
            let criteriaInfo = "\n[Criteria]\n"
                + "<Keyword>: \(self.criteria?.keyword)\n"
                + "<Type>: \(self.criteria?.types)\n"
                + "<Price>: \(self.criteria?.price)\n"
                + "<Size>: \(self.criteria?.size)\n"
//                + "<City>: \(self.criteria?)\n"
//                + "<Region>: \(self.criteria?.size)\n"
            
            
            let host = HouseDataRequester.getInstance().urlComp.host ?? ""
            let port = HouseDataRequester.getInstance().urlComp.port ?? 0
            let path = HouseDataRequester.getInstance().urlComp.path ?? ""
            let query = HouseDataRequester.getInstance().urlComp.query ?? ""
            
            let queryInfo = "\n[Last HTTP Request]\n"
                + "<Host>: \n\(host) \n"
                + "<Port>: \(port) \n"
                + "<Path>: \(path) \n"
                + "<Query>: \n\(query) \n"
            
            let urlInfo = "\n[Full URL]\n"
                + "\(HouseDataRequester.getInstance().urlComp.URL ?? nil)"
            
            return pageInfo + criteriaInfo + queryInfo + urlInfo
        }
    }
    
    var criteria:SearchCriteria?
    private var loadStartTime: NSDate?
    var loadingDuration: Double?
    
    private var isLoadingData = false
    
    //Paging Info
    var currentPage: Int {
        
        get {
            return calculateNumOfPages(cachedData.count)
        }
        
    }
    
    //Total Number of items
    var estimatedTotalResults:Int = 0
    
    //Cache Data
    private var cachedData = [HouseItem]()
    
    private var onDataLoaded: ((dataSource: HouseItemTableDataSource, pageNo:Int, error: NSError?) -> Void)?
    
    // Designated initializer
    public init() {
        
    }
    
    //** MARK: - APIs
    
    //Load some pages for display
    func initData(){
        //Remove previous data for initial data fetching
        cachedData.removeAll()
        
        loadStartTime = NSDate()
        loadRemoteData(Const.START_PAGE)
    }
    
    func getItemForRow(row:Int) -> HouseItem{
        return cachedData[row] //index within memory cache
    }
    
    func getSize() -> Int{
        return cachedData.count
    }
    
    func loadDataForPage(pageNo: Int) {
        if(isLoadingData) {
            Log.debug("loadDataForPage: Duplicate page request for [\(pageNo)]")
            return
        }
        
        loadStartTime = NSDate()
        loadRemoteData(pageNo)
    }
    
    func setDataLoadedHandler(handler: (dataSource: HouseItemTableDataSource, pageNo:Int, error: NSError?) -> Void) {
        onDataLoaded = handler
    }
    
    //** MARK: - Callback Functions
    
    func appendDataForPage(pageNo:Int, data: [HouseItem]) -> Void {
        
        cachedData.appendContentsOf(data)
    }
    
    
    //** MARK: - Private Functions
    
    private func loadRemoteData(pageNo:Int){
        let requester = HouseDataRequester.getInstance()
        let start = getStartIndexFromPageNo(pageNo)
        let row = Const.PAGE_SIZE
        
        if criteria == nil {
            return
        }
        
        isLoadingData = true
        
        Log.debug("loadRemoteData: pageNo = \(pageNo)")
        
        requester.searchByCriteria(criteria!, start: start, row: row) { (totalNum, result, error) -> Void in
            
            self.estimatedTotalResults = totalNum
            
            if let result = result {
                self.appendDataForPage(pageNo, data: result)
            }
            
            if let loadStartTime = self.loadStartTime {
                let loadEndTime = NSDate()
                self.loadingDuration = loadEndTime.timeIntervalSinceDate(loadStartTime)
            }
            
            //Callback to table
            self.onDataLoaded!(dataSource: self, pageNo: pageNo, error: error)
            
            self.isLoadingData = false
        }
        
    }
    
    private func getStartIndexFromPageNo(pageNo: Int) -> Int{
        assert(pageNo > 0, "pageNo should start at 1")
        
        return (pageNo - 1) * Const.PAGE_SIZE
    }
    
    private func calculateNumOfPages(numOfItems:Int) -> Int{
        return Int(ceil(Double(numOfItems) / Double(Const.PAGE_SIZE)))
    }
    
}