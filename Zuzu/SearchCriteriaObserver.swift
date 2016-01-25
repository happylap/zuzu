//
//  SearchBoxStateObserver.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

// MARK: - Protocols

protocol FastCountCriteriaObserverDelegate:class {
    
    func onBeforeQueryItemCount()
    
    func onAfterQueryItemCount(totalNum: Int)
    
}

protocol RegionItemCountCriteriaObserverDelegate:class {
    
    func onBeforeQueryRegionItemCount()
    
    func onAfterQueryRegionItemCount(facetResult: [String: Int]?)
    
}

protocol SearchCriteriaObserver:class {
    
    func start()
    
    func notifyCriteriaChange(criteria: SearchCriteria)
    
}

// MARK: - Observers

class FastCountCriteriaObserver: NSObject, SearchCriteriaObserver {
    
    //If the criteria is not changed for allowedIdleSeconds, the system will fetch the number of houses before the user actually presses the search button
    private let allowedIdleTime = 2.0
    
    private var currentCriteria: SearchCriteria = SearchCriteria()
    
    private let houseReq = HouseDataRequester.getInstance()
    
    private var enabled = false
    
    var delegate: FastCountCriteriaObserverDelegate?
    
    var currentTimer:NSTimer?
    
    func start() {
        enabled = true
    }
    
    private func validateCriteria(criteria: SearchCriteria) -> Bool {
        
        Log.debug("validateCriteria")
        
        if(criteria.region == nil || criteria.region!.count <= 0) {
            return false
        }
        
        return true
    }
    
    func notifyCriteriaChange(criteria: SearchCriteria) {
        
        if(!enabled ) {
            return
        }
        
        if(!validateCriteria(criteria) ) {
            return
        }
        
        Log.debug("onCriteriaChanged")
        
        ///Make a copy of the current SearchCriteria
        currentCriteria = criteria.copy() as! SearchCriteria
        
        ///Reset the timer for query remote item numbers
        
        currentTimer?.invalidate()
        
        delegate?.onBeforeQueryItemCount()
        
        currentTimer = NSTimer.scheduledTimerWithTimeInterval(allowedIdleTime, target: self, selector: "onFetchNumberOfItems", userInfo: nil, repeats: false)
    }
    
    func onFetchNumberOfItems() {
        Log.enter()

        houseReq.searchByCriteria(currentCriteria, start: 0, row: 0) { (totalNum, result, facetResult, error) -> Void in
            
            Log.debug("Result: totalNum = \(totalNum)")
            
            self.delegate?.onAfterQueryItemCount(totalNum)
            
        }
    }
}


class RegionItemCountCriteriaObserver: NSObject, SearchCriteriaObserver {
    
    private let allowedIdleTime = 2.0
    
    private var currentCriteria: SearchCriteria = SearchCriteria()
    
    private let houseReq = HouseDataRequester.getInstance()
    
    private var enabled = false
    
    var delegate: RegionItemCountCriteriaObserverDelegate?
    
    var currentTimer:NSTimer?
    
    func start() {
        enabled = true
    }
    
    private func validateCriteria(criteria: SearchCriteria) -> Bool {
        
        Log.debug("validateCriteria")
        
        return true
    }
    
    func notifyCriteriaChange(criteria: SearchCriteria) {
        
        if(!enabled ) {
            return
        }
        
        if(!validateCriteria(criteria) ) {
            return
        }
        
        Log.debug("onCriteriaChanged")
        
        ///Make a copy of the current SearchCriteria
        currentCriteria = criteria.copy() as! SearchCriteria
        
        ///Ignore region selection
        currentCriteria.region = nil
        
        ///Reset the timer for query remote item numbers
        
        currentTimer?.invalidate()
        
        delegate?.onBeforeQueryRegionItemCount()
        
        currentTimer = NSTimer.scheduledTimerWithTimeInterval(allowedIdleTime, target: self, selector: "onFetchNumberOfItems", userInfo: nil, repeats: false)
    }
    
    func onFetchNumberOfItems() {
        Log.enter()
        
        houseReq.searchByCriteria(currentCriteria, start: 0, row: 0, facetField: SolrConst.Field.REGION) { (totalNum, result, facetResult, error) -> Void in
            
            Log.debug("Result: Facet = \(facetResult)")
            
            self.delegate?.onAfterQueryRegionItemCount(facetResult)
            
        }
    }
}