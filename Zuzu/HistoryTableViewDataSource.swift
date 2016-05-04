//
//  HistoryTableViewDataSource.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit

private let Log = Logger.defaultLogger

public class SearchItemTableViewDataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var criteriaToLoad: SearchCriteria?
    
    let searchItemService : SearchItemService = SearchItemService.getInstance()
    
    var itemType: SearchType = .SavedSearch {
        
        didSet {
            self.searchData = searchItemService.getSearchItemsByType(itemType)
            tableViewController.searchItemTable.reloadData()
        }
    }
    
    private var searchData:[SearchItem]?
    
    private let cellID = "searchItemCell"
    
    private let tableViewController: SearchBoxTableViewController!
    
    init(tableViewController: SearchBoxTableViewController) {
        self.tableViewController = tableViewController
    }
    
    func handleLoadCriteria(alertAction: UIAlertAction!) -> Void {
        if let criteria = self.criteriaToLoad {
            self.tableViewController.currentCriteria = criteria
            
            //Scroll to the top of the table to see the search item table fully
            tableViewController.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            
            ///GA Tracker
            tableViewController.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                action: GAConst.Action.UIActivity.History, label: GAConst.Label.History.Load)
        }
    }
    
    func cancelLoadCriteria(alertAction: UIAlertAction!) {
        self.criteriaToLoad = nil
    }
    
    private func confirmLoadCriteria() {
        let alert = UIAlertController(title: "載入搜尋條件", message: "是否確認載入此搜尋條件?", preferredStyle: .ActionSheet)
        
        let loadAction = UIAlertAction(title: "載入", style: .Default, handler: handleLoadCriteria)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: cancelLoadCriteria)
        
        alert.addAction(loadAction)
        alert.addAction(cancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.tableViewController.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.tableViewController.view.bounds.size.width / 2.0, y: self.tableViewController.view.bounds.size.height / 2.0, width: 1.0, height: 1.0)
        
        self.tableViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var itemSize = 0
        
        if(searchData == nil) {
            itemSize = 0
        }else {
            itemSize = searchData!.count
        }
        
        Log.debug("Number of search history = \(itemSize)")

        if (itemSize == 0) {
            
            if(itemType == .SavedSearch) {
                tableViewController
                    .showNoSearchHistoryMessage(SystemMessage.INFO.EMPTY_SAVED_SEARCH)
            }
            
            if(itemType == .HistoricalSearch) {
                tableViewController
                    .showNoSearchHistoryMessage(SystemMessage.INFO.EMPTY_HISTORICAL_SEARCH)
            }
        } else {
            tableViewController.hideNoSearchHistoryMessage()
        }
        
        return itemSize
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        assert(self.searchData != nil,
            "Impossible to be inside this delegate function, if there is no search item")
        
        if(searchData == nil) {
            return
        }
        
        self.criteriaToLoad = searchData![indexPath.row].criteria
        
        self.confirmLoadCriteria()
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
                
                let success = searchItemService.deleteSearchItem(indexPath.row, itemType: self.itemType)
                
                if(success) {
                    ///Reload from storage
                    self.searchData = searchItemService.getSearchItemsByType(self.itemType)
                    
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        }
    }
    
}