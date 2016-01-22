//
//  SearchBoxStateObserver.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

class SearchCriteriaObserver:NSObject {
    
    //If the criteria is not changed for allowedIdleSeconds, the system will fetch the number of houses before the user actually presses the search button
    private let allowedIdleTime = 2.0
    
    private let viewController: SearchBoxTableViewController
    
    private var currentCriteria: SearchCriteria = SearchCriteria()
    
    private let houseReq = HouseDataRequester.getInstance()
    
    private var enabled = false
    
    var currentTimer:NSTimer?
    
    init(viewController: SearchBoxTableViewController) {
        self.viewController = viewController
        super.init()
    }
    
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
        
        //Reset fast house count label
        self.viewController.fastItemCountLabel.hidden = false
        self.viewController.fastItemCountLabel.alpha = 0
        self.viewController.fastItemCountLabel.text = nil
        
        currentTimer = NSTimer.scheduledTimerWithTimeInterval(allowedIdleTime, target: self, selector: "fetchNumberOfItems", userInfo: nil, repeats: false)
    }
    
    func fetchNumberOfItems() {
        Log.debug("Start fetchNumberOfItems!")
        
        houseReq.searchByCriteria(currentCriteria, start: 0, row: 0) { (totalNum, result, error) -> Void in
                
            Log.debug("End fetchNumberOfItems = \(totalNum)")
            
            if(totalNum != 0) {
                self.viewController.fastItemCountLabel.text = "立即觀看 \(totalNum) 筆出租物件"
                self.viewController.fastItemCountLabel.fadeIn(0.5, delay: 0)
                
            } else {
                self.viewController.fastItemCountLabel.text = nil
            }
        }
    }
}