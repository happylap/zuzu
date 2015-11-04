//
//  FilterTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class FilterTableViewController: UITableViewController {
    
    struct ViewTransConst {
        static let displayFilterOptions:String = "displayFilterOptions"
    }
    
    //var selectedFilterGroup : FilterGroup?
    
    var filterSelected = [String : String]()
    var checkStatus = [String : Bool]()
    var resultItems = [(group: String, filterGroups: [FilterGroup])]()
    
    // MARK: - Private Utils
    private static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [(group: String, filterGroups: [FilterGroup])]{
        
        var resultItems = [(group: String, filterGroups: [FilterGroup])]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[criteriaLabel].arrayValue
                
                NSLog("\(criteriaLabel) = %d", items.count)
                
                for itemJsonObj in items {
                    let group = itemJsonObj["group"].stringValue
                    
                    if let items = itemJsonObj["items"].array {
                        
                        let allFilters = items.map({ (json) -> FilterGroup in
                            let label = json["label"].stringValue
                            let type = json["type"].intValue
                            let commonKey = json["filterKey"].stringValue
                            
                            
                            if let filters = json["filters"].array {
                                
                                let filters = filters.map({ (json) -> Filter in
                                    let label = json["label"].stringValue
                                    let value = json["value"].stringValue
                                    if let key = json["key"].string {
                                        return Filter(label: label, key: key, value: value)
                                    } else {
                                        return Filter(label: label, key: commonKey, value: value)
                                    }
                                })
                                
                                let filterGroup = FilterGroup(label: label,
                                    type: FilterType(rawValue: type)!,
                                    filters: filters)
                                
                                return filterGroup
                                
                            } else {
                               
                                let value = json["filterValue"].stringValue
                                
                                let filterGroup = FilterGroup(label: label,
                                    type: FilterType(rawValue: type)!,
                                    filters: [Filter(label: label, key: commonKey, value: value)])
                                
                                return filterGroup
                                
                            }
                        })
                        
                        resultItems.append( (group: group, filterGroups: allFilters))
                        
                    }
                    
                    
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load json file %@", error)
                
            }
        }
        
        return resultItems
    }
    
    // MARK: - Action Handlers
    @IBAction func onFilterSelectionDone(sender: UIBarButtonItem) {
        
        navigationController?.popViewControllerAnimated(true)
        
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultItems = FilterTableViewController.loadFilterData("resultFilters", criteriaLabel: "advancedFilters")
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return resultItems.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return resultItems[section].filterGroups.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filterGroup = resultItems[indexPath.section].filterGroups[indexPath.row]
        
        let type = filterGroup.type
        let label = filterGroup.label
        
        if(type == FilterType.TopLevel) {
            if let status = checkStatus[label] {
                if(status) {
                    checkStatus[label] = false
                } else {
                    checkStatus[label] = true
                }
            } else {
                checkStatus[label] = true
            }
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let type = resultItems[indexPath.section].filterGroups[indexPath.row].type
        let label = resultItems[indexPath.section].filterGroups[indexPath.row].label
        let cellID: String?
        
        if(type == FilterType.TopLevel) {
            cellID = "simpleFilterTableCell"
        } else {
            cellID = "filterTableCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID!, forIndexPath: indexPath) as! FilterTableViewCell
        
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        if(type == FilterType.TopLevel) {
            cell.simpleFilterLabel.text = label
            
            if let checked = checkStatus[label] {
                
                if(checked) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        } else {
            cell.filterLabel.text = label
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return resultItems[section].group
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 44
        
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        NSLog("prepareForSegue: %@", self)
        
        if let identifier = segue.identifier{
            switch identifier{
            case ViewTransConst.displayFilterOptions:
                NSLog(ViewTransConst.displayFilterOptions)
                
                if let fotvc = segue.destinationViewController as? FilterOptionTableViewController {
                    
                    let path = self.tableView.indexPathForSelectedRow!
                    
                    let filterGroup = resultItems[path.section].filterGroups[path.row]
                    
                    fotvc.filterOptions = filterGroup
                    
                    fotvc.title = filterGroup.label
                }
                
            default: break
            }
        }
    }

}
