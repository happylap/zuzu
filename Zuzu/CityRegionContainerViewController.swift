//
//  CityRegionContainerViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON



class CityRegionContainerViewController: UIViewController, RegionTableViewControllerDelegate {
    
    let allRegion = Region(code: 0, name: "全區")
    let dataSource : CityRegionDataSource = UserDefaultsCityRegionDataSource.getInstance()
    
    var checkedRegions: [Int:[Bool]] = [Int:[Bool]]()//Region selected grouped by city
    var cityRegions = [Int : City]()//City dictionary by city code
    var cityList = [City]()//City list
    
    struct ViewTransConst {
        static let showRegionTable:String = "showRegionTable"
        static let showCityPicker:String = "showCityPicker"
    }
    
    var isSelectionDone:Bool = false
    
    weak var cityPicker:CityPickerViewController?
    weak var regionTable:RegionTableViewController?
    
    // MARK: - Private Utils
    
    private func loadCityRegionData() {
        
        if(cityRegions.count > 0 && cityRegions.count == checkedRegions.count) {
            return //Already loaded
        }
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            ///Load all city regions from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                NSLog("Cities = %d", cities.count)
                
                for cityJsonObj in cities {
                    //Do something you want
                    let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    let regions = cityJsonObj["region"].arrayValue
                    
                    ///Init Region Table data
                    var regionList:[Region] = [Region]()
                    
                    regionList.append(allRegion)///All region
                    
                    for region in regions {
                        if let regionDic = region.dictionary {
                            for key in regionDic.keys {
                                regionList.append(Region(code: regionDic[key]!.intValue, name: key))
                            }
                        }
                    }
                    
                    ///Init selection status for each city
                    checkedRegions[code] = [Bool](count:regionList.count, repeatedValue: false)
                    
                    let city = City(code: code, name: name, regions: regionList)
                    
                    cityRegions[code] = city
                    cityList.append(city)
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load area json file %@", error)
                
            }
            
            ///Init selected regions
            if let selectedCities = dataSource.getSelectedCityRegions() {
                for city in selectedCities {
                    
                    let selectedRegions = city.regions
                    
                    if(selectedRegions.isEmpty) {
                        checkedRegions[city.code]?[0] = true
                    } else {
                        for region in selectedRegions {
                            if let index = cityRegions[city.code]?.regions.indexOf(region) { ///Region needs to be Equatable
                                checkedRegions[city.code]?[index] = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - RegionTableViewControllerDelegate
    func onRegionSelectionDone(result: [City]) {
        //Save selection to user defaults only when the user presses "Done" button
        if(isSelectionDone) {
            dataSource.setSelectedCityRegions(result)
        }
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func onSelectionDone(sender: UIBarButtonItem) {
        
        NSLog("onSelectionDone")
        
        isSelectionDone = true
        
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func onSelectionCleared(sender: UIBarButtonItem) {
        NSLog("onSelectionDone")
        
        for key in checkedRegions.keys {
            for (var index:Int = 0; index < checkedRegions[key]?.count; index++ ) {
                checkedRegions[key]![index] = false
            }
        }
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        NSLog("prepareForSegue: %@", self)
        
        loadCityRegionData()
        
        if let identifier = segue.identifier{
            switch identifier{
            case ViewTransConst.showCityPicker:
                
                if let vc = segue.destinationViewController as? CityPickerViewController {
                    cityPicker = vc
                    vc.cityRegions  = cityList
                }
                
            case ViewTransConst.showRegionTable:
                
                if let vc = segue.destinationViewController as? RegionTableViewController {
                    regionTable = vc
                    vc.checkedRegions = checkedRegions
                    vc.cityRegions = cityRegions
                }
            default: break
            }
        }
        
        if(cityPicker != nil && regionTable != nil) {
            cityPicker?.delegate = regionTable
            
            regionTable?.delegate = self
        }
    }
    
}
