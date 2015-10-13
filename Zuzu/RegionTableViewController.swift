//
//  RegionTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol RegionTableViewControllerDelegate {
    func onRegionsSelected(regions: [(name: String, code: Int)] )
}

class RegionTableViewController: UITableViewController, CitySelectionViewControllerDelegate {
    
    var citySelected:Int = 100 //Default value
    var checkStatus: [Int:Set<Int>] = [Int:Set<Int>]()
    var cityRegions = [Int:[(String, Int)]]()
    
    private func configureRegionTable() {
        
        //Configure cell height
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        //tableView.allowsSelection = false
        
    }
    
    func onCitySelected(value: Int) {
        citySelected = value
        
        if (checkStatus[citySelected] == nil) {
            checkStatus[citySelected] = Set<Int>()
        }
        
        tableView.reloadData()
    }
    
    // MARK: - View Controller Life Cycel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureRegionTable()
        
        NSLog("viewDidLoad: %@", self)
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                NSLog("Cities = %d", cities.count)
                
                //var allCities = [(label:String, value:Int)]()
                
                for cityJsonObj in cities {
                    //Do something you want
                    //let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    let regions = cityJsonObj["region"].arrayValue
                    
                    var regionList:[(String, Int)] = [(String, Int)]()
                    
                    for region in regions {
                        
                        if let regionDic = region.dictionary {
                            
                            for key in regionDic.keys {
                                
                                regionList.append((key, regionDic[key]!.intValue))
                            }
                        }
                    }
                    cityRegions[code] = regionList
                    
                    
                    //allCities.append( (name, code) )
                }
                
                //cityItems.append(allCities)
                
            } catch let error as NSError{
                
                NSLog("Cannot load area json file %@", error)
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        if let statusForCity = checkStatus[citySelected]{
            if(statusForCity.contains(indexPath.row)) {
                checkStatus[citySelected]!.remove(indexPath.row)
            } else {
                checkStatus[citySelected]!.insert(indexPath.row)
            }
            
        }
        
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cityRegions[citySelected]?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("regionCell", forIndexPath: indexPath)
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        //cell.accessoryType = UITableViewCellAccessoryType.None
        
        if let statusForCity:Set<Int> = checkStatus[citySelected] {
            
            if (statusForCity.contains(indexPath.row)) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            }else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            
        }
        
        
        
        cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline).fontWithSize(20)
        
        if let regions = cityRegions[citySelected] {
            cell.textLabel?.text = regions[indexPath.row].0
        }
        
        return cell
    }
    
}
