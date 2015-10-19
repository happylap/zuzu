//
//  AreaSelectionViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/12.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol CitySelectionViewControllerDelegate: class {
    func onCitySelected(value: Int)
}

class CityPickerViewController:UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    static let numberOfComponents = 1
    
    let dataSource : CityRegionDataSource = UserDefaultsCityRegionDataSource.getInstance()
    
    var regionSelectionResult: [City]?
    
    @IBOutlet weak var cityPicker: UIPickerView!
    
    weak var delegate: CitySelectionViewControllerDelegate?
    
    var cityRegions = [City]()//Array of Cities
    
    private func configurePricePicker() {
        cityPicker.dataSource = self
        cityPicker.delegate = self
        regionSelectionResult = dataSource.getSelectedCityRegions()
    }
    
    // MARK: - PickerView DataSource & Delegate
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return CityPickerViewController.numberOfComponents
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        let city = cityRegions[row]
        
        if(regionSelectionResult != nil) {
            if let index = regionSelectionResult!.indexOf(city){
                let selectedRegions = regionSelectionResult![index].regions
                let numberOfSelection = regionSelectionResult![index].regions.count
                
                if(numberOfSelection > 0) {
                    
                    if(numberOfSelection == 1) {
                        if(selectedRegions[0] == RegionTableViewController.allRegion) {
                            return ("\(cityRegions[row].name) (全區)")
                        }
                    }

                    return ("\(cityRegions[row].name) (\(numberOfSelection))")
                }
            }
        }

        return cityRegions[row].name
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cityRegions.count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedCity = cityRegions[row].code
        
        delegate?.onCitySelected(selectedCity)
    }
    
    // MARK: - Notification Selector
    func onRegionSelectionUpdated(notification:NSNotification) {
        if let userInfo = notification.userInfo {
            
            if let cityStatus = userInfo["status"] as? City {
                if let index = regionSelectionResult?.indexOf(cityStatus) {
                    regionSelectionResult?.removeAtIndex(index)
                    regionSelectionResult?.insert(cityStatus, atIndex: index)
                } else {
                    regionSelectionResult?.append(cityStatus)
                }
                
                cityPicker.reloadAllComponents()
            }
            
        }
    }
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("viewDidLoad: %@", self)
        
        self.configurePricePicker()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onRegionSelectionUpdated:", name: "regionSelectionChanged", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear: %@", self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("viewDidAppear: %@", self)
        
        let row = cityPicker.selectedRowInComponent(0)
        let selectedCity = cityRegions[row].code // cityItems[0][row].value
        
        delegate?.onCitySelected(selectedCity)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
