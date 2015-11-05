//
//  FilterTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol FilterTableViewControllerDelegate {
    
    func onFiltersSelected(filters: [String : String])
    
}

class FilterTableViewController: UITableViewController {
    
    struct ViewTransConst {
        static let displayFilterOptions:String = "displayFilterOptions"
    }
    
    var filterDelegate:FilterTableViewControllerDelegate?
    
    var rowsSelected = [NSIndexPath]()
    var filterGroupSelected = [FilterGroup]()
    var filterItems = [(group: String, filterGroups: [FilterGroup])]()
    
    // MARK: - Private Utils
    private static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [(group: String, filterGroups: [FilterGroup])]{
        
        var resultItems = [(group: String, filterGroups: [FilterGroup])]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let groupList = json[criteriaLabel].arrayValue
                
                NSLog("\(criteriaLabel) = %d", groupList.count)
                
                for groupJson in groupList {
                    let group = groupJson["group"].stringValue
                    
                    if let itemList = groupJson["items"].array {
                        
                        let allFilters = itemList.map({ (itemJson) -> FilterGroup in
                            let label = itemJson["label"].stringValue
                            let type = itemJson["displayType"].intValue
                            let choiceType = ChoiceType(rawValue: itemJson["choiceType"].stringValue)
                            let logicType = LogicType(rawValue: itemJson["logicType"].stringValue)
                            let commonKey = itemJson["filterKey"].stringValue
                            
                            ///DetailView
                            if let filters = itemJson["filters"].array {
                                
                                let filters = filters.map({ (filterJson) -> Filter in
                                    let label = filterJson["label"].stringValue
                                    let value = filterJson["filterValue"].stringValue
                                    
                                    if let key = filterJson["filterKey"].string {
                                        return Filter(label: label, key: key, value: value)
                                    } else {
                                        return Filter(label: label, key: commonKey, value: value)
                                    }
                                })
                                
                                let filterGroup = FilterGroup(label: label,
                                    type: DisplayType(rawValue: type)!,
                                    filters: filters)
                                
                                filterGroup.logicType = logicType
                                filterGroup.choiceType = choiceType
                                
                                return filterGroup
                                
                                ///SimpleView
                            } else {
                                
                                let value = itemJson["filterValue"].stringValue
                                
                                let filterGroup = FilterGroup(label: label,
                                    type: DisplayType(rawValue: type)!,
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
        
        for indexPath in self.rowsSelected {
            
            let filterGroup = filterItems[indexPath.section].filterGroups[indexPath.row]
            
            self.filterGroupSelected.append(filterGroup)
        }
        
        var result = [String:String]()
        
        ///Convert to key:value dictionary
        for filterGroup in filterGroupSelected {
            let filterDic = filterGroup.filterDic
            
            for (key, value) in filterDic {
                result[key] = value
            }
        }
        
        self.filterDelegate?.onFiltersSelected(result)
        
        navigationController?.popViewControllerAnimated(true)
        
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterItems = FilterTableViewController.loadFilterData("resultFilters", criteriaLabel: "advancedFilters")
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return filterItems.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterItems[section].filterGroups.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filterGroup = filterItems[indexPath.section].filterGroups[indexPath.row]
        
        let type = filterGroup.type
        
        if(type == DisplayType.SimpleView) {
            
            if let index = rowsSelected.indexOf(indexPath) {
                rowsSelected.removeAtIndex(index)
            } else {
                rowsSelected.append(indexPath)
            }
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filterGroup = filterItems[indexPath.section].filterGroups[indexPath.row]
        let type = filterGroup.type
        let label = filterGroup.label
        let cellID: String?
        
        if(type == DisplayType.SimpleView) {
            cellID = "simpleFilterTableCell"
        } else {
            cellID = "filterTableCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellID!, forIndexPath: indexPath) as! FilterTableViewCell
        
        if(type == DisplayType.SimpleView) {
            
            
            if(rowsSelected.contains(indexPath)) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            
            cell.simpleFilterLabel.text = label
            
        } else {
            
            cell.filterLabel.text = label
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filterItems[section].group
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 44
        
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@", identifier)
            
            switch identifier{
            case ViewTransConst.displayFilterOptions:
                NSLog(ViewTransConst.displayFilterOptions)
                
                if let fotvc = segue.destinationViewController as? FilterOptionTableViewController {
                    
                    let path = self.tableView.indexPathForSelectedRow!
                    
                    let filterGroup = filterItems[path.section].filterGroups[path.row]
                    
                    fotvc.filterOptions = filterGroup
                    
                    fotvc.title = filterGroup.label
                    
                    fotvc.filterOptionDelegate = self
                }
                
            default: break
            }
        }
    }
    
}

extension FilterTableViewController: FilterOptionTableViewControllerDelegate {
    
    func onFiltersSelected(filterGroup: FilterGroup) {
        NSLog("onFiltersSelected: %@", filterGroup.filters)
        
        filterGroupSelected.append(filterGroup)
    }
}
