//
//  FilterOptionTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/4.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

protocol FilterOptionTableViewControllerDelegate {
    
    func onFiltersSelected(filters: [Filter])
    
}

class FilterOptionTableViewController: UITableViewController {
    
    var filterOptionDelegate: FilterOptionTableViewControllerDelegate?
    
    var filterSelected = [Filter]() //filter key
    var filterCheckStatus = [String : Bool]()
    var filterOptions : FilterGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove extra cells when the table height is smaller than the screen
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        if(parent == nil) {
            self.filterOptionDelegate?.onFiltersSelected(filterSelected)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterOptions.filters.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentfilter = filterOptions.filters[indexPath.row]
        
        let label = currentfilter.label
        
        if let status = filterCheckStatus[label] {
            if(status) {
                filterCheckStatus[label] = false
                if let index = filterSelected.indexOf({ (filter) -> Bool in
                    return (filter.key == currentfilter.key) && (filter.value == currentfilter.value)
                }) {
                    
                    filterSelected.removeAtIndex(index)
                }
                
            } else {
                filterCheckStatus[label] = true
                
                let exists = filterSelected.contains({ (filter) -> Bool in
                    return (filter.key == currentfilter.key) && (filter.value == currentfilter.value)
                })
                
                if(!exists) {
                    filterSelected.append(currentfilter)
                }
            }
        } else {
            filterCheckStatus[label] = true
            filterSelected.append(currentfilter)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filter = filterOptions.filters[indexPath.row]
        let label = filter.label
        
        let cell = tableView.dequeueReusableCellWithIdentifier("filterOptionsCell", forIndexPath: indexPath)
        
        
        if let checked = filterCheckStatus[label] {
            
            if(checked) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        cell.textLabel?.text = filterOptions.filters[indexPath.row].label
        
        return cell
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
