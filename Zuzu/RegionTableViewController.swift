//
//  RegionTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class Region: NSObject, NSCoding {
    var code:Int
    var name:String
    
    init(code:Int, name: String) {
        self.code = code
        self.name = name
    }
    
    convenience required init?(coder decoder: NSCoder) {
        let code = decoder.decodeIntegerForKey("code") as Int
        let name = decoder.decodeObjectForKey("name") as? String ?? ""
        
        self.init(code: code, name: name)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        return (object as? Region)?.code == code
    }
    
    //    override var hashValue : Int {
    //        get {
    //            return code.hashValue
    //        }
    //    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(code, forKey:"code")
        aCoder.encodeObject(name, forKey:"name")
    }
    
    override var description: String {
        let string = "Region: code = \(code), name = \(name)"
        return string
    }
}

//func ==(lhs: Region, rhs: Region) -> Bool {
//    return  lhs.hashValue == rhs.hashValue
//}

class City: NSObject, NSCoding {
    var code:Int
    var name:String
    var regions:[Region]
    
    init(code:Int, name: String, regions:[Region]) {
        self.code = code
        self.name = name
        self.regions = regions
    }
    
    convenience required init?(coder decoder: NSCoder) {
        
        let code = decoder.decodeIntegerForKey("code") as Int
        let name = decoder.decodeObjectForKey("name") as? String ?? ""
        let regions = decoder.decodeObjectForKey("regions") as? [Region] ?? [Region]()
        
        self.init(code: code, name: name, regions: regions)
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        return (object as? City)?.code == code
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInteger(code, forKey:"code")
        aCoder.encodeObject(name, forKey:"name")
        aCoder.encodeObject(regions, forKey:"regions")
    }
    
    override var description: String {
        let string = "Region: code = \(code), name = \(name)"
        return string
    }
}

protocol RegionTableViewControllerDelegate {
    func onRegionSelectionDone(result: [City])
}

class RegionTableViewController: UITableViewController, CitySelectionViewControllerDelegate {
    
    static let numberOfSections = 1
    static let allRegion = Region(code: 0, name: "全區")
    
    var citySelected:Int = 100 //Default value
    var checkedRegions: [Int:[Bool]] = [Int:[Bool]]()//Region selected grouped by city
    var cityRegions = [Int : City]()//City dictionary by city code
    
    var delegate: RegionTableViewControllerDelegate?
    
    private func configureRegionTable() {
        
        //Configure cell height
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
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
                            selectedRegions.append(RegionTableViewController.allRegion)
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
    
    // MARK: - CitySelectionViewControllerDelegate
    func onCitySelected(value: Int) {
        citySelected = value
        
        tableView.reloadData()
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureRegionTable()
        
        NSLog("viewDidLoad: %@", self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSLog("viewWillDisappear: %@", self)
        
        /// Send back selected city regions
        var result: [City] = [City]()
        
        for cityCode in checkedRegions.keys {
            
            
            if let city = self.convertStatusToCity(cityCode) {
                if(city.regions.count > 0) {
                    result.append(city)
                }
            }
            
            
            ///Copy city data
            //            if let city = cityRegions[cityCode] {
            //
            //                ///Check selected regions
            //                if let selectionStatus = checkedRegions[cityCode] {
            //
            //                    let newCity = City(code: city.code, name: city.name, regions: [Region]())
            //                    var allRegion:Bool = false
            //                    var selectedRegions:[Region] = [Region]()
            //
            //                    for (index, status) in selectionStatus.enumerate() {
            //                        if(status) {
            //                            if(index == 0) { ///"All Region"
            //                                allRegion = true
            //                            } else{ ///Not "All Region" items
            //                                selectedRegions.append(city.regions[index])
            //                            }
            //                        }
            //                    }
            //
            //                    if(allRegion) {
            //                        result.append(newCity)
            //                    } else {
            //                        if(!selectedRegions.isEmpty) {
            //                            newCity.regions = selectedRegions
            //                            result.append(newCity)
            //                        }
            //                    }
            //
            //                    allRegion = false
            //                }
            //
            //            }
            
        }
        
        delegate?.onRegionSelectionDone(result)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let row = indexPath.row
        
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
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return RegionTableViewController.numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityRegions[citySelected]?.regions.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("regionCell", forIndexPath: indexPath)
        
        let row = indexPath.row
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        ///Reset for reuse
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        if let statusForCity = checkedRegions[citySelected]{
            if(statusForCity[row]) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        
        cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline).fontWithSize(20)
        
        if let city = cityRegions[citySelected] {
            cell.textLabel?.text = city.regions[indexPath.row].name
        }
        
        return cell
    }
    
}
