//
//  LazyDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

public class PersistentTableDataSource {
    
    struct Const {
        static let SAVE_PAGE_PREFIX = "page"
        static let START_PAGE = 1
        static let PAGE_SIZE = 10
    }
    
    var debugStr: String {
        
        get {
            
            
            let pageInfo = "Total Result: \(HouseDataRequester.getInstance().numOfRecord)\n"
                + "Items Per Page: \(Const.PAGE_SIZE)\n"
                + "Last Page No: \(self.lastPageNo)\n"
                + "Total Items in Table: \(self.getItemSize())\n"
            
            
            
            let criteriaInfo = "\n[Criteria]\n"
                + "<Keyword>: \(self.criteria?.keyword)\n"
                + "<Type>: \(self.criteria?.criteriaTypes)\n"
                + "<Price>: \(self.criteria?.criteriaPrice)\n"
                + "<Size>: \(self.criteria?.criteriaSize)\n"
            
            
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
    
    //Paging Info
    var lastPageNo = 0
    
    //Cache Data
    let cachablePageSize:Int
    private var cachedPageStart = 0
    private var cachedData = [HouseItem]()
    
    //Saved Data
    private let savablePageSize:Int
    private var savedPageCount:Int = 0
    private var savedPageData = Set<Int>()
    
    private var retriveRemoteData: ((dataSource: PersistentTableDataSource, pageNo:Int) -> Void)?
    private var dataLoaded: ((dataSource: PersistentTableDataSource, pageNo:Int) -> Void)?
    
    // Designated initializer
    public init(cachablePageSize: Int = 5, savablePageSize: Int = 10) {
        self.cachablePageSize = cachablePageSize
        self.savablePageSize = savablePageSize
    }
    
    //** MARK: - APIs
    //Load some pages for display
    func initData(){
        loadRemoteData(Const.START_PAGE)
    }
    
    func getEstimatedPageSize() -> Int?{
        let requester = HouseDataRequester.getInstance()
        return requester.numOfRecord
    }
    
    func getItemForRow(row:Int) -> HouseItem{
        let index = row - (cachedPageStart-1) * Const.PAGE_SIZE
        //index is negative if scroll back to persistent page
        
        return cachedData[index] //index within memory cache
        
    }
    
    func getItemSize() -> Int{
        return lastPageNo * Const.PAGE_SIZE//cachedData.count + savedPageData.count * Const.PAGE_SIZE
    }
    
    func getCurrentPageNo() -> Int{
        return lastPageNo
    }
    
    //    func getStartPageNo() -> Int{
    //        return cachedPageStart
    //    }
    
    func getCachedPageBound()->(min:Int, max:Int) {
        let min = cachedPageStart
        let max = (cachedPageStart > 0) ? (cachedPageStart-1) + getPageSizeFromItemSize(cachedData.count) : cachedPageStart
        
        return (min, max)
    }
    
    func checkWithinCacheForPage(pageNo:Int) -> Bool {
        if(pageNo < cachedPageStart){
            return false
        }
        
        
        if(pageNo > (cachedPageStart-1) + getPageSizeFromItemSize(cachedData.count)) {
            
            return false
            
        }
        
        return true //within cache
    }
    
    func checkWithinStoreForPage(pageNo:Int) -> Bool {
        
        return savedPageData.contains(pageNo)
    }
    
    func isChacheFull() -> Bool {
        return getPageSizeFromItemSize(cachedData.count) >= cachablePageSize
    }
    
    func loadDataForPage(pageNo: Int) {
        
        assert(!checkWithinCacheForPage(pageNo), "The page is already in cache")
        
        //let savedPageDataRnge = (cacheStartIndex + cachedData.count ...
        
        //Load saved page if the page is in saved pages
        if(checkWithinStoreForPage(pageNo)) {
            loadPersistentData(pageNo)
            return
        }
        
        //Load network data if the page is not local
        loadRemoteData(pageNo)
    }
    
    func setDataRetrivalHandler(handler: (dataSource: PersistentTableDataSource, pageNo:Int) -> Void) {
        retriveRemoteData = handler
    }
    
    func setDataLoadedHandler(handler: (dataSource: PersistentTableDataSource, pageNo:Int) -> Void) {
        dataLoaded = handler
    }
    
    //** MARK: - Callback Functions
    
    func appendDataForPage(pageNo:Int, estimatedPageSize: Int?, data: [HouseItem]) -> Void {
        
        //No more data to be loaded
        if(estimatedPageSize != nil) {
            assert(pageNo <= estimatedPageSize, "Exceed total page size")
        }
        
        //Prune oldest saved data when exceeding savable page size
        //        if(savedPageData.count >= savablePageSize) {
        //            if let oldestPage = savedPageData.minElement() {
        //                pruneOldDataForPage(oldestPage)
        //            }
        //        }
        
        //Previous page
        if(pageNo < self.getCachedPageBound().min){
            
            if(isChacheFull()) {
                self.moveBackwardCachedData(data)
            }
            cachedData.insertContentsOf(data, at: 0)
            print("Current cachedData: \(cachedData.count) \n")
            
            //Next page
        } else if(pageNo > self.getCachedPageBound().max) {
            
            if(isChacheFull()) {
                self.moveForwardCachedData(data)
            }
            cachedData.appendContentsOf(data)
            print("Current cachedData: \(cachedData.count) \n")
            
        } else {
            assert(false, "Page\(pageNo) is already in cache")
        }
        
        //Init cachedPageStart to loaded page
        if(cachedPageStart == 0) {
            cachedPageStart = pageNo
        }
    }
    
    
    //** MARK: - Data Loadrs
    private func loadPersistentData(pageNo:Int) {
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            //print("Run on thread:\(NSThread.currentThread())")
            
            if let restoredItems = self.restorePersistentDataForPage(pageNo) {
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.appendDataForPage(pageNo, estimatedPageSize: nil, data: restoredItems)
                }
            }
        }
    }
    
    private func loadRemoteData(pageNo:Int){
        let requester = HouseDataRequester.getInstance()
        let start = getStartIndexFromPageNo(pageNo)
        let row = Const.PAGE_SIZE
        
        if criteria == nil {
            return
        }
        
        requester.searchByCriteria(criteria!.keyword, price: criteria!.criteriaPrice,
            size: criteria!.criteriaSize, types: criteria!.criteriaTypes,
            start: start, row: row) { (newHouseItems: [HouseItem]) -> Void in
                
                self.appendDataForPage(pageNo, estimatedPageSize: requester.numOfRecord, data: newHouseItems)
                
                self.lastPageNo = pageNo
                
                print("currentPageNo: \(self.lastPageNo) \n")
                
                self.dataLoaded!(dataSource: self, pageNo: pageNo)
        }
        
    }
    
    //** MARK: - Private Functions
    
    
    private func moveForwardCachedData(data: [HouseItem]){
        let pageToBeRemoved = self.cachedPageStart
        
        let rangeToBeRomoved:Range<Int> = (0...Const.PAGE_SIZE-1)
        
        let dataToBeSaved = self.cachedData[rangeToBeRomoved]
        persistDataForPage(pageToBeRemoved, data: [HouseItem](dataToBeSaved))
        
        self.cachedData.removeRange(rangeToBeRomoved) //Shifting cached data window
        
        ++cachedPageStart
    }
    
    private func moveBackwardCachedData(data: [HouseItem]){
        let pageToBeRemoved = (self.cachedPageStart-1) + getPageSizeFromItemSize(cachedData.count)
        
        let rangeToBeRomoved:Range<Int> = (getStartIndexFromPageNo(cachablePageSize)...cachedData.count-1)
        let dataToBeSaved = self.cachedData[rangeToBeRomoved]
        
        persistDataForPage(pageToBeRemoved, data: [HouseItem](dataToBeSaved))
        self.cachedData.removeRange(rangeToBeRomoved) //Shifting cached data window
        
        --cachedPageStart
    }
    
    private func getStartIndexFromPageNo(pageNo: Int) -> Int{
        assert(pageNo > 0, "pageNo should start at 1")
        
        return (pageNo - 1) * Const.PAGE_SIZE
    }
    
    private func getPageSizeFromItemSize(totalItemSize:Int) -> Int {
        let totalPage = ceil(
            Double(totalItemSize) / Double(Const.PAGE_SIZE))
        
        return Int(totalPage)
    }
    
    //** MARK: - Persistence APIs
    private func persistDataForPage(pageNo:Int, data:[HouseItem]){
        
        let fileName = Const.SAVE_PAGE_PREFIX + "\(pageNo)"
        
        let result = DataPersistence.saveData(data, directory: .DocumentDirectory, filename: fileName)
        
        print("persistDataForPage: \(result.success) \n")
        
        if(result.success){
            savedPageData.insert(pageNo)
        }
        
        print("persistDataForPage: \(savedPageData)")
    }
    
    private func restorePersistentDataForPage(pageNo:Int) -> [HouseItem]?{
        
        let fileName = Const.SAVE_PAGE_PREFIX + "\(pageNo)"
        
        let result = DataPersistence.loadDataFromDirectory(.DocumentDirectory, filename: fileName)
        
        print("restorePersistentDataForPage: \(result.success) \n")
        if(result.success){
            savedPageData.remove(pageNo)
        }
        
        return result.data as? [HouseItem]
    }
    
    private func pruneOldDataForPage(pageNo:Int) {
        
        let fileName = Const.SAVE_PAGE_PREFIX + "\(pageNo)"
        
        let result = DataPersistence.deleteDataFromDirectory(.DocumentDirectory, filename: fileName)
        
        print("pruneOldDataForPage: \(result.success) \n")
        
        if(result.success){
            savedPageData.remove(pageNo)
        }
    }
    
}