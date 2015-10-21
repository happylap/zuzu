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
    
    var criteriaToLoad: SearchCriteria?
    
    let searchItemsDataStore : SearchHistoryDataStore = UserDefaultsSearchHistoryDataStore.getInstance()
    
    var itemType: SearchType = .SavedSearch {
        
        didSet {
            
            self.searchData = self.getSearchitemsByType(itemType)
            tableViewController.searchItemTable.reloadData()
        }
    }
    
    private var searchData:[SearchItem]?
    
    private let cellID = "searchItemCell"
    
    private let tableViewController: SearchBoxTableViewController!
    
    private func getSearchitemsByType(type: SearchType) ->  [SearchItem]?{
        
        var data:[SearchItem]?
        
        if let itemList = searchItemsDataStore.loadSearchItems() {
            data = itemList.filter({ (item: SearchItem) -> Bool in
                return item.type == itemType
            })
        }
        
        return data
    }
    
    init(tableViewController: SearchBoxTableViewController) {
        self.tableViewController = tableViewController
    }
    
    func handleLoadCriteria(alertAction: UIAlertAction!) -> Void {
        if let criteria = self.criteriaToLoad {
            self.tableViewController.currentCriteria = criteria
        }
    }
    
    func cancelLoadCriteria(alertAction: UIAlertAction!) {
        self.criteriaToLoad = nil
    }
    
    private func confirmLoadCriteria() {
        let alert = UIAlertController(title: "載入搜尋條件", message: "是否確認載入此搜尋條件?", preferredStyle: .ActionSheet)
        
        let DeleteAction = UIAlertAction(title: "載入", style: .Destructive, handler: handleLoadCriteria)
        let CancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: cancelLoadCriteria)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.tableViewController.view
        alert.popoverPresentationController?.sourceRect = CGRectMake(self.tableViewController.view.bounds.size.width / 2.0, self.tableViewController.view.bounds.size.height / 2.0, 1.0, 1.0)
        
        self.tableViewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if(searchData == nil) {
            return 0
        }
        
        return searchData!.count
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