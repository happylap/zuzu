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
    
    func onFiltersSelected(selectedFilterIdSet: [String : Set<FilterIdentifier>])
    
    func onFiltersReset()
    
}

class FilterTableViewController: UITableViewController {
    
    static let cellHeight = 55 * getCurrentScale()
    static let headerHeight = 45 * getCurrentScale()
    
    ///The list of all filter options grouped by sections
    static var filterSections:[FilterSection] = FilterTableViewController.loadFilterData("resultFilters", criteriaLabel: "advancedFilters")
    
    var filterSections:[FilterSection] {
        get {
            return FilterTableViewController.filterSections
        }
    }
    
    @IBOutlet weak var resetAllButton: UIButton! {
        didSet {
            
            resetAllButton.setTitleColor(UIColor.orangeColor(), forState: UIControlState.Normal)
            resetAllButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Disabled)
            resetAllButton.enabled = false
            
            resetAllButton.addTarget(self, action: "resetAllFilters:", forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    
    struct ViewTransConst {
        static let displayFilterOptions:String = "displayFilterOptions"
    }
    
    var filterDelegate:FilterTableViewControllerDelegate?
    
    var selectedFilterIdSet = [String : Set<FilterIdentifier>]() ///GroupId : Filter Set
    
    // MARK: - Private Utils
    private func updateResetFilterButton() {
        var filtersCount = 0
        for filterIdSet in selectedFilterIdSet.values {
            filtersCount += filterIdSet.count
        }
        
        if(filtersCount > 0) {
            resetAllButton.enabled = true
        } else {
            resetAllButton.enabled = false
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
                                
                                let filters = filters.enumerate().map({ (index, filterJson) -> Filter in
                                    let label = filterJson["label"].stringValue
                                    let value = filterJson["filterValue"].stringValue
                                    
                                    if let key = filterJson["filterKey"].string {
                                        return Filter(label: label, key: key, value: value, order: index)
                                    } else {
                                        return Filter(label: label, key: commonKey, value: value, order: index)
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
    
    func resetAllFilters(sender: UIButton) {
        NSLog("resetAllFilters")
        
        self.filterDelegate?.onFiltersReset()
        
        selectedFilterIdSet.removeAll()
        tableView.reloadData()
        
        resetAllButton.enabled = false
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity, action: GAConst.Action.Activity.ResetFilters)
    }
    
    @IBAction func onFilterSelectionDone(sender: UIBarButtonItem) {
        
        self.filterDelegate?.onFiltersSelected(self.selectedFilterIdSet)
        
        navigationController?.popViewControllerAnimated(true)
        
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateResetFilterButton()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
        
        self.tableView.registerNib(UINib(nibName: "FilterTableViewCell", bundle: nil), forCellReuseIdentifier: "filterTableCell")
        self.tableView.registerNib(UINib(nibName: "SimpleFilterTableViewCell", bundle: nil), forCellReuseIdentifier: "simpleFilterTableCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("%@ [[viewWillAppear]]", self)
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.filterSections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filterSections[section].filterGroups.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filterGroup = self.filterSections[indexPath.section].filterGroups[indexPath.row]
        let filterIdSet = selectedFilterIdSet[filterGroup.id]
        
        let type = filterGroup.type
        
        if(type == DisplayType.SimpleView) {
            
            if let currentFilter = filterGroup.filters.first {
                
                if let filterIdSet = filterIdSet {
                    if (filterIdSet.contains(currentFilter.identifier)) {
                        selectedFilterIdSet[filterGroup.id]?.remove(currentFilter.identifier)
                        NSLog("Remove: %@", currentFilter.identifier.key)
                    } else {
                        selectedFilterIdSet[filterGroup.id]?.insert(currentFilter.identifier)
                        NSLog("Insert: %@", currentFilter.identifier.key)
                    }
                } else {
                    selectedFilterIdSet[filterGroup.id] = [currentFilter.identifier]
                }
                
                updateResetFilterButton()
            }
            
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        } else {
            
            performSegueWithIdentifier(ViewTransConst.displayFilterOptions, sender: self)
            
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filterGroup = self.filterSections[indexPath.section].filterGroups[indexPath.row]
        let filterIdSetForGroup = selectedFilterIdSet[filterGroup.id]
        
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
                    cell.filterCheckMark.image = UIImage(named: "checked_green")
                } else {
                    cell.filterCheckMark.image = UIImage(named: "uncheck")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    cell.filterCheckMark.tintColor = UIColor.grayColor()
                }
            }
            
            cell.simpleFilterLabel.text = label
            
        } else {
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            
            if let filterIdSetForGroup = filterIdSetForGroup {
                
                ///Get list of filter labels for a FilterGroup
                let sortedFilterIdSetForGroup = filterIdSetForGroup.sort({ (first, second) -> Bool in
                    return first.order < second.order
                })
                
                var labelList = [String]()
                
                for filterIdentifier in sortedFilterIdSetForGroup {
                    if let filterLabel = getFilterLabel(filterIdentifier) {
                        labelList.append(filterLabel)
                        print(filterLabel)
                    }
                }
                
                if(filterIdSetForGroup.count == 0) {
                    cell.filterSelection?.text = "不限"
                } else {
                    cell.filterSelection?.text = labelList.joinWithSeparator(" ")
                }
            } else {
                cell.filterSelection?.text = "不限"
            }
            
            cell.filterLabel.text = label
            
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.filterSections[section].label
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return FilterTableViewController.cellHeight
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return FilterTableViewController.headerHeight
        
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
                    
                    let filterGroup = self.filterSections[path.section].filterGroups[path.row]
                    
                    fotvc.filterOptions = filterGroup
                    
                    if let selectedFilterIds = self.selectedFilterIdSet[filterGroup.id]{
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
        selectedFilterIdSet[groupId] = filterIdSet
        
        updateResetFilterButton()
        
        tableView.reloadData()
    }
}
