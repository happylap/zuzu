//
//  CityRegionContainerController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol CityRegionContainerControllerDelegate: class {
    func onCitySelectionDone(regions:[City])
}

class CityRegionContainerController: UIViewController {
    
    var delegate: CityRegionContainerControllerDelegate?
    
    var isDataPrepared = false
    
    let dataStore : CityRegionDataStore = UserDefaultsCityRegionDataStore.getInstance()
    
    var checkedRegions: [Int:[Bool]] = [Int:[Bool]]()//Region selected grouped by city
    var regionSelectionState: [City] = [City]()
    
    var cityRegions = [Int : City]()//City dictionary by city code
    
    struct ViewTransConst {
        static let showRegionTable:String = "showRegionTable"
        static let showCityPicker:String = "showCityPicker"
    }
    
    weak var cityPicker:CityPickerViewController?
    weak var regionTable:RegionTableViewController?
    
    // MARK: - Private Utils
    
    private func loadCityRegionData() {
        
        cityRegions.removeAll()
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            ///Load all city regions from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let cities = json["cities"].arrayValue
                
                NSLog("Cities = %d", cities.count)
                
                for cityJsonObj in cities {
                    let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    let regions = cityJsonObj["region"].arrayValue
                    
                    ///Init Region Table data
                    var regionList:[Region] = [Region]()
                    
                    regionList.append(Region.allRegions)///All region
                    
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
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load area json file %@", error)
                
            }
            
            ///Init selected regions
            let selectedCities = self.regionSelectionState
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
    
    private func prepareDataIfNeeded() {
        if(!isDataPrepared) {
            loadCityRegionData()
            isDataPrepared = true
        }
    }
    
    // MARK: - UI Control Actions
    @IBAction func onSelectionDone(sender: UIBarButtonItem) {
        
        NSLog("onSelectionDone")
        
        //Save selection to user defaults only when the user presses "Done" button
        
        //dataStore.saveSelectedCityRegions(regionSelectionState)
        
        delegate?.onCitySelectionDone(regionSelectionState)
        
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    // MARK: - Notification Selector
    func onRegionSelectionUpdated(notification:NSNotification) {
        if let userInfo = notification.userInfo {
            
            if let cityStatus = userInfo["status"] as? City {
                
                ///If the region count is 0, it means we don't need this entry anymore
                let markRemoved = cityStatus.regions.count <= 0
                
                if let index = regionSelectionState.indexOf(cityStatus) {
                    
                    if(markRemoved) {
                        regionSelectionState.removeAtIndex(index)
                    } else {
                        regionSelectionState.replaceRange(index...index, with: [cityStatus])
                    }
                } else {
                    if(!markRemoved) {
                        regionSelectionState.append(cityStatus)
                    }
                }
            }
            
        }
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("viewDidLoad: %@", self)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onRegionSelectionUpdated:", name: "regionSelectionChanged", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear: %@", self)
        
        ///Hide tab bar
        self.tabBarController!.tabBarHidden = true
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("viewWillDisappear: %@", self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Load previously stored data
        prepareDataIfNeeded()
        
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@ %@",identifier, self)
            
            switch identifier{
            case ViewTransConst.showCityPicker:
                
                if let vc = segue.destinationViewController as? CityPickerViewController {
                    cityPicker = vc
                    vc.cityRegions  = [City](cityRegions.values)
                    vc.regionSelectionState = regionSelectionState
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
        }
    }
    
}
