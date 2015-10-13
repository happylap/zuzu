//
//  AreaSelectionViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/12.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol CitySelectionViewControllerDelegate {
    func onCitySelected(value: Int)
}

class CitySelectionViewController:UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var cityPicker: UIPickerView!
    
    var delegate: CitySelectionViewControllerDelegate?
    
    var cityItems = [[(label:String, value:Int)]]()
    
    private func configurePricePicker() {
        cityPicker.dataSource = self
        cityPicker.delegate = self
    }
    
//    
//    private func configureRegionTable() {
//        
//        //Configure cell height
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.allowsSelection = false
//        
//        tableView.dataSource = self
//        tableView.delegate = self
//    }
    
    // MARK: - PickerView DataSource & Delegate
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return cityItems.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return cityItems[component][row].label
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cityItems[component].count
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedCity = cityItems[component][row].value
        
        delegate?.onCitySelected(selectedCity)
    }
    
    // MARK: - Table DataSource & Delegate
    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return regions.count
//    }
//    
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        
//        let cell = tableView.dequeueReusableCellWithIdentifier("regionCell", forIndexPath: indexPath)
//        
//        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
//        
//        
//        cell.textLabel?.text = regions[indexPath.row]
//
//        return cell
//    }
    
    // MARK: - View Controller Life Cycel
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("viewDidLoad: %@", self)
        
        if let path = NSBundle.mainBundle().pathForResource("areasInTaiwan", ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                
                //NSLog("Cities = %@", jsonData)
                
                let cities = json["cities"].arrayValue
                
                NSLog("Cities = %d", cities.count)
                
                var allCities = [(label:String, value:Int)]()
                
                for cityJsonObj in cities {
                    //Do something you want
                    let name = cityJsonObj["name"].stringValue
                    let code = cityJsonObj["code"].intValue
                    allCities.append( (name, code) )
                }
                
                cityItems.append(allCities)
                
            } catch let error as NSError{
                
                NSLog("Cannot load area json file %@", error)
                
            }
        }
        
        self.configurePricePicker()
        //self.configureRegionTable()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear: %@", self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("viewDidAppear: %@", self)
        
        let row = cityPicker.selectedRowInComponent(0)
        let selectedCity = cityItems[0][row].value
        
        delegate?.onCitySelected(selectedCity)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
}
