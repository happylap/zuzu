//
//  SearchBoxStateObserver.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

protocol SearchCriteriaObserverDelegate:class {
    
    func onBeforeCriteriaQuery()
    
    func onAfterCriteriaQuery(itemCount: Int)
    
}

class SearchCriteriaObserver:NSObject {
    
    //If the criteria is not changed for allowedIdleSeconds, the system will fetch the number of houses before the user actually presses the search button
    private let allowedIdleTime = 2.0
    
    private var currentCriteria: SearchCriteria = SearchCriteria()
    
    private let houseReq = HouseDataRequester.getInstance()
    
    private var enabled = false
    
    var delegate: SearchCriteriaObserverDelegate?
    
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
    
    func onCriteriaChanged(criteria: SearchCriteria) {
        
        
        if(!enabled ) {
            return
        }
        
        if(!validateCriteria(criteria) ) {
            return
        }
        
        Log.debug("onCriteriaChanged")
        
        currentCriteria = criteria
        
        ///Reset the timer for query remote item numbers
        
        currentTimer?.invalidate()
        
        delegate?.onBeforeCriteriaQuery()
        
        currentTimer = NSTimer.scheduledTimerWithTimeInterval(allowedIdleTime, target: self, selector: "onNumberOfItemsFetched", userInfo: nil, repeats: false)
    }
    
    func onNumberOfItemsFetched() {
        Log.debug("Start fetchNumberOfItems!")
        
        houseReq.searchByCriteria(currentCriteria, start: 0, row: 0) { (totalNum, result, error) -> Void in
                
            Log.debug("End fetchNumberOfItems = \(totalNum)")
            
            self.delegate?.onAfterCriteriaQuery(totalNum)
            
        }
    }
}