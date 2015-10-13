//
//  CityRegionContainerViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class CityRegionContainerViewController: UIViewController {
    
    var cityPicker:CitySelectionViewController?
    var regionTable:RegionTableViewController?
    
    struct ViewTransConst {
        static let showRegionTable:String = "showRegionTable"
        static let showCityPicker:String = "showCityPicker"
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func onSelectionDone(sender: UIBarButtonItem) {
        navigationController?.popToRootViewControllerAnimated(true)
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        NSLog("prepareForSegue: %@", self)
        
        if let identifier = segue.identifier{
            switch identifier{
            case ViewTransConst.showCityPicker:

                if let vc = segue.destinationViewController as? CitySelectionViewController {
                    cityPicker = vc
                }
                
            case ViewTransConst.showRegionTable:

                if let vc = segue.destinationViewController as? RegionTableViewController {
                    regionTable = vc
                }
            default: break
            }
        }
        
        if(cityPicker != nil && regionTable != nil) {
            cityPicker?.delegate = regionTable
        }
    }

}
