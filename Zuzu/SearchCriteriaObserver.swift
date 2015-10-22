//
//  SearchBoxStateObserver.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class SearchCriteriaObserver:NSObject {
    
    //If the criteria is not changed for allowedIdleSeconds, the system will fetch the number of houses before the user actually presses the search button
    let allowedIdleTime = 3.0
    
    let viewController: SearchBoxTableViewController
    
    var currentCriteria: SearchCriteria = SearchCriteria()
    
    let houseReq = HouseDataRequester.getInstance()
    
    var currentTimer:NSTimer?
    
    init(viewController: SearchBoxTableViewController) {
        self.viewController = viewController
        super.init()
    }
    
    func onCriteriaChanged(criteria: SearchCriteria) {
        
        currentCriteria = criteria
        
        ///Reset the timer for query remote item numbers
        
        currentTimer?.invalidate()
        
        currentTimer = NSTimer.scheduledTimerWithTimeInterval(allowedIdleTime, target: self, selector: "fetchNumberOfItems", userInfo: nil, repeats: false)
    }
    
    func fetchNumberOfItems() {
        NSLog("Start fetchNumberOfItems!")
        
        houseReq.searchByCriteria(currentCriteria.keyword, region: currentCriteria.region, price: currentCriteria.price, size: currentCriteria.size, types: currentCriteria.types, start: 0, row: 0) { (totalNum, result, error) -> Void in
            NSLog("End fetchNumberOfItems = \(totalNum)")
            
            if(totalNum != nil && totalNum != 0) {
                self.viewController.fastItemCountLabel.text = "立即觀看 \(totalNum!) 筆出租物件"
            } else {
                self.viewController.fastItemCountLabel.text = nil
            }
        }
    }
}