//
//  FilterTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

private let Log = Logger.defaultLogger

// MARK: - Public Utils
internal func convertFilterGroupToIdentifier(filterGroups: [FilterGroup]) -> [String: Set<FilterIdentifier>] {

    var filterIdSet = [String: Set<FilterIdentifier>]()
    for filterGroup in filterGroups {
        filterIdSet[filterGroup.id] = []
        for filter in filterGroup.filters {
            filterIdSet[filterGroup.id]?.insert(filter.identifier)
        }
    }

    return filterIdSet
}

internal func convertIdentifierToFilterGroup(selectedFilterIdSet: [String: Set<FilterIdentifier>]) -> [FilterGroup] {

    var filterGroupResult = [FilterGroup]()

    ///Walk through all items to generate the list of selected FilterGroup
    for section in FilterTableViewController.filterSections {
        for group in section.filterGroups {
            if let selectedFilterId = selectedFilterIdSet[group.id] {
                let groupCopy = group.copy() as! FilterGroup

                let selectedFilters = group.filters.filter({ (filter) -> Bool in
                    selectedFilterId.contains(filter.identifier)
                })

                if(!selectedFilters.isEmpty) {
                    groupCopy.filters = selectedFilters

                    filterGroupResult.append(groupCopy)
                }
            }
        }
    }

    return filterGroupResult
}

// MARK: - FilterTableViewControllerDelegate
protocol FilterTableViewControllerDelegate {

    func onFiltersSelected(newFilterIdSet: [String : Set<FilterIdentifier>])
    func onFiltersSelectionDone(selectedFilterIdSet: [String : Set<FilterIdentifier>])
    func onFiltersReset()

}

class FilterTableViewController: UITableViewController {

    static let cellHeight = 55 * getCurrentScale()
    static let headerHeight = 45 * getCurrentScale()

    ///The list of all filter options grouped by sections
    static var filterSections: [FilterSection] = ConfigLoader.loadAdvancedFilters()

    struct ViewTransConst {
        static let displayFilterOptions: String = "displayFilterOptions"
    }

    @IBOutlet weak var resetAllButton: UIButton! {
        didSet {

            resetAllButton.setTitleColor(UIColor.orangeColor(), forState: UIControlState.Normal)
            resetAllButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Disabled)
            resetAllButton.enabled = false

            resetAllButton.addTarget(self, action: #selector(FilterTableViewController.onFilterResetButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }

    var filterSections: [FilterSection] {
        get {
            return FilterTableViewController.filterSections
        }
    }

    var filterStatusBarView: FilterStatusBarView?

    var filterDelegate: FilterTableViewControllerDelegate?

    var selectedFilterIdSet = [String : Set<FilterIdentifier>]() ///GroupId : Filter Set

    let basementFilterIdentifier = FilterIdentifier(key: "floor", value: "{* TO 0}", order: 0)

    // MARK: - Private Utils
    private func handleConflictSelection(selectedFilterGroupId: String) {

        if(selectedFilterGroupId == "floor_range") {

            if let _ = selectedFilterIdSet["floor_range"] {

                /// Remove not_basement selection if any floor is selected
                selectedFilterIdSet["not_basement"] = nil

            }

        }

    }

    ///Try to update any UI related to filter status
    private func notifyFilterChange() {

        updateResetFilterButton()

        updateStatusBar()

        //Notify the lateset set of criteria
        self.filterDelegate?.onFiltersSelected(self.selectedFilterIdSet)
    }

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

    private func updateStatusBar() {

        let nonEmptyFilterGroup = selectedFilterIdSet.values.filter { (filters) -> Bool in
            return (filters.count > 0)
        }

        let filtersCount = nonEmptyFilterGroup.count

        if let filterStatusBarView = self.filterStatusBarView {

            if(filtersCount > 0) {
                filterStatusBarView.statusText.text = "已經設定 \(filtersCount) 個過濾條件"
            } else {
                filterStatusBarView.statusText.text = "尚未設定任何過濾條件"
            }

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

    // MARK: - Action Handlers

    func onFilterResetButtonTouched(sender: UIButton) {
        Log.debug("onFilterResetButtonTouched")

        self.filterDelegate?.onFiltersReset()

        selectedFilterIdSet.removeAll()
        tableView.reloadData()

        self.notifyFilterChange()

        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity, action: GAConst.Action.UIActivity.ResetFilters)
    }

    //    @IBAction func onFilterSelectionDone(sender: UIBarButtonItem) {
    //
    //        self.filterDelegate?.onFiltersSelected(self.selectedFilterIdSet)
    //
    //        navigationController?.popViewControllerAnimated(true)
    //
    //    }

    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        self.tableView.registerNib(UINib(nibName: "FilterTableViewCell", bundle: nil), forCellReuseIdentifier: "filterTableCell")
        self.tableView.registerNib(UINib(nibName: "SimpleFilterTableViewCell", bundle: nil), forCellReuseIdentifier: "simpleFilterTableCell")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()

        //Add Filter Status Bar
        if let navView = self.navigationController?.view {
            if let filterStatusBarView = self.filterStatusBarView {

                filterStatusBarView.showStatusBarOnView(navView)

            } else {

                var parentRect = navView.bounds
                Log.verbose("parentRect = \(parentRect)")
                let statusBarHeight: CGFloat = min(UIApplication.sharedApplication().statusBarFrame.size.height, 20.0)
                let navigationBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
                Log.verbose("statusBarHeight = \(statusBarHeight), navigationBarHeight = \(navigationBarHeight)")

                ///Position the bar below status bar & navigation bar
                parentRect.origin.y += (navigationBarHeight + statusBarHeight)
                filterStatusBarView = FilterStatusBarView(frame: parentRect)
                filterStatusBarView!.showStatusBarOnView(navView)
            }

            filterStatusBarView?.alpha = 0.1

        }

        notifyFilterChange()

        //Google Analytics Tracker

        self.trackScreen()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.enter()

        filterStatusBarView?.fadeIn(0.5)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Log.enter()

        filterStatusBarView?.hideStatusBar()
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)

        if(parent == nil) {
            self.tabBarController?.tabBarHidden = false
            /// Filter Setting Finished
            self.filterDelegate?.onFiltersSelectionDone(self.selectedFilterIdSet)
        }
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
                        Log.debug("Remove: \(currentFilter.identifier.key)")
                    } else {
                        selectedFilterIdSet[filterGroup.id]?.insert(currentFilter.identifier)
                        Log.debug("Insert: \(currentFilter.identifier.key)")
                    }
                } else {
                    selectedFilterIdSet[filterGroup.id] = [currentFilter.identifier]
                }

                notifyFilterChange()

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

            if let currentFilter = filterGroup.filters.first, filterSetForGroup = filterIdSetForGroup {
                if filterSetForGroup.contains(currentFilter.identifier) {
                    cell.filterCheckMark.image = UIImage(named: "checked_green")
                } else {
                    cell.filterCheckMark.image = UIImage(named: "uncheck")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    cell.filterCheckMark.tintColor = UIColor.grayColor()
                }
            }

            cell.simpleFilterLabel.text = label

            if(filterGroup.id == "not_basement") {

                if let filterIdSet = selectedFilterIdSet["floor_range"] {

                    if(filterIdSet.isEmpty) {
                        cell.userInteractionEnabled = true
                        cell.contentView.alpha = 1
                    } else {
                        cell.userInteractionEnabled = false
                        cell.contentView.alpha = 0.5
                    }

                }
            }

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
                        Log.debug(filterLabel)
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

        if let identifier = segue.identifier {

            Log.debug("prepareForSegue: \(identifier)")

            switch identifier {
            case ViewTransConst.displayFilterOptions:
                Log.debug(ViewTransConst.displayFilterOptions)

                if let fotvc = segue.destinationViewController as? FilterOptionTableViewController {

                    let path = self.tableView.indexPathForSelectedRow!

                    let filterGroup = self.filterSections[path.section].filterGroups[path.row]

                    fotvc.filterOptions = filterGroup

                    if let selectedFilterIds = self.selectedFilterIdSet[filterGroup.id] {
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
        Log.debug("onFiltersSelected: \(filterIdSet)")

        ///Update selection for a FilterGroup
        selectedFilterIdSet[groupId] = filterIdSet

        self.handleConflictSelection(groupId)

        tableView.reloadData()

        notifyFilterChange()
    }
}
