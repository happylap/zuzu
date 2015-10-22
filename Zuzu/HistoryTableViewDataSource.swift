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
                
                let success = searchItemService.deleteSearchItem(indexPath.row, itemType: self.itemType)
                
                if(success) {
                    ///Reload from storage
                    self.searchData = searchItemService.getSearchItemsByType(self.itemType)
                    
                    tableView.beginUpdates()
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    tableView.endUpdates()
                }
            }
        }
    }
    
}