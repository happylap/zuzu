    //
    //  ZuzuTableViewController.swift
    //  Zuzu
    //
    //  Created by Jung-Shuo Pai on 2015/9/21.
    //  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
    //
    
    import UIKit
    import SwiftyJSON
    
    
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
        
        // Price & Size Picker Vars
        struct PickerConst {
            static let anyLower:(label:String, value:Int) = ("0",CriteriaConst.Bound.LOWER_ANY)
            static let anyUpper:(label:String, value:Int) = ("不限",CriteriaConst.Bound.UPPER_ANY)
            static let upperBoundStartZero = 0
            
            static let lowerComponentIndex = 0
            static let upperComponentIndex = 1
        }
        
        var regionSelectionState: [City]? {
            didSet {
                if (regionSelectionState != nil) {
                    updateRegionLabel(regionSelectionState!)
                }
            }
        }
        
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
        
        private func updateRegionLabel(regionSelection: [City]) {
            
            var regionLabel = "不限"
            
            var labelStr:[String] = [String]()
            
            if(regionSelection.count > 0) {
                
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
            
            cityRegionLabel.text = regionLabel
            
        }
        
        var currentCriteria: SearchCriteria =  SearchCriteria() {
            
            didSet{
                
                if !(oldValue == currentCriteria) {
                    filterDataStore.clearFilterSetting()
                    
                    stateObserver.onCriteriaChanged(currentCriteria)
                    
                    ///Reset the prefetch house number label
                    self.fastItemCountLabel.text = nil
                    
                    criteriaDataStore.saveSearchCriteria(currentCriteria)
                    
                    ///Load the criteria to the Search Box UI
                    self.populateViewFromSearchCriteria(currentCriteria)
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
            
            // Delay the dismissal
            self.runOnMainThreadAfter(2.0) {
                alertView.dismissWithClickedButtonIndex(-1, animated: true)
            }
        }
        
        private func pickerRangeToString(pickerView: UIPickerView, pickerFrom:(component:Int, row:Int), pickerTo:(component:Int, row:Int)) -> String{
            
            var pickerStr:String = ""
            
            let fromTuple = self.getItemForPicker(pickerView, component: pickerFrom.component, row: pickerFrom.row)
            let toTuple = self.getItemForPicker(pickerView, component: pickerTo.component, row: pickerTo.row)
            
            if(fromTuple?.value == toTuple?.value) {
                pickerStr = "\((toTuple?.label)!)"
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
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
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
            case 2: // Price Picker
                picker = pricePicker
                if(hiddenCells.contains(3)) {
                    hiddenCells.insert(5) //Hide 5
                    hiddenCells.remove(3) //Show 3
                    
                    priceUpperRange = getUpperBoundRangeForPicker(picker!, items: priceItems)
                    picker?.reloadComponent(PickerConst.upperComponentIndex)
                } else { //Hide
                    hiddenCells.insert(3)
                }
                
            case 4: // Size Picker
                picker = sizePicker
                if(hiddenCells.contains(5)) {
                    hiddenCells.insert(3) //Hide 3
                    hiddenCells.remove(5) //Show 5
                    
                    sizeUpperRange = getUpperBoundRangeForPicker(picker!, items: sizeItems)
                    picker?.reloadComponent(PickerConst.upperComponentIndex)
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
        
        private func populateViewFromSearchCriteria(criteria: SearchCriteria) {
            
            ///Keywords
            searchBar.text = criteria.keyword
            
            ///Region
            regionSelectionState = criteria.region
            
            ///Price Range
            var pickerPriceFrom:(component:Int, row:Int) = (0,0)
            var pickerPriceTo:(component:Int, row:Int) = (1,0)
            
            if let priceRange = criteria.price {
                
                for (index, price) in priceItems[PickerConst.lowerComponentIndex].enumerate() {
                    if(priceRange.0 == price.value) {
                        
                        pickerPriceFrom = (PickerConst.lowerComponentIndex, index + 1)
                    }
                }
                
                for (index, price) in priceItems[PickerConst.upperComponentIndex].enumerate() {
                    if(priceRange.1 == price.value) {
                        
                        pickerPriceTo = (PickerConst.upperComponentIndex, index + 1)
                    }
                }
            }
            
            pricePicker.selectRow(pickerPriceFrom.row, inComponent: pickerPriceFrom.component, animated: true)
            pricePicker.selectRow(pickerPriceTo.row, inComponent: pickerPriceTo.component, animated: true)
            
            //Init Price Picker Upper Bound display range
            priceUpperRange = (PickerConst.upperBoundStartZero...self.priceItems.count - 1)
            
            priceLabel.text =
                pickerRangeToString(pricePicker, pickerFrom: pickerPriceFrom, pickerTo: pickerPriceTo)
            
            
            ///Size Range
            var pickerSizeFrom:(component:Int, row:Int) = (0,0)
            var pickerSizeTo:(component:Int, row:Int) = (1,0)
            
            if let sizeRange = criteria.size {
                
                for (index, size) in sizeItems[PickerConst.lowerComponentIndex].enumerate() {
                    if(sizeRange.0 == size.value) {
                        pickerSizeFrom = (PickerConst.lowerComponentIndex, index + 1)
                    }
                }
                
                for (index, size) in sizeItems[PickerConst.upperComponentIndex].enumerate() {
                    if(sizeRange.1 == size.value) {
                        pickerSizeTo = (PickerConst.upperComponentIndex, index + 1)
                    }
                }
            }
            
            sizePicker.selectRow(pickerSizeFrom.row, inComponent: pickerSizeFrom.component, animated: true)
            sizePicker.selectRow(pickerSizeTo.row, inComponent: pickerSizeTo.component, animated: true)
            
            //Init Price Picker Upper Bound display range
            sizeUpperRange = (PickerConst.upperBoundStartZero...self.sizeItems.count - 1)
            
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
        
        private func stateToSearhCriteria() -> SearchCriteria {
            
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
            sizePicker.selectedRowInComponent(PickerConst.lowerComponentIndex)
            let sizeMaxRow =
            sizePicker.selectedRowInComponent(PickerConst.upperComponentIndex)
            
            
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
                
                currentCriteria = self.stateToSearhCriteria()
            }
        }
        
        func onSearchButtonClicked(sender: UIButton) {
            NSLog("onSearchButtonClicked: %@", self)
            
            //Hide size & price pickers
            self.setRowVisible(3, visible: false)
            self.setRowVisible(5, visible: false)
            
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
            case 2, 4: // Price, Size Picker
                handlePicker(indexPath)
                
            case 0: //Area Picker
                ///With modal transition, this segue may be very slow without explicitly send it to the main ui queue
                self.performSegueWithIdentifier(ViewTransConst.showAreaSelector, sender: nil)
                
                
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
            
            //Configure Guesture
            self.configureGestureRecognizer()
            
            //Load Search Criteria
            if let criteria = criteriaDataStore.loadSearchCriteria() {
                
                currentCriteria.keyword = criteria.keyword
                currentCriteria.region = criteria.region
                currentCriteria.price  = criteria.price
                currentCriteria.size = criteria.size
                currentCriteria.types = criteria.types
                
                self.populateViewFromSearchCriteria(currentCriteria)
            }
            
        }
        
        func handleTap(sender:UITapGestureRecognizer) {
            NSLog("handleTap")
            searchBar.resignFirstResponder()
        }
        
        override func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
            
            //Load search item segment data
            loadSearchItemsForSegment(searchItemSegment.selectedSegmentIndex)
            
            //Scroll search item data to the top of the table
            if(searchItemTable.numberOfRowsInSection(0) > 0) {
                self.searchItemTable.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            }
            
            //Restore hidden tab bar before apeearing
            self.tabBarController!.tabBar.hidden = false;
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
                        
                        self.tabBarController!.tabBar.hidden = true
                        
                        navigationItem.backBarButtonItem = UIBarButtonItem(title: "重新搜尋", style: UIBarButtonItemStyle.Plain, target: self, action: "dismissCurrentView:")
                        
                        ///Collect the search criteria set by the user
                        srtvc.searchCriteria = currentCriteria
                        
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
                    
                    ///So that we'll not see the pickerView expand when loading the area selector view
                    self.tabBarController!.tabBar.hidden = true;
                    
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
                    
                    NSLog("\(criteriaLabel) = %d", items.count)
                    
                    for itemJsonObj in items {
                        let label = itemJsonObj["label"].stringValue
                        let value = itemJsonObj["value"].intValue
                        
                        resultItems[0].append( (label: label, value: value) )
                        resultItems[1].append( (label: label, value: value) )
                    }
                    
                } catch let error as NSError{
                    
                    NSLog("Cannot load area json file %@", error)
                    
                }
            }
            
            return resultItems
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
            if(component == PickerConst.lowerComponentIndex) {
                
                switch(pickerView) {
                case sizePicker:
                    sizeUpperRange = getUpperBoundRangeForPicker(pickerView, items: targetItems)
                    
                case pricePicker:
                    priceUpperRange = getUpperBoundRangeForPicker(pickerView, items: targetItems)
                    
                default:
                    return
                }
                
                //Reload for new index
                pickerView.reloadComponent(PickerConst.upperComponentIndex)
                
                //Select the first item if the original selected item is not in range (Just a temp & consistent solution)
                pickerView.selectRow(targetItems.startIndex, inComponent: PickerConst.upperComponentIndex, animated: false)
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
        func searchBarSearchButtonClicked(searchBar: UISearchBar) {
            NSLog("searchBarSearchButtonClicked: %@", self)
            searchBar.resignFirstResponder()//.endEditing(true)
        }
        
        func searchBarTextDidEndEditing(searchBar: UISearchBar) {
            NSLog("searchBarTextDidEndEditing: %@", self)
            searchBar.resignFirstResponder()
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
            
            currentCriteria = self.stateToSearhCriteria()
        }
    }
