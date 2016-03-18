//
//  SearchBoxTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON
import SCLAlertView
import AwesomeCache

private let ActionLabel = "RadarUIAction"
private let FileLog = Logger.fileLogger
private let Log = Logger.defaultLogger


protocol RadarConfigureTableViewControllerDelegate: class {
    func onCriteriaChanged(searchCriteria:SearchCriteria)
}

class RadarConfigureTableViewController: UITableViewController {
    
    struct UIControlTag {
        static let NOT_LIMITED_BUTTON_TAG = 99
    }
    
    struct CellConst {
        static let area = 0
        static let houseType = 1
        static let priceLabel = 2
        static let pricePicker = 3
        static let sizeLabel = 4
        static let sizePicker = 5
        static let moreFilters = 6
    }
    
    // Price & Size Picker Vars
    struct PickerConst {
        static let anyLower:(label:String, value:Int) = ("0",CriteriaConst.Bound.LOWER_ANY)
        static let anyUpper:(label:String, value:Int) = ("不限",CriteriaConst.Bound.UPPER_ANY)
        static let upperBoundStartZero = 0
        
        static let lowerCompIdx = 0
        static let upperCompIdx = 1
    }
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    private var regionSelectionState: [City]? {
        didSet {
            updateRegionLabel(regionSelectionState)
        }
    }
    
    private var filterSelectionState: [FilterGroup]? {
        didSet {
            updateFilterLabel(filterSelectionState)
        }
    }
    
    private var sizeUpperRange:Range<Int>?
    private var priceUpperRange:Range<Int>?
    
    private let sizeItems:[[(label:String, value:Int)]] = RadarConfigureTableViewController.loadPickerData("searchCriteriaOptions", criteriaLabel: "sizeRange")
    private let priceItems:[[(label:String, value:Int)]] = RadarConfigureTableViewController.loadPickerData("searchCriteriaOptions", criteriaLabel: "priceRange")
    
    private var selectAllButton:ToggleButton!
    
    private let downArrowImage = UIImage(named: "arrow_down_n")!.imageWithRenderingMode(.AlwaysTemplate)
    private let upArrowImage = UIImage(named: "arrow_up_n")!.imageWithRenderingMode(.AlwaysTemplate)
    private let filterImage = UIImage(named: "filter_n")!.imageWithRenderingMode(.AlwaysTemplate)
    
    var delegate: RadarConfigureTableViewControllerDelegate?

    /// The current criteria set by the user on the UI
    internal var currentCriteria: SearchCriteria = SearchCriteria() {
        
        didSet{
            
            ///Load the criteria to the Search Box UI
            self.populateViewFromSearchCriteria(currentCriteria)
            
            ///Send Info to Criteria Summary View
            self.delegate?.onCriteriaChanged(currentCriteria)
        }
    }
    
    @IBOutlet weak var priceArrow: UIImageView! {
        didSet {
            priceArrow.image = downArrowImage
            priceArrow.tintColor = UIColor.colorWithRGB(0xBABABA)
        }
    }
    
    @IBOutlet weak var sizeArrow: UIImageView! {
        didSet {
            sizeArrow.image = downArrowImage
            sizeArrow.tintColor = UIColor.colorWithRGB(0xBABABA)
        }
    }
    
    @IBOutlet weak var filtersImage: UIImageView!{
        didSet {
            self.filtersImage.image = filterImage
            self.filtersImage.tintColor = UIColor.blackColor()
            //self.filtersImage.tintColor = UIColor.colorWithRGB(0x808080, alpha: 1)
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
    
    @IBOutlet weak var cityRegionLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var sizePicker: UIPickerView!
    @IBOutlet weak var pricePicker: UIPickerView!
    @IBOutlet weak var filterLabel: UILabel!
    
    // MARK: - Private Utils

    private func updateRegionLabel(regionSelection: [City]?) {
        
        var regionLabel = "不限"
        
        if let regionSelection = regionSelection {
            /// We can display more info when only one city is selected
            if(regionSelection.count == 1) {
                
                var labelStr:String?
                
                if let city = regionSelection.first {
                    
                    if(city.regions.count == 1) {
                        if let regionName = city.regions.first?.name {
                            labelStr = ("\(city.name) (\(regionName))")
                        } else {
                            labelStr = ("\(city.name) (\(city.regions.count))")
                        }
                    } else {
                        labelStr = ("\(city.name) (\(city.regions.count))")
                    }
                }
                
                if let labelStr = labelStr {
                    regionLabel = labelStr
                }
                
            } else if(regionSelection.count > 1) {
                
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
                
            }
        }
        
        cityRegionLabel.text = regionLabel
        
    }
    
    private func updateFilterLabel(filterSelectionState: [FilterGroup]?) {
        
        var filterLabel = "不限"
        
        if let filterSelectionState = filterSelectionState {
            
            if(filterSelectionState.count > 0) {
                filterLabel = "\(filterSelectionState.count)個"
            }
            
        }
        
        self.filterLabel.text = filterLabel
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
        tableView.delegate = self
    }
    
    private func handlePicker(indexPath:NSIndexPath) {
        var picker:UIPickerView?
        var isHidePicker = false
        switch(indexPath.row) {
        case CellConst.priceLabel: // Price Picker
            picker = pricePicker
            if(hiddenCells.contains(CellConst.pricePicker)) {
                /// Hide Size Picker, Display Price Picker
                sizeArrow.image = downArrowImage
                hiddenCells.insert(CellConst.sizePicker)
                
                priceArrow.image = upArrowImage
                hiddenCells.remove(CellConst.pricePicker)
            } else {
                /// Hide Price Picker
                priceArrow.image = downArrowImage
                hiddenCells.insert(CellConst.pricePicker)
                isHidePicker = true
            }
            
        case CellConst.sizeLabel: // Size Picker
            picker = sizePicker
            if(hiddenCells.contains(CellConst.sizePicker)) {
                /// Hide Price Picker, Display Size Picker
                priceArrow.image = downArrowImage
                hiddenCells.insert(CellConst.pricePicker)
                
                sizeArrow.image = upArrowImage
                hiddenCells.remove(CellConst.sizePicker)
            } else {
                /// Hide Size Picker
                sizeArrow.image = downArrowImage
                hiddenCells.insert(CellConst.sizePicker)
                isHidePicker = true
            }
        default: break
        }
        
        if(picker != nil) {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
            
            tableView.beginUpdates()
            tableView.endUpdates()
            if isHidePicker == false{
                if indexPath.row == CellConst.priceLabel{
                    let lasIndexPath = NSIndexPath(forRow: indexPath.row-1, inSection: indexPath.section)
                    let lastRect = tableView.rectForRowAtIndexPath(lasIndexPath)
                    let x = lastRect.origin.x
                    let y = lastRect.size.height*0.5 + lastRect.origin.y
                    self.tableView.setContentOffset(CGPoint(x:x,y:y), animated: true)
                }else if indexPath.row == CellConst.sizeLabel{
                    let lasIndexPath = NSIndexPath(forRow: indexPath.row-2, inSection: indexPath.section)
                    let lastRect = tableView.rectForRowAtIndexPath(lasIndexPath)
                    self.tableView.setContentOffset(lastRect.origin, animated: true)
                }
            }
        }
    }
    
    private func populateViewFromSearchCriteria(criteria: SearchCriteria) {
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
        
        /// Filters
        self.filterSelectionState = criteria.filterGroups
    }
    
    private func stateToSearhCriteria() -> SearchCriteria {
        
        let searchCriteria = SearchCriteria()
        
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
        
        searchCriteria.filterGroups = self.filterSelectionState
        
        return searchCriteria
    }
    
    // MARK: - UI Control Actions
    func onTypeButtonTouched(sender: UIButton) {
        Log.info("Sender: \(sender)", label: ActionLabel)
        
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
    
    // MARK: - Table Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch(indexPath.row) {
        case CellConst.sizeLabel, CellConst.priceLabel: // Price, Size Picker
            handlePicker(indexPath)
            
        case CellConst.area: //Area Picker
            ///With modal transition, this segue may be very slow without explicitly send it to the main ui queue
            let storyboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
            let cityRegionVC = storyboard.instantiateViewControllerWithIdentifier("CityRegionContainer") as! CityRegionContainerController
            cityRegionVC.delegate = self
            if let regionSelectionState = currentCriteria.region {
                cityRegionVC.regionSelectionState = regionSelectionState
            }
            self.parentViewController?.navigationItem.backBarButtonItem?.title = "取消"
            self.showViewController(cityRegionVC, sender: self)
            
        case CellConst.moreFilters: //More Filters
            let storyboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
            let ftvc = storyboard.instantiateViewControllerWithIdentifier("FilterTableView") as! FilterTableViewController
            
            
            if let filterGroups = self.currentCriteria.filterGroups {
                ftvc.selectedFilterIdSet = convertFilterGroupToIdentifier(filterGroups)
            }
            
            ftvc.filterDelegate = self
            self.parentViewController?.navigationItem.backBarButtonItem?.title = "完成"
            self.showViewController(ftvc, sender: self)
            
        default: break
        }
        
    }
    
    var hiddenCells:Set<Int> = [CellConst.pricePicker, CellConst.sizePicker]
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        Log.debug("IndexPath = \(indexPath)")
        
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
        Log.enter()
        
        self.configureSearchBoxTable()
        
        //Confugure Price Picker
        sizeUpperRange = (PickerConst.upperBoundStartZero...self.sizeItems[1].count - 1)
        priceUpperRange = (PickerConst.upperBoundStartZero...self.priceItems[1].count - 1)
        
        self.configurePricePicker()
        
        Log.exit()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()
        
        //Restore hidden tab bar before apeearing
        self.tabBarController?.tabBarHidden = false
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.enter()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        Log.enter()
    }
}


extension RadarConfigureTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Private Utils
    
    private static func loadPickerData(resourceName: String, criteriaLabel: String) ->  [[(label:String, value:Int)]]{
        
        var resultItems = Array(count: 2, repeatedValue: [(label: String, value: Int)]() )
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            ///Load all picker data from json
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[criteriaLabel].arrayValue
                
                Log.debug("JSON Config: \(criteriaLabel) = \(items.count)")
                
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
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        
        var valueText: String = ""
        
        if let rowItem = self.getItemForPicker(pickerView, component: component, row: row) {
            
            if(pickerView == pricePicker && component == 1) {
                Log.debug("Upper Price: com = \(component), row = \(row), label = \(rowItem.label)")
            }
            
            valueText = rowItem.label
        }
        
        let pickerLabel = (view as? UILabel) ?? UILabel()
        
        pickerLabel.text = valueText
        pickerLabel.font = UIFont.systemFontOfSize(18)
        pickerLabel.autoScaleFontSize = true
        pickerLabel.textAlignment = NSTextAlignment.Center
        
        return pickerLabel
    }
}


// MARK: - CityRegionContainerControllerDelegate
extension RadarConfigureTableViewController : CityRegionContainerControllerDelegate {
    func onCitySelectionDone(regions:[City]) {
        
        regionSelectionState = regions
        
        currentCriteria = self.stateToSearhCriteria()
        
        ///GA Tracker
        dispatch_async(GlobalQueue.Background) {
            
            if let cities = self.regionSelectionState {
                for city in cities {
                    for region in city.regions {
                        self.trackEventForCurrentScreen(GAConst.Catrgory.SearchHouse,
                            action: GAConst.Action.SearchHouse.Region + String(city.code), label: String(region.code))
                    }
                }
            }
        }
    }
}

// MARK: - FilterTableViewControllerDelegate
extension RadarConfigureTableViewController: FilterTableViewControllerDelegate {
    
    func onFiltersReset() {
        self.filterSelectionState = nil
        
        /// Update currentCriteria
        self.currentCriteria = self.stateToSearhCriteria()
    }
    
    func onFiltersSelected(selectedFilterIdSet: [String : Set<FilterIdentifier>]) {
        //Do nothing
    }
    
    func onFiltersSelectionDone(selectedFilterIdSet: [String : Set<FilterIdentifier>]) {
        self.filterSelectionState = convertIdentifierToFilterGroup(selectedFilterIdSet)
        
        /// Update currentCriteria
        self.currentCriteria = self.stateToSearhCriteria()
    }
}
