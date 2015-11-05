//
//  FilterOptionTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/4.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

protocol FilterOptionTableViewControllerDelegate {
    
    func onFiltersSelected(filterGroup: FilterGroup)
    
}

class FilterOptionTableViewController: UITableViewController {
    
    var filterOptionDelegate: FilterOptionTableViewControllerDelegate?
    
    var rowsSelected = [NSIndexPath]()
    
    var filterSelected = [Filter]() //filter key
    
    var filterOptions : FilterGroup!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Remove extra cells when the table height is smaller than the screen
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        
        if(parent == nil) {
            
            for indexPath in self.rowsSelected {
                
                let filter = filterOptions.filters[indexPath.row]
                
                ///No need to add "unlimited" option
                if(filter.key != Filter.defaultKeyUnlimited) {
                    self.filterSelected.append(filter)
                }
            }
            
            ///Consider make a copy method
            let filtergroup =
            FilterGroup(label: filterOptions.label, type: filterOptions.type, filters: self.filterSelected)
            filtergroup.logicType = filterOptions.logicType
            filterOptions.choiceType = filterOptions.choiceType
            
            self.filterOptionDelegate?.onFiltersSelected(filtergroup)
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
        let allFilters = filterOptions.filters
        let choiceType:ChoiceType! = filterOptions.choiceType
        let unlimitIndex = allFilters.indexOf({ (filter) -> Bool in
            return (filter.key == Filter.defaultKeyUnlimited)
        })
        
        NSLog("didSelectRowAtIndexPath %@", indexPath)
        
        if(choiceType == .SingleChoice) {
            //Clear all selection before selecting other choices
            rowsSelected.removeAll()
            tableView.reloadData()
            
        } else {
            if(unlimitIndex == indexPath.row) {
                ///The user selects unlimited option
                
                rowsSelected.removeAll()
                tableView.reloadData()
            } else {
                ///The user selects other options
                
                if let unlimitIndex = unlimitIndex {
                    let unlimitIndexPath = NSIndexPath(forRow: unlimitIndex, inSection: 0)
                    
                    if let index = rowsSelected.indexOf(unlimitIndexPath) {
                        rowsSelected.removeAtIndex(index)
                    }
                    
                    tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: unlimitIndex, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
        }
        
        ///Toggle Check /Unchecked state
        if let index = rowsSelected.indexOf(indexPath) {
            rowsSelected.removeAtIndex(index)
        } else {
            rowsSelected.append(indexPath)
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentFilter = filterOptions.filters[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("filterOptionsCell", forIndexPath: indexPath)
        
        
        
        if rowsSelected.contains(indexPath) {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
        cell.textLabel?.text = currentFilter.label
        
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
