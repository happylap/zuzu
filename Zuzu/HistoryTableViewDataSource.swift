//
//  HistoryTableViewDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit

public class SearchItemTableViewDataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    let searchItemsDataStore : SearchHistoryDataStore = UserDefaultsSearchHistoryDataStore.getInstance()
    
    var itemType: SearchType = .SavedSearch {
        
        didSet {
            
            self.searchData = self.getSearchitemsByType(itemType)
            
        }
    }
    
    private var searchData:[SearchItem]?
    
    private let cellID = "searchItemCell"
    
    private let viewController : UIViewController?
    
    private func getSearchitemsByType(type: SearchType) ->  [SearchItem]?{
        
        var data:[SearchItem]?
        
        if let itemList = searchItemsDataStore.loadSearchItems() {
            data = itemList.filter({ (item: SearchItem) -> Bool in
                return item.type == itemType
            })
        }
        
        return data
    }
    
    init(viewController : UIViewController) {
        self.viewController = viewController
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if(searchData == nil) {
            return 0
        }
        
        return searchData!.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let cell = tableView.dequeueReusableCellWithIdentifier(cellID) {
            
            if let searchData = self.searchData {
                
                let search = searchData[indexPath.row]
                
                cell.textLabel!.text = search.title
                cell.detailTextLabel!.text = search.detail
                
//                if(indexPath.row == searchData.endIndex - 1) {
//                    cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(cell.bounds)/2.0, 0, CGRectGetWidth(cell.bounds)/2.0)
//                }
                return cell
            }
        } else {
            assert(false, "Failed to prepare cell instance")
        }
        
        return UITableViewCell()
    }
    
    public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if(editingStyle == .Delete) {
            
            assert(self.searchData != nil,
                "Impossible to be inside this deletion delegate function, if there is no search item")
            
            if(self.searchData != nil) {
                
                if let itemList = searchItemsDataStore.loadSearchItems() {
                    var allItems = itemList
                    
                    assert(allItems.count > 0,
                        "Impossible to be inside this deletion delegate function, if there is no persistent search item")
                    
                    if(allItems.count <= 0) {
                        return
                    }
                    ///Delete & Persist Result
                    var indexForType = 0
                    for (index, item) in allItems.enumerate() {
                        if(item.type == self.itemType){
                            
                            if(indexForType == indexPath.row) {
                                allItems.removeAtIndex(index)
                                break
                            }
                            
                            indexForType++
                        }
                    }
                    self.searchItemsDataStore.saveSearchItems(allItems)
                    
                    ///Reload from storage
                    self.searchData = self.getSearchitemsByType(itemType)
                    
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    tableView.endUpdates()
                }
            }
        }
    }
    
}