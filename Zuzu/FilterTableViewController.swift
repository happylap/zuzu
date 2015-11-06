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
    
    func onFiltersSelected(filters: [FilterGroup])
    
}

class FilterTableViewController: UITableViewController {
    
    let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    struct ViewTransConst {
        static let displayFilterOptions:String = "displayFilterOptions"
    }
    
    var filterDelegate:FilterTableViewControllerDelegate?
    
    var selectedFilters = [String : Set<FilterIdentifier>]() ///GroupId : Filter Set
    
    var filterSections = [FilterSection]() ///The list of all filter options grouped by sections
    
    // MARK: - Private Utils
    private static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [FilterSection]{
        
        var resultSections = [FilterSection]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let groupList = json[criteriaLabel].arrayValue
                
                NSLog("\(criteriaLabel) = %d", groupList.count)
                
                for groupJson in groupList {
                    let section = groupJson["section"].stringValue
                    
                    if let itemList = groupJson["groups"].array {
                        
                        let allFilters = itemList.map({ (itemJson) -> FilterGroup in
                            let groupId = itemJson["id"].stringValue
                            let label = itemJson["label"].stringValue
                            let type = itemJson["displayType"].intValue
                            let choiceType = ChoiceType(rawValue: itemJson["choiceType"].stringValue)
                            let logicType = LogicType(rawValue: itemJson["logicType"].stringValue)
                            let commonKey = itemJson["filterKey"].stringValue
                            
                            
                            if let filters = itemJson["filters"].array {
                                ///DetailView
                                
                                let filters = filters.map({ (filterJson) -> Filter in
                                    let label = filterJson["label"].stringValue
                                    let value = filterJson["filterValue"].stringValue
                                    
                                    if let key = filterJson["filterKey"].string {
                                        return Filter(label: label, key: key, value: value)
                                    } else {
                                        return Filter(label: label, key: commonKey, value: value)
                                    }
                                })
                                
                                let filterGroup = FilterGroup(id: groupId, label: label,
                                    type: DisplayType(rawValue: type)!,
                                    filters: filters)
                                
                                filterGroup.logicType = logicType
                                filterGroup.choiceType = choiceType
                                
                                return filterGroup
                                
                            } else {
                                ///SimpleView
                                
                                let value = itemJson["filterValue"].stringValue
                                
                                let filterGroup = FilterGroup(id: groupId, label: label,
                                    type: DisplayType(rawValue: type)!,
                                    filters: [Filter(label: label, key: commonKey, value: value)])
                                
                                return filterGroup
                                
                            }
                        })
                        
                        resultSections.append(FilterSection(label: section, filterGroups: allFilters))
                        
                    }
                    
                    
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load json file %@", error)
                
            }
        }
        
        return resultSections
    }
    
    // MARK: - Action Handlers
    @IBAction func onFilterSelectionDone(sender: UIBarButtonItem) {
        
        var filterGroupResult = [FilterGroup]()
        
        ///Save all selected setting
        filterDataStore.saveAdvancedFilterSetting(self.selectedFilters)
        
        ///Walk through all items to generate the list of selected FilterGroup
        for section in filterSections {
            for group in section.filterGroups {
                if let selectedFilterId = self.selectedFilters[group.id] {
                    let groupCopy = group.copy() as! FilterGroup
                    
                    let selectedFilters = group.filters.filter({ (filter) -> Bool in
                        selectedFilterId.contains(filter.identifier)
                    })
                    
                    groupCopy.filters = selectedFilters
                    
                    filterGroupResult.append(groupCopy)
                }
            }
        }
        
        self.filterDelegate?.onFiltersSelected(filterGroupResult)
        
        navigationController?.popViewControllerAnimated(true)
        
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load all filter items
        filterSections = FilterTableViewController.loadFilterData("resultFilters", criteriaLabel: "advancedFilters")
        
        // Load selected filters
        if let selectedFilterSetting = filterDataStore.loadAdvancedFilterSetting() {
            for (key, value) in selectedFilterSetting {
                self.selectedFilters[key] = value
            }
        }
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return filterSections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterSections[section].filterGroups.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filterGroup = filterSections[indexPath.section].filterGroups[indexPath.row]
        let filterSet = selectedFilters[filterGroup.id]
        
        let type = filterGroup.type
        
        if(type == DisplayType.SimpleView) {
            
            if let currentFilter = filterGroup.filters.first {
                
                if (filterSet == nil) {
                    selectedFilters[filterGroup.id] = [currentFilter.identifier]
                } else {
                    if (filterSet!.contains(currentFilter.identifier)) {
                        selectedFilters[filterGroup.id]?.remove(currentFilter.identifier)
                        NSLog("Remove: %@", currentFilter.identifier.key)
                    } else {
                        selectedFilters[filterGroup.id]?.insert(currentFilter.identifier)
                        NSLog("Insert: %@", currentFilter.identifier.key)
                    }
                }
            }
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
    
    private func getFilterLabel(filterIdentifier: FilterIdentifier) -> String? {
        for section in self.filterSections {
            for group in section.filterGroups {
                
                let result = group.filters.filter({ (filter) -> Bool in
                    return filter.identifier == filterIdentifier
                })
                
                if(!result.isEmpty) {
                    return result.first?.label
                }
            }
        }
        
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filterGroup = filterSections[indexPath.section].filterGroups[indexPath.row]
        let filterIdSetForGroup = selectedFilters[filterGroup.id]
        
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
            
            if let currentFilter = filterGroup.filters.first, let filterSetForGroup = filterIdSetForGroup {
                if filterSetForGroup.contains(currentFilter.identifier) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                }
            }
            
            cell.simpleFilterLabel.text = label
            
        } else {
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            if let filterIdSetForGroup = filterIdSetForGroup {
                
                ///Get list of filter labels for a FilterGroup
                var labelList = [String]()
                for filterIdentifier in filterIdSetForGroup {
                    if let filterLabel = getFilterLabel(filterIdentifier) {
                        labelList.append(filterLabel)
                    }
                }
                
                if(filterIdSetForGroup.count == 0) {
                    cell.filterSelection?.text = "不限"
                } else {
                    cell.filterSelection?.text = labelList.joinWithSeparator(",")
                }
            }
            
            cell.filterLabel.text = label
            
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filterSections[section].label
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
                    
                    let filterGroup = filterSections[path.section].filterGroups[path.row]
                    
                    fotvc.filterOptions = filterGroup
                    
                    if let selectedFilterIds = self.selectedFilters[filterGroup.id]{
                        fotvc.selectedFilterIds = selectedFilterIds
                    }
                    
                    fotvc.title = filterGroup.label
                    
                    fotvc.filterOptionDelegate = self
                }
                
            default: break
            }
        }
    }
    
}

extension FilterTableViewController: FilterOptionTableViewControllerDelegate {
    
    func onFiltersSelected(groupId: String, filterIdSet: Set<FilterIdentifier>) {
        NSLog("onFiltersSelected: %@", filterIdSet)
        
        ///Update selection for a FilterGroup
        selectedFilters[groupId] = filterIdSet
        
        tableView.reloadData()
    }
}
