//
//  CityRegionContainerController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/13.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

private let Log = Logger.defaultLogger

protocol CityRegionContainerControllerDelegate: class {
    func onCitySelectionDone(regions: [City])
}

class CityRegionContainerController: UIViewController {

    var delegate: CityRegionContainerControllerDelegate?

    var isDataPrepared = false

    /// @Controller Input Params
    var itemCountByRegion: [String: Int]?

    var checkedRegions: [Int:[Bool]] = [Int:[Bool]]()//Region selected grouped by city
    var regionSelectionState: [City] = [City]()

    var codeToCityMap = ConfigLoader.CodeToCityMap //City dictionary by city code
    var cityList = ConfigLoader.SortedCityList //Sorted City list

    struct ViewTransConst {
        static let showRegionTable: String = "showRegionTable"
        static let showCityPicker: String = "showCityPicker"
    }

    weak var cityPicker: CityPickerViewController?
    weak var regionTable: RegionTableViewController?

    // MARK: - Private Utils

    private func initCityRegionSelectionData() {
        ///Init selection status for each city
        for city in cityList {
            let regionList = city.regions
            checkedRegions[city.code] = [Bool](count:regionList.count, repeatedValue: false)
        }

        ///Init selected regions
        for city in regionSelectionState {

            let selectedRegions = city.regions

            for region in selectedRegions {
                if let regionList = codeToCityMap[city.code]?.regions {

                    if let index = regionList.indexOf(region) { ///Region needs to be Equatable
                        checkedRegions[city.code]?[index] = true
                    }
                }
            }
        }
    }

    private func prepareDataIfNeeded() {
        if(!isDataPrepared) {
            initCityRegionSelectionData()
            isDataPrepared = true
        }
    }

    // MARK: - UI Control Actions
    @IBAction func onSelectionDone(sender: UIBarButtonItem) {

        Log.debug("onSelectionDone")

        //Save selection to user defaults only when the user presses "Done" button

        //dataStore.saveSelectedCityRegions(regionSelectionState)

        delegate?.onCitySelectionDone(regionSelectionState)

        navigationController?.popViewControllerAnimated(true)
        //navigationController?.popToRootViewControllerAnimated(true)
    }

    // MARK: - Notification Selector
    func onRegionSelectionUpdated(notification: NSNotification) {
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
        Log.debug("viewDidLoad: \(self)")

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CityRegionContainerController.onRegionSelectionUpdated(_:)), name: "regionSelectionChanged", object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.debug("viewWillAppear: \(self)")

        ///Hide tab bar
        self.tabBarController?.tabBarHidden = true

        //Google Analytics Tracker
        self.trackScreen()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Log.debug("viewWillDisappear: \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        Log.debug("parents view controller: \(parent)")
        if(parent == nil) {
            self.tabBarController?.tabBarHidden = false
        }
    }

    override func didReceiveMemoryWarning() {

        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // Load previously stored data
        prepareDataIfNeeded()

        if let identifier = segue.identifier {

            Log.debug("prepareForSegue: \(identifier) \(self)")

            switch identifier {
            case ViewTransConst.showCityPicker:

                if let vc = segue.destinationViewController as? CityPickerViewController {
                    cityPicker = vc
                    vc.allCities  = cityList
                    vc.regionSelectionState = regionSelectionState
                }

            case ViewTransConst.showRegionTable:

                if let vc = segue.destinationViewController as? RegionTableViewController {
                    regionTable = vc
                    vc.checkedRegions = checkedRegions
                    vc.codeToCityMap = codeToCityMap
                    vc.itemCountByRegion = self.itemCountByRegion
                }

            default: break
            }
        }

        if(cityPicker != nil && regionTable != nil) {
            cityPicker?.delegate = regionTable
        }
    }

}
