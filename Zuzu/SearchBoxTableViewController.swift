    //
    //  ZuzuTableViewController.swift
    //  Zuzu
    //
    //  Created by Jung-Shuo Pai on 2015/9/21.
    //  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
    //
    
    import UIKit
    import SwiftyJSON
    
    private let FileLog = Logger.fileLogger
    private let Log = Logger.defaultLogger
    
    class ToggleButtonListenr: ToggleStateListenr {
        
        let target: ToggleButton
        
        init(target: ToggleButton) {
            self.target = target
        }
        
        func onStateChanged(sender: AnyObject, state: Bool) {
            if let sourceButton = sender as? ToggleButton {
                //Toggle off all other buttons when "select all" button is toggled on
                if(sourceButton.getToggleState()) {
                    self.target.setToggleState(false)
                }
            }
        }
    }
    
    class SearchBoxTableViewController: UITableViewController {
        
        struct ViewTransConst {
            static let showSearchResult:String = "showSearchResult"
            static let showAreaSelector:String = "showAreaSelector"
        }
        
        struct UIControlTag {
            static let NOT_LIMITED_BUTTON_TAG = 99
        }
        
        struct CellConst {
            static let searchBar = 0
            static let area = 1
            static let houseType = 2
            static let priceLabel = 3
            static let pricePicker = 4
            static let sizeLabel = 5
            static let sizePicker = 6
            static let searchHistory = 8
        }
        
        // Price & Size Picker Vars
        struct PickerConst {
            static let anyLower:(label:String, value:Int) = ("0",CriteriaConst.Bound.LOWER_ANY)
            static let anyUpper:(label:String, value:Int) = ("不限",CriteriaConst.Bound.UPPER_ANY)
            static let upperBoundStartZero = 0
            
            static let lowerCompIdx = 0
            static let upperCompIdx = 1
        }
        
        var locationManagerActive = false {
            didSet {
                if(locationManagerActive) {
                    locationManager.startUpdatingLocation()
                } else {
                    locationManager.stopUpdatingLocation()
                }
            }
        }
        
        let locationManager = CLLocationManager()
        
        var regionSelectionState: [City]? {
            didSet {
                updateRegionLabel(regionSelectionState)
            }
        }
        
        var keywordTextChanged = false
        
        var sizeUpperRange:Range<Int>?
        var priceUpperRange:Range<Int>?
        
        let sizeItems:[[(label:String, value:Int)]] = SearchBoxTableViewController.loadPickerData("searchCriteriaOptions", criteriaLabel: "sizeRange")
        let priceItems:[[(label:String, value:Int)]] = SearchBoxTableViewController.loadPickerData("searchCriteriaOptions", criteriaLabel: "priceRange")
        
        // Trigger the fetching of total number of items that meet the current criteria
        lazy var stateObserver: SearchCriteriaObserver = SearchCriteriaObserver(viewController: self)
        
        // Data Store Insatance
        private let criteriaDataStore = UserDefaultsSearchCriteriaDataStore.getInstance()
        private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
        private let cityRegionDataStore = UserDefaultsCityRegionDataStore.getInstance()
        private let searchItemService = SearchItemService.getInstance()
        private lazy var searchItemTableDataSource: SearchItemTableViewDataSource = SearchItemTableViewDataSource(tableViewController: self)
        
        private func updateRegionLabel(regionSelection: [City]?) {
            
            var regionLabel = "不限"
            
            if let regionSelection = regionSelection {
                if(regionSelection.count > 0) {
                    var labelStr:[String] = [String]()
                    var numOfCity = 0
                    for city in regionSelection {
                        
                        if(city.regions.count == 0) {
                            continue
                        }
                        
                        if(labelStr.count < 3) {
                            labelStr.append("\(city.name) (\(city.regions.count))")
                        }
                        numOfCity++
                    }
                    
                    regionLabel = labelStr.joinWithSeparator("，") + ((numOfCity > 3) ? " ..." : "")
                    
                } else {
                    self.fastItemCountLabel.text = nil
                }
            }
            
            cityRegionLabel.text = regionLabel
            
        }
        
        var currentCriteria: SearchCriteria = SearchCriteria() {
            
            didSet{
                
                if !(oldValue == currentCriteria) {
                    filterDataStore.clearFilterSetting()
                    
                    stateObserver.onCriteriaChanged(currentCriteria)
                    
                    ///Reset the prefetch house number label
                    self.fastItemCountLabel.text = nil
                    
                    ///Save search criteria and enable reset button
                    if(!currentCriteria.isEmpty()) {
                        criteriaDataStore.saveSearchCriteria(currentCriteria)
                        clearCriteriaButton.enabled = true
                    }
                    
                    ///Load the criteria to the Search Box UI
                    self.populateViewFromSearchCriteria(currentCriteria)
                }
            }
        }
        
        var selectAllButton:ToggleButton!
        
        
        @IBOutlet weak var clearCriteriaButton: UIButton! {
            didSet {
                
                clearCriteriaButton.setTitleColor(UIColor.orangeColor(), forState: UIControlState.Normal)
                clearCriteriaButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Disabled)
                clearCriteriaButton.enabled = false
                clearCriteriaButton.addTarget(self, action: "onClearCriteriaButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                
            }
        }
        
        @IBOutlet weak var typeButtonContainer: UIView! {
            didSet {
                let views = typeButtonContainer.subviews
                
                selectAllButton = typeButtonContainer.viewWithTag(UIControlTag.NOT_LIMITED_BUTTON_TAG) as? ToggleButton
                
                if(selectAllButton != nil) {
                    selectAllButton!.toggleButtonState()
                    
                    //Other type buttons are controlled by "select all" button
                    for view in views {
                        if let typeButton = view as? ToggleButton {
                            if(typeButton.tag !=
                                UIControlTag.NOT_LIMITED_BUTTON_TAG){
                                    selectAllButton!.addStateListener(ToggleButtonListenr(target: typeButton))
                            }
                            
                            typeButton.addTarget(self, action: "onTypeButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
                        }
                    }
                }
            }
        }
        
        @IBOutlet weak var fastItemCountLabel: UILabel!
        @IBOutlet weak var cityRegionLabel: UILabel!
        @IBOutlet weak var sizeLabel: UILabel!
        @IBOutlet weak var priceLabel: UILabel!
        @IBOutlet weak var sizePicker: UIPickerView!
        @IBOutlet weak var pricePicker: UIPickerView!
        
        @IBOutlet weak var searchItemTable: UITableView!
        @IBOutlet weak var searchItemSegment: UISegmentedControl!
        
        @IBOutlet weak var searchBar: UISearchBar! {
            didSet {
                searchBar.delegate = self
            }
        }
        @IBOutlet weak var searchButton: UIButton! {
            didSet {
                searchButton.addTarget(self, action: "onSearchButtonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
        
        // MARK: - Private Utils
        
        private func alertInvalidRegionSelection() {
            // Initialize Alert View
            
            let alertView = UIAlertView(
                title: "請選擇地區",
                message: "請選擇地區以進行搜尋",
                delegate: self,
                cancelButtonTitle: "知道了")
            
            // Show Alert View
            alertView.show()
            
            // Delay the dismissal
            self.runOnMainThreadAfter(2.0) {
                alertView.dismissWithClickedButtonIndex(-1, animated: true)
            }
        }
        
        private func pickerRangeToString(pickerView: UIPickerView, pickerFrom:(component:Int, row:Int), pickerTo:(component:Int, row:Int)) -> String{
            
            var pickerStr:String = ""
            
            let fromTuple = self.getItemForPicker(pickerView, component: pickerFrom.component, row: pickerFrom.row)
            let toTuple = self.getItemForPicker(pickerView, component: pickerTo.component, row: pickerTo.row)
            
            if(pickerView == pricePicker) {
                Log.debug("pricePicker: Upper: \(toTuple)")
            }
            
            if(fromTuple?.value == toTuple?.value) {
                pickerStr = "\((toTuple?.label)!)"
            } else {
                pickerStr = "\((fromTuple?.label)!) — \((toTuple?.label)!)"
            }
            
            return pickerStr
        }
        
        private func loadSearchItemsForSegment(index: Int) {
            if(index == 1) {
                
                searchItemTableDataSource.itemType = .HistoricalSearch
            } else if(index == 0) {
                
                searchItemTableDataSource.itemType = .SavedSearch
            } else {
                assert(false, "Invalid Segment!")
            }
        }
        
        private func configureButton() {
            
            searchButton.layer.borderWidth = 2
            searchButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            searchButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            searchButton
                .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Normal)
            searchButton
                .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Selected)
            
            //searchButton.tintColor = color
            //searchButton.backgroundColor = color
            
            //let edgeInsets:UIEdgeInsets = UIEdgeInsets(top:4,left: 4,bottom: 4,right: 4)
            
            //let buttonImg = UIImage(named: "purple_button")!
            
            //let buttonInsetsImg:UIImage = buttonImg.imageWithAlignmentRectInsets(edgeInsets)
            
            //searchButton.setBackgroundImage(buttonInsetsImg, forState: UIControlState.Normal)
        }
        
        private func configurePricePicker() {
            
            sizePicker.dataSource = self
            sizePicker.delegate = self
            
            pricePicker.dataSource = self
            pricePicker.delegate = self
        }
        
        private func configureGestureRecognizer() {
            let tap = UITapGestureRecognizer(target: self, action: "handleTap:")
            /// Setting this property to false will enable forward the touch event
            /// to the original UI after handled by UITapGestureRecognizer
            tap.cancelsTouchesInView = false
            tap.delegate = self
            tableView.addGestureRecognizer(tap)
        }
        
        private func configureSearchBoxTable() {
            //tableView.backgroundView = nil
            tableView.backgroundColor = UIColor.whiteColor()
            
            //Remove extra cells when the table height is smaller than the screen
            tableView.tableFooterView = UIView(frame: CGRectZero)
            
            //Configure cell height
            tableView.delegate = self
        }
        
        private func configureSearchHistoryTable() {
            
            //Segments UI config
            searchItemSegment.tintColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            searchItemSegment.setTitleTextAttributes(
                [NSForegroundColorAttributeName : UIColor.blackColor(),
                    NSFontAttributeName: UIFont.systemFontOfSize(16)],
                forState: .Normal)
            searchItemSegment.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.whiteColor()], forState: .Selected)
            
            //Remove extra cells when the table height is smaller than the screen
            searchItemTable.tableFooterView = UIView(frame: CGRectZero)
            
            //Set delegate & datasource
            searchItemTable.dataSource = searchItemTableDataSource
            searchItemTable.delegate = searchItemTableDataSource
        }
        
        
        private func setRowVisible(row: Int, visible: Bool) {
            if(visible) {
                hiddenCells.remove(row)
            } else {
                if(!hiddenCells.contains(row)) {
                    hiddenCells.insert(row)
                }
            }
            
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0), animated: false)
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        private func handlePicker(indexPath:NSIndexPath) {
            var picker:UIPickerView?
            
            switch(indexPath.row) {
            case CellConst.priceLabel: // Price Picker
                picker = pricePicker
                if(hiddenCells.contains(CellConst.pricePicker)) {
                    hiddenCells.insert(CellConst.sizePicker)
                    hiddenCells.remove(CellConst.pricePicker)
                } else { //Hide
                    hiddenCells.insert(CellConst.pricePicker)
                }
                
            case CellConst.sizeLabel: // Size Picker
                picker = sizePicker
                if(hiddenCells.contains(CellConst.sizePicker)) {
                    hiddenCells.insert(CellConst.pricePicker)
                    hiddenCells.remove(CellConst.sizePicker)
                } else { //Hide
                    hiddenCells.insert(CellConst.sizePicker)
                }
            default: break
            }
            
            if(picker != nil) {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
        
        private func resetSearchBox() {
            ///Keywords
            searchBar.text = nil
            
            ///Region
            regionSelectionState = nil
            
            ///Price Range
            
            let pickerPriceFrom:(component:Int, row:Int) = (0,0)
            let pickerPriceTo:(component:Int, row:Int) = (1,0)
            pricePicker.selectRow(pickerPriceFrom.row, inComponent: pickerPriceFrom.component, animated: true)
            pricePicker.selectRow(pickerPriceTo.row, inComponent: pickerPriceTo.component, animated: true)
            
            priceLabel.text = PickerConst.anyUpper.label
            
            ///Size Range
            let pickerSizeFrom:(component:Int, row:Int) = (0,0)
            let pickerSizeTo:(component:Int, row:Int) = (1,0)
            sizePicker.selectRow(pickerSizeFrom.row, inComponent: pickerSizeFrom.component, animated: true)
            sizePicker.selectRow(pickerSizeTo.row, inComponent: pickerSizeTo.component, animated: true)
            sizeLabel.text =  PickerConst.anyUpper.label
            
            //Check each type button (each with a different tag as set in the Story Board)
            for tag in (1...5) {
                
                if let typeButton = typeButtonContainer.viewWithTag(tag) as? ToggleButton {
                    typeButton.setToggleState(false)
                }
            }
            //At lease one type is selected, so "Select All" button can be set to false
            selectAllButton.setToggleState(true)
        }
        
        private func populateViewFromSearchCriteria(criteria: SearchCriteria) {
            
            ///Keywords
            searchBar.text = criteria.keyword
            
            ///Region
            regionSelectionState = criteria.region
            
            ///Price Range
            
            var pickerPriceFrom:(component:Int, row:Int) = (0,0)
            var pickerPriceTo:(component:Int, row:Int) = (1,0)
            
            if let priceRange = criteria.price {
                
                ///Get Lower Bound Index
                for (index, price) in priceItems[PickerConst.lowerCompIdx].enumerate() {
                    if(priceRange.0 == price.value) {
                        
                        pickerPriceFrom = (PickerConst.lowerCompIdx, index + 1)
                        Log.debug("pickerPriceFrom = \(pickerPriceFrom)")
                        break
                    }
                }
                
                //Update Price Picker Upper Bound Range based on Lower Bound selection
                priceUpperRange = getUpperBoundRangeForPicker(priceRange.0, items: priceItems)
                Log.debug("priceUpperRange = \(priceUpperRange)")
                
                ///Get Upper Bound Index
                if let priceUpperRange = priceUpperRange {
                    for (index, price) in priceItems[PickerConst.upperCompIdx].enumerate() {
                        if(priceRange.1 == price.value) {
                            
                            pickerPriceTo = (PickerConst.upperCompIdx, index - priceUpperRange.startIndex + 1)
                            Log.debug("pickerPriceTo = \(pickerPriceTo)")
                            break
                        }
                    }
                }
            } else {
                
                //Update Price Picker Upper Bound Range based on Lower Bound selection
                priceUpperRange = getUpperBoundRangeForPicker(PickerConst.anyLower.value, items: priceItems)
                Log.debug("priceUpperRange = \(priceUpperRange)")
                
            }
            
            //Reload for New Upper Bound Index (Number of items may be less)
            pricePicker.reloadComponent(PickerConst.upperCompIdx)
            pricePicker.selectRow(pickerPriceFrom.row, inComponent: pickerPriceFrom.component, animated: true)
            pricePicker.selectRow(pickerPriceTo.row, inComponent: pickerPriceTo.component, animated: true)
            
            priceLabel.text =
                pickerRangeToString(pricePicker, pickerFrom: pickerPriceFrom, pickerTo: pickerPriceTo)
            
            ///Size Range
            var pickerSizeFrom:(component:Int, row:Int) = (0,0)
            var pickerSizeTo:(component:Int, row:Int) = (1,0)
            
            if let sizeRange = criteria.size {
                
                for (index, size) in sizeItems[PickerConst.lowerCompIdx].enumerate() {
                    if(sizeRange.0 == size.value) {
                        pickerSizeFrom = (PickerConst.lowerCompIdx, index + 1)
                    }
                }
                
                //Update Size Picker Upper Bound display range based on Lower Bound selection
                sizeUpperRange = getUpperBoundRangeForPicker(sizeRange.0, items: sizeItems)
                Log.debug("sizeUpperRange = \(sizeUpperRange)")
                
                if let sizeUpperRange = sizeUpperRange {
                    for (index, size) in sizeItems[PickerConst.upperCompIdx].enumerate() {
                        if(sizeRange.1 == size.value) {
                            pickerSizeTo = (PickerConst.upperCompIdx, index - sizeUpperRange.startIndex + 1)
                        }
                    }
                }
            } else {
                
                //Update Size Picker Upper Bound display range based on Lower Bound selection
                sizeUpperRange = getUpperBoundRangeForPicker(PickerConst.anyLower.value, items: sizeItems)
                Log.debug("sizeUpperRange = \(sizeUpperRange)")
            }
            
            //Reload for New Upper Bound Index (Number of items may be less)
            sizePicker.reloadComponent(PickerConst.upperCompIdx)
            sizePicker.selectRow(pickerSizeFrom.row, inComponent: pickerSizeFrom.component, animated: true)
            sizePicker.selectRow(pickerSizeTo.row, inComponent: pickerSizeTo.component, animated: true)
            
            sizeLabel.text = pickerRangeToString(sizePicker, pickerFrom: pickerSizeFrom, pickerTo: pickerSizeTo)
            
            ///House Types
            if let houseTypes = criteria.types {
                
                //Check each type button (each with a different tag as set in the Story Board)
                for tag in (1...5) {
                    
                    if let typeButton = typeButtonContainer.viewWithTag(tag) as? ToggleButton {
                        
                        var type:Int?
                        
                        switch tag {
                            
                        case 1:
                            type = CriteriaConst.PrimaryType.FULL_FLOOR
                        case 2:
                            type = CriteriaConst.PrimaryType.SUITE_INDEPENDENT
                        case 3:
                            type = CriteriaConst.PrimaryType.SUITE_COMMON_AREA
                        case 4:
                            type = CriteriaConst.PrimaryType.ROOM_NO_TOILET
                        case 5:
                            type = CriteriaConst.PrimaryType.HOME_OFFICE
                            
                        default: break
                        }
                        
                        if(houseTypes.contains(type!)) {
                            typeButton.setToggleState(true)
                        } else {
                            typeButton.setToggleState(false)
                        }
                    }
                }
                //At lease one type is selected, so "Select All" button can be set to false
                selectAllButton.setToggleState(false)
                
            } else {
                selectAllButton.setToggleState(true)
            }
            
        }
        
        private func stateToSearhCriteria() -> SearchCriteria {
            
            let searchCriteria = SearchCriteria()
            
            ///Keywords
            searchCriteria.keyword = searchBar.text
            
            ///Region
            searchCriteria.region = regionSelectionState
            
            ///Price Range
            let priceMinRow =
            pricePicker.selectedRowInComponent(PickerConst.lowerCompIdx)
            let priceMaxRow =
            pricePicker.selectedRowInComponent(PickerConst.upperCompIdx)
            
            if let priceMin = getItemForPicker(pricePicker, component: PickerConst.lowerCompIdx, row: priceMinRow),
                let priceMax = getItemForPicker(pricePicker, component: PickerConst.upperCompIdx, row: priceMaxRow) {
                    
                    if(priceMin.value != PickerConst.anyLower.value || priceMax.value != PickerConst.anyUpper.value) {
                        searchCriteria.price = (priceMin.value, priceMax.value)
                    }
                    
            }
            
            ///Size Range
            let sizeMinRow =
            sizePicker.selectedRowInComponent(PickerConst.lowerCompIdx)
            let sizeMaxRow =
            sizePicker.selectedRowInComponent(PickerConst.upperCompIdx)
            
            if let sizeMin = getItemForPicker(sizePicker, component: PickerConst.lowerCompIdx, row: sizeMinRow),
                let sizeMax = getItemForPicker(sizePicker, component: PickerConst.upperCompIdx, row: sizeMaxRow){
                    
                    if(sizeMin.value != PickerConst.anyLower.value || sizeMax.value != PickerConst.anyUpper.value) {
                        searchCriteria.size = (sizeMin.value, sizeMax.value)
                    }
            }
            
            ///House Types
            var typeList = [Int]()
            
            if(selectAllButton.getToggleState() == false) {
                let views = typeButtonContainer.subviews
                
                //Other type buttons are controlled by "select all" button
                for view in views {
                    if let typeButton = view as? ToggleButton {
                        if(typeButton.tag !=
                            UIControlTag.NOT_LIMITED_BUTTON_TAG){
                                if(typeButton.getToggleState()) {
                                    switch typeButton.tag {
                                    case 1:
                                        typeList.append(CriteriaConst.PrimaryType.FULL_FLOOR)
                                    case 2:
                                        typeList.append(CriteriaConst.PrimaryType.SUITE_INDEPENDENT)
                                    case 3:
                                        typeList.append(CriteriaConst.PrimaryType.SUITE_COMMON_AREA)
                                    case 4:
                                        typeList.append(CriteriaConst.PrimaryType.ROOM_NO_TOILET)
                                    case 5:
                                        typeList.append(CriteriaConst.PrimaryType.HOME_OFFICE)
                                    default: break
                                    }
                                }
                        }
                    }
                }
                
                if(typeList.count > 0) {
                    searchCriteria.types = typeList
                }
            }
            
            return searchCriteria
        }
        
        // MARK: - UI Control Actions
        
        
        //The UI control event handler Should not be private
        
        @IBAction func onOpenFanPage(sender: UIBarButtonItem) {
            
            var targetUrl:String?
            var result = false
            
            ///Open by Facebook App
            if let url = NSURL(string: "fb://profile/1675724006047703") {
                
                if(UIApplication.sharedApplication().canOpenURL(url)) {
                    
                    result = UIApplication.sharedApplication().openURL(url)
                    targetUrl = url.absoluteString
                }
                
            }
            
            ///Open by Browser
            if(!result) {
                if let url = NSURL(string: "https://www.facebook.com/zuzutw") {
                    
                    if(UIApplication.sharedApplication().canOpenURL(url)) {
                        
                        result = UIApplication.sharedApplication().openURL(url)
                        targetUrl = url.absoluteString
                    }
                    
                }
            }
            
            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.FanPage,
                label: targetUrl ?? "", value: Int(result))
            
            
        }
        
        @IBAction func onSegmentClicked(sender: UISegmentedControl) {
            
            loadSearchItemsForSegment(sender.selectedSegmentIndex)
            
            //Scroll to the bottom of the table to see the search item table fully
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: CellConst.searchHistory, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        
        func onClearCriteriaButtonTouched(sender: UIButton) {
            self.criteriaDataStore.clear()
            self.currentCriteria = SearchCriteria()
            
            clearCriteriaButton.enabled = false
            
            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.ResetCriteria)
        }
        
        func onTypeButtonTouched(sender: UIButton) {
            if let toogleButton = sender as? ToggleButton {
                
                if(toogleButton.tag == UIControlTag.NOT_LIMITED_BUTTON_TAG) {
                    
                    //Only allow toggling the "select all" button when it's off
                    if (!selectAllButton.getToggleState()) {
                        
                        selectAllButton.setToggleState(true)
                        
                        currentCriteria = self.stateToSearhCriteria()
                    }
                    
                } else {
                    
                    toogleButton.toggleButtonState()
                    
                    //Toggle off the select all button if any type is selected
                    if(toogleButton.getToggleState()) {
                        selectAllButton.setToggleState(false)
                    }
                    
                    currentCriteria = self.stateToSearhCriteria()
                }
                
                
            }
        }
        
        func onSearchButtonClicked(sender: UIButton) {
            Log.debug("onSearchButtonClicked: \(self)")
            
            //Hide size & price pickers
            self.setRowVisible(CellConst.pricePicker, visible: false)
            self.setRowVisible(CellConst.sizePicker, visible: false)
            
            //Validate field
            if(currentCriteria.region?.count <= 0) {
                alertInvalidRegionSelection()
                return
            }
            
            //present the view modally (hide the tabbar)
            performSegueWithIdentifier(ViewTransConst.showSearchResult, sender: nil)
        }
        
        func dismissCurrentView(sender: UIBarButtonItem) {
            navigationController?.popToRootViewControllerAnimated(true)
        }
        
        // MARK: - Table Delegate
        
        override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
            switch(indexPath.row) {
            case CellConst.sizeLabel, CellConst.priceLabel: // Price, Size Picker
                handlePicker(indexPath)
                
            case CellConst.area: //Area Picker
                ///With modal transition, this segue may be very slow without explicitly send it to the main ui queue
                self.performSegueWithIdentifier(ViewTransConst.showAreaSelector, sender: nil)
                
                
            default: break
            }
            
        }
        
        var hiddenCells:Set<Int> = [CellConst.pricePicker, CellConst.sizePicker]
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            
            Log.debug("heightForRowAtIndexPath\(indexPath)")
            
            if(hiddenCells.contains(indexPath.row)) {
                return 0
            } else {
                if (indexPath.row == CellConst.pricePicker) {
                    return pricePicker.intrinsicContentSize().height
                }
                if (indexPath.row == CellConst.sizePicker) {
                    return sizePicker.intrinsicContentSize().height
                }
            }
            
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            
            /* Use Autolayout decided size
            let cellView = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
            
            return cellView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            */
            
        }
        
        // MARK: - View Life Cycle
        override func viewDidLoad() {
            super.viewDidLoad()
            
            NSLog("Begin viewDidLoad: %@", self)
            self.configureButton()
            
            self.configureSearchHistoryTable()
            
            self.configureSearchBoxTable()
            
            //searchItemsDataStore.clearSearchItems()
            //cityRegionDataStore.clearSelectedCityRegions()
            
            //Confugure Price Picker
            sizeUpperRange = (PickerConst.upperBoundStartZero...self.sizeItems[1].count - 1)
            priceUpperRange = (PickerConst.upperBoundStartZero...self.priceItems[1].count - 1)
            
            self.configurePricePicker()
            
            //Configure Guesture
            self.configureGestureRecognizer()
            
            //Load Search Criteria
            if let criteria = criteriaDataStore.loadSearchCriteria() {
                
                if(!criteria.isEmpty()) {
                    currentCriteria.keyword = criteria.keyword
                    currentCriteria.region = criteria.region
                    currentCriteria.price  = criteria.price
                    currentCriteria.size = criteria.size
                    currentCriteria.types = criteria.types
                    
                    self.populateViewFromSearchCriteria(currentCriteria)
                    
                    clearCriteriaButton.enabled = true
                }
            }
            
            //Configure location manager
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            
            //Try to start monitoring location
            if let regionList = currentCriteria.region where !regionList.isEmpty {
                locationManagerActive = false
            } else {
                locationManagerActive = true
            }
            
            NSLog("End viewDidLoad: %@", self)
        }
        
        func handleTap(sender:UITapGestureRecognizer) {
            Log.debug("handleTap: view = \(sender.view)")
            searchBar.resignFirstResponder()
        }
        
        override func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            
            //Scroll main table to the Search Bar
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: CellConst.searchBar, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            
            //Load search item segment data
            loadSearchItemsForSegment(searchItemSegment.selectedSegmentIndex)
            
            //Scroll search history table to the top
            if(searchItemTable.numberOfRowsInSection(0) > 0) {
                self.searchItemTable.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            }
            
            //Restore hidden tab bar before apeearing
            self.tabBarController!.tabBarHidden = false
            
            //Google Analytics Tracker
            self.trackScreen()
        }
        
        override func viewDidAppear(animated: Bool) {
            super.viewDidAppear(animated)
            NSLog("viewDidAppear: %@", self)
            self.stateObserver.start()
        }
        
        override func viewDidDisappear(animated: Bool) {
            super.viewDidDisappear(animated)
            NSLog("viewDidDisappear: %@", self)
        }
        
        // MARK: - Navigation
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            
            NSLog("prepareForSegue: %@", self)
            
            if let identifier = segue.identifier{
                switch identifier{
                case ViewTransConst.showSearchResult:
                    NSLog("showSearchResult")
                    if let srtvc = segue.destinationViewController as? SearchResultViewController {
                        
                        ///GA Tracker
                        dispatch_async(GlobalBackgroundQueue) {
                            
                            if let keyword = self.currentCriteria.keyword {
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                    action: GAConst.Action.Criteria.Keyword, label: keyword)
                            }
                            
                            if let priceRange = self.currentCriteria.price {
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                    action: GAConst.Action.Criteria.PriceMin,
                                    label: String(priceRange.0))
                                
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                    action: GAConst.Action.Criteria.PriceMax,
                                    label: String(priceRange.1))
                            }
                            
                            if let sizeRange = self.currentCriteria.size {
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                    action: GAConst.Action.Criteria.SizeMin,
                                    label: String(sizeRange.0))
                                
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                    action: GAConst.Action.Criteria.SizeMax,
                                    label: String(sizeRange.1))
                            }
                            
                            if let types = self.currentCriteria.types {
                                for type in types {
                                    self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                        action: GAConst.Action.Criteria.Type, label: String(type))
                                }
                            } else {
                                self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria, action:
                                    GAConst.Action.Criteria.Type, label: "99")
                            }
                            
                        }
                        
                        ///Collect the search criteria set by the user
                        srtvc.searchCriteria = currentCriteria
                        
                        ///Save the final search criteria
                        if(!currentCriteria.isEmpty()) {
                            criteriaDataStore.saveSearchCriteria(currentCriteria)
                        }
                        
                        ///Save search history (works like a ring buffer, delete the oldest record if maxItemSize is exceeded)
                        
                        if let historicalItems =  searchItemService.getSearchItemsByType(.HistoricalSearch) {
                            
                            if(historicalItems.count >= SearchItemService.maxItemSize) {
                                let deleteIndex = historicalItems.endIndex - 1
                                searchItemService.deleteSearchItem(deleteIndex, itemType: .HistoricalSearch)
                            }
                        }
                        
                        do{
                            try searchItemService.addNewSearchItem(SearchItem(criteria: currentCriteria, type: .HistoricalSearch))
                        } catch {
                            NSLog("Fail to save search history")
                        }
                        
                    }
                case ViewTransConst.showAreaSelector:
                    NSLog("showAreaSlector")
                    
                    ///Setup delegat to receive result
                    if let vc = segue.destinationViewController as? CityRegionContainerController {
                        vc.delegate = self
                        
                        if let regionSelectionState = currentCriteria.region {
                            vc.regionSelectionState = regionSelectionState
                        }
                    }
                    
                    navigationItem.backBarButtonItem = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: "dismissCurrentView:")
                    
                default: break
                }
            }
        }
        
    }
    
    
    extension SearchBoxTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
        
        // MARK: - Private Utils
        
        private static func loadPickerData(resourceName: String, criteriaLabel: String) ->  [[(label:String, value:Int)]]{
            
            var resultItems = Array(count: 2, repeatedValue: [(label: String, value: Int)]() )
            
            if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
                
                ///Load all picker data from json
                do {
                    let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                    let json = JSON(data: jsonData)
                    let items = json[criteriaLabel].arrayValue
                    
                    Log.debug("\(criteriaLabel) = \(items.count)")
                    
                    for itemJsonObj in items {
                        let label = itemJsonObj["label"].stringValue
                        let value = itemJsonObj["value"].intValue
                        
                        resultItems[0].append( (label: label, value: value) )
                        resultItems[1].append( (label: label, value: value) )
                    }
                    
                    Log.debug("LowerItems = \(resultItems[0])")
                    Log.debug("UpperItems = \(resultItems[1])")
                    
                } catch let error as NSError{
                    
                    Log.error("Cannot load area json file \(error)")
                    
                } catch {
                    Log.error("Cannot load area json file")
                }
            }
            
            return resultItems
        }
        
        private func getUpperBoundRangeForPicker(lowerSelectedValue: Int, items: [[(label:String, value:Int)]]) -> Range<Int>?{
            
            let upperItems = items[PickerConst.upperCompIdx]
            
            ///Do not need to update Upper Bound values if there is not limit on Lower Bound
            if(lowerSelectedValue == PickerConst.anyLower.value) {
                return (PickerConst.upperBoundStartZero...upperItems.count - 1)
            }
            
            var hasLargerValue:Bool = false
            
            for (index, item) in upperItems.enumerate() {
                if(item.value > lowerSelectedValue) {
                    hasLargerValue = true
                    return (index...upperItems.count - 1)
                }
            }
            
            if(!hasLargerValue) {
                return nil
            }
        }
        
        ///Consider encapsulating items with any value in a class...
        private func getItemForPicker(pickerView: UIPickerView, component: Int, row: Int) ->  (label:String, value:Int)? {
            
            ///1st row is always "any value"
            if(row == 0){
                if(component == PickerConst.lowerCompIdx) {
                    return PickerConst.anyLower
                }
                if(component == PickerConst.upperCompIdx) {
                    return PickerConst.anyUpper
                }
            }
            
            var targetItems:[[(label:String, value:Int)]]
            var targetUpperRange:Range<Int>?
            
            switch(pickerView) {
            case sizePicker:
                targetItems = sizeItems
                targetUpperRange = sizeUpperRange
            case pricePicker:
                targetItems = priceItems
                targetUpperRange = priceUpperRange
                
                if(component == PickerConst.upperCompIdx) {
                    Log.debug("Price targetUpperRange: \(targetUpperRange)")
                }
            default:
                assert(false,"Invalid picker view")
                return nil
            }
            
            let idxWithoutAnyValue = row - 1
            
            ///Upper values are limited to valus greater than the selected lower value
            if(component == PickerConst.upperCompIdx) {
                if (targetUpperRange == nil) {
                    assert(false,"There should be no item except for any value")
                    return nil
                }
                
                if(pickerView == pricePicker) {
                    Log.debug("Index: \(idxWithoutAnyValue + targetUpperRange!.startIndex), Label: \(targetItems[component][idxWithoutAnyValue + targetUpperRange!.startIndex])")
                }
                
                return targetItems[component][idxWithoutAnyValue + targetUpperRange!.startIndex]
            }
            
            return targetItems[component][idxWithoutAnyValue]
        }
        
        // MARK: - Picker Data Source & Delegate
        func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
            
            switch(pickerView) {
            case sizePicker:
                return sizeItems.count
            case pricePicker:
                return priceItems.count
            default:
                return 0
            }
        }
        
        func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            
            if let rowItem = self.getItemForPicker(pickerView, component: component, row: row) {
                
                if(pickerView == pricePicker && component == 1) {
                    Log.debug("Upper Price: com = \(component), row = \(row), label = \(rowItem.label)")
                }
                
                return rowItem.label
            } else {
                return ""
            }
        }
        
        func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            
            var targetItems:[[(label:String, value:Int)]]
            var targetUpperRange:Range<Int>?
            
            switch(pickerView) {
            case sizePicker:
                targetItems = sizeItems
                targetUpperRange = sizeUpperRange
                
            case pricePicker:
                targetItems = priceItems
                targetUpperRange = priceUpperRange
            default:
                return 0
            }
            
            let numOfItemsWithAnyValue = targetItems[component].count + 1
            
            if(component == targetItems.endIndex - 1) {
                
                if targetUpperRange == nil {
                    return 1 //Only Any Value exisy
                }
                
                if(pickerView == pricePicker) {
                    Log.debug("Upper Price Num Items: \(numOfItemsWithAnyValue - targetUpperRange!.startIndex)")
                }
                return numOfItemsWithAnyValue - targetUpperRange!.startIndex
            }
            
            return numOfItemsWithAnyValue
        }
        
        private func updatePickerSelectionLabel(
            pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int, targetItems: [[(label: String, value: Int)]]) {
                
                var targetLabel:UILabel
                
                switch(pickerView) {
                case sizePicker:
                    targetLabel = sizeLabel
                case pricePicker:
                    targetLabel = priceLabel
                default:
                    return
                }
                
                var pickerFrom:(component:Int, row:Int) = (0,0)
                var pickerTo:(component:Int, row:Int) = (0,0)
                
                if(component == PickerConst.lowerCompIdx) {
                    let fromItemIdx = row
                    let toItemIdx = pickerView.selectedRowInComponent(targetItems.endIndex - 1)
                    
                    pickerFrom = (component, fromItemIdx)
                    pickerTo = ((targetItems.endIndex - 1), toItemIdx)
                    
                }else if(component == PickerConst.upperCompIdx) {
                    let fromItemIdx = pickerView.selectedRowInComponent(targetItems.startIndex)
                    let toItemIdx = row
                    
                    pickerFrom = (component: (targetItems.startIndex), row: fromItemIdx)
                    pickerTo = (component: component, row: toItemIdx)
                    
                }else {
                    assert(false, "Strange component index!")
                }
                
                let fromTuple = self.getItemForPicker(pickerView, component: pickerFrom.component, row: pickerFrom.row)
                let toTuple = self.getItemForPicker(pickerView, component: pickerTo.component, row: pickerTo.row)
                
                if(fromTuple?.label == toTuple?.label) {
                    targetLabel.text = "\((fromTuple?.label)!)"
                } else {
                    targetLabel.text = "\((fromTuple?.label)!) — \((toTuple?.label)!)"
                }
                
                targetLabel.text = pickerRangeToString(pickerView, pickerFrom: pickerFrom, pickerTo: pickerTo)
                
        }
        
        func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            
            
            var targetItems:[[(label:String, value:Int)]]
            
            switch(pickerView) {
            case sizePicker:
                targetItems = sizeItems
            case pricePicker:
                targetItems = priceItems
            default:
                return
            }
            
            ///Try to refresh upper picker component items if lower component selection is changed
            if(component == PickerConst.lowerCompIdx) {
                
                var upperRangeDiff = 0
                
                switch(pickerView) {
                case sizePicker:
                    
                    let prevStart = sizeUpperRange?.startIndex
                    
                    if let lowerSelected = getItemForPicker(sizePicker, component: PickerConst.lowerCompIdx, row: row) {
                        sizeUpperRange = getUpperBoundRangeForPicker(lowerSelected.value, items: targetItems)
                    } else {
                        sizeUpperRange = getUpperBoundRangeForPicker(PickerConst.anyLower.value, items: targetItems)
                    }
                    
                    if let sizeUpperRange = sizeUpperRange, prevStart = prevStart {
                        upperRangeDiff =  sizeUpperRange.startIndex - prevStart
                    }
                    
                case pricePicker:
                    
                    let prevStart = priceUpperRange?.startIndex
                    
                    if let lowerSelected = getItemForPicker(pricePicker, component: PickerConst.lowerCompIdx, row: row) {
                        priceUpperRange = getUpperBoundRangeForPicker(lowerSelected.value, items: targetItems)
                    } else {
                        priceUpperRange = getUpperBoundRangeForPicker(PickerConst.anyLower.value, items: targetItems)
                    }
                    
                    if let priceUpperRange = priceUpperRange, prevStart = prevStart  {
                        upperRangeDiff =  priceUpperRange.startIndex - prevStart
                    }
                    
                default:
                    return
                }
                
                //Reload for new index
                pickerView.reloadComponent(PickerConst.upperCompIdx)
                
                //Select the first item if the original selected item is not in range (Just a temp & consistent solution)
                var selectedRow = pickerView.selectedRowInComponent(PickerConst.upperCompIdx)
                
                if(selectedRow != PickerConst.upperBoundStartZero) {
                    selectedRow = max(selectedRow - upperRangeDiff, PickerConst.upperBoundStartZero)
                }
                
                
                pickerView.selectRow(selectedRow, inComponent: PickerConst.upperCompIdx, animated: false)
            }
            
            //Update selection label
            updatePickerSelectionLabel(pickerView, didSelectRow: row, inComponent: component, targetItems: targetItems)
            
            currentCriteria = self.stateToSearhCriteria()
        }
    }
    
    extension SearchBoxTableViewController: UISearchBarDelegate {
        
        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            if let touch = touches.first {
                if (searchBar.isFirstResponder() && touch.view != searchBar) {
                    searchBar.resignFirstResponder()
                }
            }
            super.touchesBegan(touches, withEvent:event)
        }
        
        // MARK: - UISearchBarDelegate
        func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
            Log.debug("textDidChange: \(self), \(searchText)")
            keywordTextChanged = true
        }
        func searchBarSearchButtonClicked(searchBar: UISearchBar) {
            Log.debug("searchBarSearchButtonClicked: \(self)")
            searchBar.resignFirstResponder()
        }
        
        func searchBarTextDidEndEditing(searchBar: UISearchBar) {
            Log.debug("searchBarTextDidEndEditing: \(self)")
            searchBar.resignFirstResponder()
            
            if(keywordTextChanged) {
                currentCriteria = self.stateToSearhCriteria()
            }
            
            keywordTextChanged = false
        }
    }
    
    extension SearchBoxTableViewController: UIGestureRecognizerDelegate {
        ///We do not need the following code now. it's a good way to decide when we don't want UIGestureRecognizer selector to be triggered
        func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
            
            //            if let view = touch.view {
            //
            //                NSLog("gestureRecognizer: %@", view)
            //                if (view.isDescendantOfView(self.tableView)) {
            //                    return false
            //                }
            //            }
            
            return true
        }
    }
    
    extension SearchBoxTableViewController : CityRegionContainerControllerDelegate {
        func onCitySelectionDone(regions:[City]) {
            regionSelectionState = regions
            
            if(!regions.isEmpty) {
                locationManagerActive = false
            }
            
            currentCriteria = self.stateToSearhCriteria()
            
            ///GA Tracker
            dispatch_async(GlobalBackgroundQueue) {
                
                if let cities = self.regionSelectionState {
                    for city in cities {
                        for region in city.regions {
                            self.trackEventForCurrentScreen(GAConst.Catrgory.Criteria,
                                action: GAConst.Action.Criteria.Region + String(city.code), label: String(region.code))
                        }
                    }
                }
            }
        }
    }
    
    extension SearchBoxTableViewController : CLLocationManagerDelegate {
        
        private func getDefaultLocation(placemark: CLPlacemark?) -> City {
            
            var currentCity = City(code: 100, name: "台北市", regions: [Region.allRegions])
            
            let regionlist = ConfigLoader.RegionList
            
            if let placemark = placemark {
                let postalCode = placemark.postalCode
                
                for (_, city) in regionlist {
                    
                    if let region = city.regions.filter({ (region) -> Bool in
                        return String(region.code) == postalCode
                    }).first {
                        
                        currentCity = City(code: city.code, name: city.name, regions: [region])
                        break
                    }
                    
                }
                
            }
            
            FileLog.debug("\(currentCity)")
            
            return currentCity
        }
        
        private func setRegionToCriteria(city:City) {
            
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
            
            if (currentCriteria.region == nil ||  currentCriteria.region?.count == 0) {
                currentCriteria.region = [city]
                
                ///Update Region (self.populateViewFromSearchCriteria cause some abnormal behavior for size/city picker)
                regionSelectionState = currentCriteria.region
                
            }
        }
        
        func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            
            FileLog.debug("Location update: \(manager.location?.coordinate)")
            
            CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {(placemarks, error) -> Void in
                if let error = error {
                    FileLog.debug("Reverse geocoder failed error = \(error.localizedDescription)")
                    return
                }
                
                if let placemarks = placemarks where placemarks.count > 0 {
                    if let pm = placemarks.first {
                        
                        FileLog.debug("Location lookup: \(pm.postalCode ?? "-"), \(pm.name ?? "-"), , \(pm.locality ?? "-")")
                        
                        let currentCity = self.getDefaultLocation(pm)
                        self.setRegionToCriteria(currentCity)
                    }
                } else {
                    FileLog.debug("Problem with the data received from geocoder")
                    let currentCity = self.getDefaultLocation(nil)
                    self.setRegionToCriteria(currentCity)
                }
            })
        }
        
        
        func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
            FileLog.debug("Updating location failed error = \(error.localizedDescription)")
            
            let currentCity = self.getDefaultLocation(nil)
            self.setRegionToCriteria(currentCity)
            
        }
    }
