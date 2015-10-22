    //
    //  ZuzuTableViewController.swift
    //  Zuzu
    //
    //  Created by Jung-Shuo Pai on 2015/9/21.
    //  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
    //
    
    import UIKit
    
    
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
    
    class SearchBoxTableViewController: UITableViewController, UISearchBarDelegate,
    UIPickerViewDelegate, UIPickerViewDataSource {
        
        struct ViewTransConst {
            static let showSearchResult:String = "showSearchResult"
            static let showAreaSelector:String = "showAreaSelector"
        }
        
        struct UIControlTag {
            static let NOT_LIMITED_BUTTON_TAG = 99
        }
        
        // Trigger the fetching of total number of items that meet the current criteria
        lazy var stateObserver: SearchCriteriaObserver = SearchCriteriaObserver(viewController: self)
        
        let searchItemService : SearchItemService = SearchItemService.getInstance()
        
        //let searchItemsDataStore : SearchHistoryDataStore = UserDefaultsSearchHistoryDataStore.getInstance()
        
        let cityRegionDataStore: CityRegionDataStore = UserDefaultsCityRegionDataStore.getInstance()
        
        lazy var searchItemTableDataSource: SearchItemTableViewDataSource = SearchItemTableViewDataSource(tableViewController: self)
        
        var regionSelectionState: [City]? {
            didSet {
                
                cityRegionLabel.text = "不限"
                
                if(regionSelectionState != nil) {
                    
                    var labelStr:[String] = [String]()
                    
                    if(regionSelectionState?.count > 0) {
                        
                        var numOfCity = 0
                        for city in regionSelectionState! {
                            
                            if(city.regions.count == 0) {
                                continue
                            }
                            
                            if(labelStr.count < 3) {
                                labelStr.append("\(city.name) (\(city.regions.count))")
                            }
                            numOfCity++
                        }
                        
                        cityRegionLabel.text = labelStr.joinWithSeparator("，") + ((numOfCity > 3) ? " ..." : "")
                    }
                }
                
                stateObserver.onCriteriaChanged(self.toSearhCriteria())
            }
        }
        
        var currentCriteria: SearchCriteria? {
            
            didSet{
                if(currentCriteria != nil) {
                    ///Reset the prefetch house number label
                    self.fastItemCountLabel.text = nil
                    
                    ///Load the criteria to the Search Box UI
                    self.loadFromSearchCriteria(currentCriteria!)
                }
            }
        }
        
        var selectAllButton:ToggleButton?
        
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
                            
                            typeButton.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
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
            
            // Delay the dismissal by 5 seconds
            let delay = 2.0 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue(), {
                alertView.dismissWithClickedButtonIndex(-1, animated: true)
            })
        }
        
        private func pickerRangeToString(pickerView: UIPickerView, pickerFrom:(component:Int, row:Int), pickerTo:(component:Int, row:Int)) -> String{
            
            var pickerStr:String = ""
            
            let fromTuple = self.getItemForPicker(pickerView, component: pickerFrom.component, row: pickerFrom.row)
            let toTuple = self.getItemForPicker(pickerView, component: pickerTo.component, row: pickerTo.row)
            
            if(fromTuple?.label == toTuple?.label) {
                pickerStr = "\((fromTuple?.label)!)"
            } else {
                pickerStr = "\((fromTuple?.label)!) - \((toTuple?.label)!)"
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
            
            let color = UIColor(red: 0x00/255, green: 0x72/255, blue: 0xE3/255, alpha: 1)
            
            searchButton.layer.borderWidth = 2
            searchButton.layer.borderColor = color.CGColor
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
        
        private func configureSearchBoxTable() {
            //tableView.backgroundView = nil
            tableView.backgroundColor = UIColor.whiteColor()
            
            //Remove extra cells when the table height is smaller than the screen
            tableView.tableFooterView = UIView(frame: CGRectZero)
            
            //Configure cell height
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            tableView.delegate = self
        }
        
        private func configureSearchHistoryTable() {
            
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
            case 2: // Price Picker
                picker = pricePicker
                if(hiddenCells.contains(3)) {
                    hiddenCells.remove(3) //Show 3
                    hiddenCells.insert(5) //Hide 5
                } else { //Hide
                    hiddenCells.insert(3)
                }
                
            case 4: // Size Picker
                picker = sizePicker
                if(hiddenCells.contains(5)) {
                    hiddenCells.remove(5) //Show 5
                    hiddenCells.insert(3) //Hide 3
                } else { //Hide
                    hiddenCells.insert(5)
                }
            default: break
            }
            
            if(picker != nil) {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
        
        private func loadFromSearchCriteria(criteria: SearchCriteria) {
            
            ///Keywords
            searchBar.text = criteria.keyword
            
            ///Region
            regionSelectionState = criteria.region
            if(regionSelectionState != nil) {
                cityRegionDataStore.saveSelectedCityRegions(regionSelectionState!)
            } else{
                cityRegionDataStore.saveSelectedCityRegions([City]())
            }
            
            ///Price Range
            var pickerPriceFrom:(component:Int, row:Int) = (0,0)
            var pickerPriceTo:(component:Int, row:Int) = (0,0)
            
            if let priceRange = criteria.price {
                
                for (index, price) in priceItems[0].enumerate() {
                    if(priceRange.0 == price.value) {
                        
                        pickerPriceFrom = (0, index + 1)
                    }
                }
                
                for (index, price) in priceItems[1].enumerate() {
                    if(priceRange.1 == price.value) {
                        
                        pickerPriceTo = (1, index + 1)
                    }
                }
            }
            
            pricePicker.selectRow(pickerPriceFrom.row, inComponent: pickerPriceFrom.component, animated: true)
            pricePicker.selectRow(pickerPriceTo.row, inComponent: pickerPriceTo.component, animated: true)
            
            priceLabel.text =
                pickerRangeToString(pricePicker, pickerFrom: pickerPriceFrom, pickerTo: pickerPriceTo)
            
            
            ///Size Range
            var pickerSizeFrom:(component:Int, row:Int) = (0,0)
            var pickerSizeTo:(component:Int, row:Int) = (0,0)
            
            if let sizeRange = criteria.size {
                
                for (index, size) in sizeItems[0].enumerate() {
                    if(sizeRange.0 == size.value) {
                        pickerSizeFrom = (0, index + 1)
                    }
                }
                
                for (index, size) in sizeItems[1].enumerate() {
                    if(sizeRange.1 == size.value) {
                        pickerSizeTo = (1, index + 1)
                    }
                }
            }
            
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
                selectAllButton?.setToggleState(false)
                
            } else {
                selectAllButton?.setToggleState(true)
            }
            
        }
        
        private func toSearhCriteria() -> SearchCriteria {
            
            let searchCriteria = SearchCriteria()
            
            ///Keywords
            searchCriteria.keyword = searchBar.text
            
            ///Region
            searchCriteria.region = regionSelectionState
            
            ///Price Range
            let priceMinRow =
            pricePicker.selectedRowInComponent(PickerConst.lowerComponentIndex)
            let priceMaxRow =
            pricePicker.selectedRowInComponent(PickerConst.upperComponentIndex)
            
            if let priceMin = self.getItemForPicker(pricePicker, component: PickerConst.lowerComponentIndex, row: priceMinRow) {
                if let priceMax = self.getItemForPicker(pricePicker, component: PickerConst.upperComponentIndex, row: priceMaxRow){
                    if(priceMin.value != CriteriaConst.Bound.LOWER_ANY || priceMax.value != CriteriaConst.Bound.UPPER_ANY) {
                        searchCriteria.price = (priceMin.value, priceMax.value)
                    }
                }
            }
            
            ///Size Range
            let sizeMinRow =
            sizePicker.selectedRowInComponent(sizeItems.startIndex)
            let sizeMaxRow =
            sizePicker.selectedRowInComponent(sizeItems.endIndex - 1)
            
            
            if let sizeMin = self.getItemForPicker(sizePicker, component: PickerConst.lowerComponentIndex, row: sizeMinRow) {
                if let sizeMax = self.getItemForPicker(sizePicker, component: PickerConst.upperComponentIndex, row: sizeMaxRow){
                    if(sizeMin.value != CriteriaConst.Bound.LOWER_ANY || sizeMax.value != CriteriaConst.Bound.UPPER_ANY) {
                        searchCriteria.size = (sizeMin.value, sizeMax.value)
                    }
                }
            }
            
            ///House Types
            var typeList = [Int]()
            
            if(selectAllButton!.getToggleState() == false) {
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
        @IBAction func onSegmentClicked(sender: UISegmentedControl) {
            
            loadSearchItemsForSegment(sender.selectedSegmentIndex)
            
            //Scroll to the bottom of the table to see the search item table fully
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 7, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        
        func onButtonClicked(sender: UIButton) {
            if let toogleButton = sender as? ToggleButton {
                toogleButton.toggleButtonState()
                
                //toggle off the select all button if any type is selected
                if(toogleButton.tag != UIControlTag.NOT_LIMITED_BUTTON_TAG
                    && toogleButton.getToggleState()==true) {
                        selectAllButton?.setToggleState(false)
                }
                
                stateObserver.onCriteriaChanged(self.toSearhCriteria())
            }
        }
        
        func onSearchButtonClicked(sender: UIButton) {
            NSLog("onSearchButtonClicked: %@", self)
            
            //Hide size & price pickers
            hiddenCells.insert(3)
            hiddenCells.insert(5)
            tableView.beginUpdates()
            tableView.endUpdates()
            
            //Validate field
            if(self.regionSelectionState == nil || self.regionSelectionState?.count <= 0) {
                alertInvalidRegionSelection()
                return
            }
            
            //present the view modally (hide the tabbar)
            performSegueWithIdentifier(ViewTransConst.showSearchResult, sender: nil)
        }
        
        func dismissCurrentView(sender: UIBarButtonItem) {
            navigationController?.popToRootViewControllerAnimated(true)
        }
        
        // MARK: - UISearchBarDelegate
        
        func searchBarSearchButtonClicked(searchBar: UISearchBar) {
            NSLog("searchBarSearchButtonClicked: %@", self)
            searchBar.endEditing(true)
        }
        
        // MARK: - Picker Data Source
        struct PickerConst {
            static let anyLower:(label:String, value:Int) = ("不限",CriteriaConst.Bound.LOWER_ANY)
            static let anyUpper:(label:String, value:Int) = ("不限",CriteriaConst.Bound.UPPER_ANY)
            static let upperBoundStartZero = 0
            
            static let lowerComponentIndex = 0
            static let upperComponentIndex = 1
        }
        
        var sizeUpperRange:Range<Int>?
        var priceUpperRange:Range<Int>?
        
        //Consider removing lable. We can genererate any kind of String when needed...
        let sizeItems:[[(label:String, value:Int)]] =
        [
            [("10",10), ("20",20), ("30",30), ("40",40), ("50",50)]
            ,
            [("10",10), ("20",20), ("30",30), ("40",40), ("50",50)]
        ]
        
        let priceItems:[[(label:String, value:Int)]] =
        [
            [("5000",5000), ("10000",10000), ("15000",15000), ("20000",20000), ("25000",25000), ("30000",30000), ("35000",35000), ("40000",40000)]
            ,
            [("5000",5000), ("10000",10000), ("15000",15000), ("20000",20000), ("25000",25000), ("30000",30000), ("35000",35000), ("40000",40000)]
        ]
        
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
                
                return numOfItemsWithAnyValue - targetUpperRange!.startIndex
            }
            
            return numOfItemsWithAnyValue
        }
        
        private func getUpperBoundRangeForPicker(pickerView: UIPickerView, items: [[(label:String, value:Int)]]) -> Range<Int>?{
            
            let numOfComponents = pickerView.numberOfComponents
            
            assert(numOfComponents == 2, "Cannot process pickers with components more or less than two")
            assert(numOfComponents == items.count, "The number of components do not match")
            
            if(numOfComponents == 2) {
                let from = items.startIndex, to = items.endIndex - 1
                
                let selectedRowInlowerBound = pickerView.selectedRowInComponent(from)
                
                if let selectedLowerBound = getItemForPicker(pickerView, component: from, row: selectedRowInlowerBound) {
                    
                    ///Do not need to update Upper Bound values if there is not limit on Lower Bound
                    if(selectedLowerBound.value == PickerConst.anyLower.value) {
                        return (PickerConst.upperBoundStartZero...items[to].count - 1)
                    }
                    
                    var hasLargerValue:Bool = false
                    
                    for (index, item) in items[to].enumerate() {
                        if(item.value > selectedLowerBound.value) {
                            hasLargerValue = true
                            return (index...items[to].count - 1)
                        }
                    }
                    
                    if(!hasLargerValue) {
                        return nil
                    }
                    
                }
            }
            
            return nil
        }
        
        ///Consider encapsulating items with any value in a class...
        private func getItemForPicker(pickerView: UIPickerView, component: Int, row: Int) ->  (label:String, value:Int)? {
            
            ///1st row is always "any value"
            if(row == 0){
                if(component == PickerConst.lowerComponentIndex) {
                    return PickerConst.anyLower
                }
                if(component == PickerConst.upperComponentIndex) {
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
            default:
                assert(false,"Invalid picker view")
                return nil
            }
            
            let idxWithoutAnyValue = row - 1
            
            ///Upper values are limited to valus greater than the selected lower value
            if(component == 1) {
                if (targetUpperRange == nil) {
                    assert(false,"There should be no item except for any value")
                    return nil
                }
                return targetItems[component][idxWithoutAnyValue + targetUpperRange!.startIndex]
            }
            
            return targetItems[component][idxWithoutAnyValue]
        }
        
        func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            
            var targetItems:[[(label:String, value:Int)]]
            var targetLabel:UILabel
            
            switch(pickerView) {
            case sizePicker:
                targetItems = sizeItems
                targetLabel = sizeLabel
            case pricePicker:
                targetItems = priceItems
                targetLabel = priceLabel
            default:
                return
            }
            
            var pickerFrom:(component:Int, row:Int) = (0,0)
            var pickerTo:(component:Int, row:Int) = (0,0)
            
            if(component == PickerConst.lowerComponentIndex) {
                let fromItemIdx = row
                let toItemIdx = pickerView.selectedRowInComponent(targetItems.endIndex - 1)
                
                pickerFrom = (component, fromItemIdx)
                pickerTo = ((targetItems.endIndex - 1), toItemIdx)
                
            }else if(component == PickerConst.upperComponentIndex) {
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
                targetLabel.text = "\((fromTuple?.label)!) - \((toTuple?.label)!)"
            }
            
            targetLabel.text = pickerRangeToString(pickerView, pickerFrom: pickerFrom, pickerTo: pickerTo)
            
            ///Try to refresh picker items
            switch(pickerView) {
            case sizePicker:
                sizeUpperRange = getUpperBoundRangeForPicker(pickerView, items: targetItems)
            case pricePicker:
                priceUpperRange = getUpperBoundRangeForPicker(pickerView, items: targetItems)
            default:
                return
            }
            
            pickerView.reloadAllComponents()
            
            
            stateObserver.onCriteriaChanged(self.toSearhCriteria())
        }
        
        // MARK: - Table Delegate
        
        override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
            switch(indexPath.row) {
            case 2, 4: // Price, Size Picker
                handlePicker(indexPath)
                
            case 0: //Area Picker
                NSLog("isMainThread : \(NSThread.currentThread().isMainThread)")
                dispatch_async(dispatch_get_main_queue(),{
                    NSLog("isMainThread : \(NSThread.currentThread().isMainThread)")
                    self.performSegueWithIdentifier(ViewTransConst.showAreaSelector, sender: nil)
                })
                
                
            default: break
            }
            
        }
        
        var hiddenCells:Set<Int> = [3, 5]
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            
            NSLog("heightForRowAtIndexPath\(indexPath)")
            
            if(hiddenCells.contains(indexPath.row)) {
                return 0
            } else {
                if (indexPath.row == 3) {
                    return pricePicker.intrinsicContentSize().height
                }
                if (indexPath.row == 5) {
                    return sizePicker.intrinsicContentSize().height
                }
                //                if (indexPath.row == 7) {
                //                    self.searchItemTable.layoutIfNeeded()
                //                    let height = self.searchItemTable.contentSize.height
                //                    return height
                //                }
                
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
            
            NSLog("viewDidLoad: %@", self)
            self.configureButton()
            
            self.configureSearchHistoryTable()
            
            self.configureSearchBoxTable()
            
            //searchItemsDataStore.clearSearchItems()
            //cityRegionDataStore.clearSelectedCityRegions()
            
            //Confugure Price Picker
            sizeUpperRange = (PickerConst.upperBoundStartZero...self.sizeItems.count - 1)
            priceUpperRange = (PickerConst.upperBoundStartZero...self.priceItems.count - 1)
            
            self.configurePricePicker()
        }
        
        override func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            
            //Load selected areas
            regionSelectionState = cityRegionDataStore.loadSelectedCityRegions()
            
            print(regionSelectionState)
            
            //Load search item segment data
            loadSearchItemsForSegment(searchItemSegment.selectedSegmentIndex)
            
            //Scroll search item data to the top of the table
            if(searchItemTable.numberOfRowsInSection(0) > 0) {
                self.searchItemTable.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            }
        }
        override func viewDidAppear(animated: Bool) {
            super.viewDidAppear(animated)
            NSLog("viewDidAppear: %@", self)
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
                    if let srtvc = segue.destinationViewController as? SearchResultTableViewController {
                        
                        ///Collect the search criteria set by the user
                        let criteria = toSearhCriteria()
                        
                        srtvc.searchCriteria = criteria
                        
                        ///Save search history (works like a ring buffer, delete the oldest record if maxItemSize is exceeded)
                        
                        if let historicalItems =  searchItemService.getSearchItemsByType(.HistoricalSearch) {
                            
                            if(historicalItems.count >= SearchItemService.maxItemSize) {
                                let deleteIndex = historicalItems.endIndex - 1
                                searchItemService.deleteSearchItem(deleteIndex, itemType: .HistoricalSearch)
                            }
                            
                            do{
                                try searchItemService.addNewSearchItem(SearchItem(criteria: criteria, type: .HistoricalSearch))
                            } catch {
                                NSLog("Fail to save search history")
                            }
                        }
                    }
                case ViewTransConst.showAreaSelector:
                    NSLog("showAreaSlector")
                    
                    ///Setup delegat to receive result
                    //                    if let vc = segue.destinationViewController as? CityRegionContainerViewController {
                    //                        vc.delegate = self
                    //                    }
                    
                    ///So that we'll not see the pickerView expand when loading the area selector view
                    self.tabBarController!.tabBar.hidden = true;
                    
                    navigationItem.backBarButtonItem = UIBarButtonItem(title: "取消", style: UIBarButtonItemStyle.Plain, target: self, action: "dismissCurrentView:")
                    
                default: break
                }
            }
        }
        
    }
