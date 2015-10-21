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
    
    var searchData:[SearchItem]?
    
    private let cellID = "searchItemCell"
    
    private let viewController : UIViewController?
    
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
    
}