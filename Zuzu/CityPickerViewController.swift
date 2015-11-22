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

class CityPickerViewController:UIViewController {
    
    static let numberOfComponents = 1
    
    var regionSelectionState: [City]?
    
    @IBOutlet weak var cityPicker: UIPickerView!
    
    weak var delegate: CitySelectionViewControllerDelegate?
    
    var cityRegions = [City]()//Array of Cities
    
    private func configurePricePicker() {
        cityPicker.dataSource = self
        cityPicker.delegate = self
    }
    
    private func getFirstSelectedCityIndex() -> Int?{
        
        for (index, city) in cityRegions.enumerate() {
            if let regionSelectionState = regionSelectionState {
                if(regionSelectionState.contains(city)) {
                    return index
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Notification Selector
    func onRegionSelectionUpdated(notification:NSNotification) {
        if let userInfo = notification.userInfo {
            
            if let cityStatus = userInfo["status"] as? City {
                if let index = regionSelectionState?.indexOf(cityStatus) {
                    regionSelectionState?.removeAtIndex(index)
                    regionSelectionState?.insert(cityStatus, atIndex: index)
                } else {
                    regionSelectionState?.append(cityStatus)
                }
                
                cityPicker.reloadAllComponents()
            }
            
        }
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("viewDidLoad: %@", self)
        
        self.configurePricePicker()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onRegionSelectionUpdated:", name: "regionSelectionChanged", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear: %@", self)
        
        ///Auto-pick the fisrt city with selected region
        if let index = getFirstSelectedCityIndex() {
            cityPicker.selectRow(index, inComponent: 0, animated: false)
        }
        
        ///Notify the slected city
        let row = cityPicker.selectedRowInComponent(0)
        let selectedCity = cityRegions[row].code // cityItems[0][row].value
        delegate?.onCitySelected(selectedCity)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("viewDidAppear: %@", self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("viewWillDisappear: %@", self)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension CityPickerViewController: UIPickerViewDataSource {
    
    // MARK: - PickerView DataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return CityPickerViewController.numberOfComponents
    }
}

extension CityPickerViewController: UIPickerViewDelegate {
    
    // MARK: - PickerView Delegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        let city = cityRegions[row]
        
        if let regionSelectionState = regionSelectionState {
            if let index = regionSelectionState.indexOf(city){
                let selectedRegions = regionSelectionState[index].regions
                let numberOfSelection = selectedRegions.count
                
                if(numberOfSelection > 0) {
                    
                    if(numberOfSelection == 1) {
                        if(selectedRegions[0] == Region.allRegions) {
                            return ("\(cityRegions[row].name) (\(Region.allRegions.name))")
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
}
