//
//  RegionTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class RegionTableViewController: UITableViewController {
    
    static let maxNumOfCitiesAllowed = 3
    static let numberOfSections = 1
    static let cellHeight = 45 * getCurrentScale()
    
    var citySelected:Int = 100 //Default value
    var checkedRegions: [Int:[Bool]] = [Int:[Bool]]()//Region selected grouped by city
    var cityRegions = [Int : City]()//City dictionary by city code
    
    // MARK: - Private Utils

    
    private func validateCityRegionSelection(cityRegionStatus: [Int:[Bool]], selectedCity: Int) -> Bool {
        
        ///Count the number of cities selected (regions are not restricted)
        var count = 0
        
        for cityCode in cityRegionStatus.keys {
            
            if let status = cityRegionStatus[cityCode] {
                let selectionCountInCity =  status.reduce(0, combine: { (count, itemStatus) -> Int in
                    if(itemStatus) {
                        return count + 1
                    } else {
                        return count
                    }
                })
                
                if(selectionCountInCity > 0) {
                    count++
                    
                    ///Selection within the city which already has selected regions is allowed
                    if(cityCode == selectedCity) {
                        return true
                    }
                }
            }
            
        }
        
        //Allow the user to select a new region only if:
        // The total number of cities selected is still under maxNumOfCitiesAllowed
        // Or the region the user tries to select now belongs to the current selected cities
        
        return (count < RegionTableViewController.maxNumOfCitiesAllowed)
    }
    
    private func alertMaxRegionSelection() {
        // Initialize Alert View
        
        let alertView = UIAlertView(
            title: "區域選擇已滿",
            message: "搜尋條件最多只可以涵蓋三個城市的區域",
            delegate: self,
            cancelButtonTitle: "知道了")
        
        // Show Alert View
        alertView.show()
        
        // Delay the dismissal
        self.runOnMainThreadAfter(2.0) {
            alertView.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    private func convertStatusToCity(cityCode: Int) -> City? {
        
        /// Send back selected city regions
        var result: City?
        
        if let city = cityRegions[cityCode] {
            
            result = City(code: city.code, name: city.name, regions: [Region]())
            
            ///Check selected regions
            if let selectionStatus = checkedRegions[cityCode] {
                
                var selectedRegions:[Region] = [Region]()
                
                for (index, status) in selectionStatus.enumerate() {
                    if(status) {
                        if(index == 0) { ///"All Region"
                            selectedRegions.append(Region.allRegions)
                        } else{ ///Not "All Region" items
                            selectedRegions.append(city.regions[index])
                        }
                    }
                }
                
                if(!selectedRegions.isEmpty) {
                    result!.regions = selectedRegions
                }
            }
        } else {
            
            assert(false, "City Code is not correct")
        }
        
        return result
    }
    
    // MARK: - UI Control Actions
    @IBAction func onSelectionCleared(sender: UIButton) {
        NSLog("onSelectionCleared")
        
        for key in checkedRegions.keys {
            
            if let stateCount = checkedRegions[key]?.count {
                for index in 0..<stateCount {
                    checkedRegions[key]![index] = false
                }
            }
            
            /// Notify selection changed
            let cityStatus = self.convertStatusToCity(key)!
            NSNotificationCenter.defaultCenter().postNotificationName("regionSelectionChanged", object: self, userInfo: ["status" : cityStatus])
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let row = indexPath.row
        
        if(!validateCityRegionSelection(checkedRegions, selectedCity: citySelected)) {
            NSLog("Max City Number")
            alertMaxRegionSelection()
            return
        }
        
        if let statusForCity = checkedRegions[citySelected]{
            if(statusForCity[row]) {
                checkedRegions[citySelected]![row] = false
                
            } else {
                checkedRegions[citySelected]![row] = true
                
                if(row == 0){ //Click on "all region"
                    
                    //Clear other selection
                    var indexPaths = [NSIndexPath]()
                    for var index = row + 1; index < checkedRegions[citySelected]?.count; ++index {
                        checkedRegions[citySelected]![index] = false
                        indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                    }
                    
                    //in order to update other cell's view
                    tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
                    
                } else { //Click on other region
                    
                    //Clear "All Region" selection
                    if(checkedRegions[citySelected]![0]) {
                        checkedRegions[citySelected]![0] = false
                    }
                    
                    tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
        }
        
        /// Notify selection changed
        let cityStatus = self.convertStatusToCity(citySelected)!
        NSNotificationCenter.defaultCenter().postNotificationName("regionSelectionChanged", object: self, userInfo: ["status" : cityStatus])
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
        
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return RegionTableViewController.numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityRegions[citySelected]?.regions.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return RegionTableViewController.cellHeight
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("simpleFilterTableCell", forIndexPath: indexPath) as! FilterTableViewCell
        
        let row = indexPath.row
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        if let statusForCity = checkedRegions[citySelected]{
            if(statusForCity[row]) {
                cell.filterCheckMark.hidden = false
                cell.filterCheckMark.image = UIImage(named: "checked_green")
            } else {
                cell.filterCheckMark.hidden = true
            }
        }
        
        cell.simpleFilterLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline).fontWithSize(20)
        
        if let city = cityRegions[citySelected] {
            cell.simpleFilterLabel?.text = city.regions[indexPath.row].name
        }
        
        return cell
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("viewDidLoad: %@", self)
        
        self.tableView.registerNib(UINib(nibName: "SimpleFilterTableViewCell", bundle: nil), forCellReuseIdentifier: "simpleFilterTableCell")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSLog("viewWillDisappear: %@", self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension RegionTableViewController: CitySelectionViewControllerDelegate {
    
    // MARK: - CitySelectionViewControllerDelegate
    func onCitySelected(value: Int) {
        citySelected = value
        
        tableView.reloadData()
    }
}
