//
//  SearchResultViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/27.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView
import GoogleMobileAds

private let Log = Logger.defaultLogger

class SearchResultViewController: UIViewController {
    
    struct CellIdentifier {
        static let houseItem = "houseItemCell"
        static let adItem = "standardAdCell"
    }
    
    struct TableConst {
        static let sectionNum:Int = 1
    }
    
    struct ViewTransConst {
        static let showDebugInfo:String = "showDebugInfo"
        static let showAdvancedFilter:String = "showAdvancedFilter"
        static let displayHouseDetail:String = "displayHouseDetail"
        static let displayDuplicateHouse:String = "displayDuplicateHouse"
    }
    
    enum ScrollDirection {
        case ScrollDirectionNone
        case ScrollDirectionRight
        case ScrollDirectionLeft
        case ScrollDirectionUp
        case ScrollDirectionDown
        case ScrollDirectionCrazy
    }
    
    private let filterSettingOnImage = UIImage(named: "filter_on_n")
    
    private let filterSettingNormalImage = UIImage(named: "filter_n")
    
    // MARK: - Member Fields
    
    @IBOutlet weak var filterSettingButton: UIButton!
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView! {
        didSet{
            stopSpinner()
        }
    }
    
    @IBOutlet weak var debugBarButton: UIBarButtonItem! {
        didSet {
            #if DEBUG
                debugBarButton.enabled = true
            #else
                debugBarButton.enabled = false
            #endif
            
        }
    }
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    
    @IBOutlet weak var sortBySizeButton: UIButton!
    
    @IBOutlet weak var sortByPostTimeButton: UIButton!
    
    
    @IBOutlet weak var tableView: UITableView!
    
    var smartFilterContainerView: SmartFilterContainerView?
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    var debugTextStr: String = ""
    
    private let searchItemService : SearchItemService = SearchItemService.getInstance()
    private let dataSource: HouseItemTableDataSource = HouseItemTableDataSource()
    private var lastContentOffset:CGFloat = 0
    private var lastDirection: ScrollDirection = ScrollDirection.ScrollDirectionNone
    private var ignoreScroll = false
    
    private var sortingStatus: [String:String] = [String:String]() //Field Name, Sorting Type
    private var selectedFilterIdSet = [String : Set<FilterIdentifier>]()
    
    private var duplicateHouseItem: HouseItem?
    
    var searchCriteria: SearchCriteria?
    
    var collectionIdList:[String]?
    
    // MARK: - Private Utils
    
    //Update Advanced Filtet Icon Status
    private func updateFilterSettingButtonStatus() {
        Log.enter()
        if let filters = self.searchCriteria?.filters {
            Log.debug("\(filters)")
            if(filters.count > 0) {
                self.filterSettingButton.setImage(self.filterSettingOnImage, forState: UIControlState.Normal)
            } else {
                self.filterSettingButton.setImage(self.filterSettingNormalImage, forState: UIControlState.Normal)
            }
        } else {
            self.filterSettingButton.setImage(self.filterSettingNormalImage, forState: UIControlState.Normal)
        }
        
    }
    
    private func setSubviewsVisible(visible: Bool) {
        let subviews = self.view.subviews
        
        for view in subviews{
            view.hidden = !visible
        }
    }
    
    private func configureTableView() {
        
        tableView.estimatedRowHeight = BaseLayoutConst.houseImageHeight * getCurrentScale()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: CellIdentifier.houseItem)
        self.tableView.registerNib(UINib(nibName: "SearchResultAdCell", bundle: nil), forCellReuseIdentifier: CellIdentifier.adItem)
    }
    
    override func viewDidLayoutSubviews() {
        
        
        
    }
    
    private func configureFilterButtons() {
        
        /// Add SmartFilterContainerView to the parent
        
        if (smartFilterContainerView == nil) {
            smartFilterContainerView = SmartFilterContainerView(frame: self.view.bounds)
            self.view.addSubview(smartFilterContainerView!)
        }
        
        updateSmartFilterState()
    }
    
    private func updateSmartFilterState() {
        
        if let smartFilterContainerView = self.smartFilterContainerView {
            
            let smartFilterViews = smartFilterContainerView.subviews.filter { (view) -> Bool in
                return (view as? SmartFilterView) != nil
            }
            
            for subView in smartFilterViews {
                if let smartFilterView = subView as? SmartFilterView {
                    for button in smartFilterView.filterButtons {
                        button.addTarget(self, action: "onSmartFilterButtonToggled:", forControlEvents: UIControlEvents.TouchDown)
                        
                        ///Check selection state
                        if let filterGroup : FilterGroup = smartFilterView.filtersByButton[button] {
                            
                            button.setToggleState(getStateForSmartFilterButton(filterGroup))
                            
                        }
                    }
                }
            }
            
        }
    }
    
    
    private func configureSortingButtons() {
        let bgColorWhenSelected = UIColor.colorWithRGB(0x00E3E3, alpha: 0.6)
        self.sortByPriceButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortBySizeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortByPostTimeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
    }
    
    private func alertSavingCurrentSearchSuccess() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "當前的搜尋條件已經被儲存，\n之後可以在\"常用搜尋\"看到"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("當前搜尋條件儲存成功", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    private func alertSavingCurrentSearchFailure() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "常用搜尋儲存已達上限，\n請先刪除不需要的條件"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("常用搜尋儲存空間已滿", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func alertMaxCollection() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "您目前的收藏筆數已達上限\(CollectionItemService.CollectionItemConstants.MYCOLLECTION_MAX_SIZE)筆。"
        
        alertView.showInfo("我的收藏滿了", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    private func tryAlertAddingToCollectionSuccess() {
        
        if(!UserDefaultsUtils.needsMyCollectionPrompt()) {
            return
        }
        
        let alertView = SCLAlertView()
        
        let subTitle = "成功加入一筆租屋到\"我的收藏\"\n現在去看看收藏項目嗎？"
        
        alertView.addButton("馬上去看看") {
            UserDefaultsUtils.disableMyCollectionPrompt()
            
            let parentViewController = self.navigationController?.popViewControllerAnimated(true)
            parentViewController?.tabBarController?.selectedIndex = 1
        }
        
        alertView.addButton("不需要") {
            UserDefaultsUtils.disableMyCollectionPrompt()
        }
        
        alertView.showCloseButton = false
        
        alertView.showTitle("新增到我的收藏", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }
    
    private func startSpinner() {
        loadingSpinner.startAnimating()
    }
    
    private func stopSpinner() {
        loadingSpinner.stopAnimating()
    }
    
    private func loadHouseListPage(pageNo: Int) {
        
        if(pageNo > dataSource.estimatedTotalResults){
            Log.debug("loadHouseListPage: Exceeding max number of pages [\(dataSource.estimatedTotalResults)]")
            return
        }
        
        startSpinner()
        dataSource.loadDataForPage(pageNo)
        
    }
    
    private func onDataLoaded(dataSource: HouseItemTableDataSource, pageNo: Int, error: NSError?) -> Void {
        
        if let error = error {
            // Initialize Alert View
            
            let alertView = UIAlertView(
                title: NSLocalizedString("unable_to_get_data.alert.title", comment: ""),
                message: NSLocalizedString("unable_to_get_data.alert.msg", comment: ""),
                delegate: self,
                cancelButtonTitle: NSLocalizedString("unable_to_get_data.alert.button.ok", comment: ""))
            
            alertView.tag = 1
            alertView.show()
            
            ///GA Tracker
            if let duration = dataSource.loadingDuration {
                self.trackTimeForCurrentScreen("Networkdata", interval: Int(duration * 1000),
                    name: "searchHouse", label: String(error.code))
            }
        } else {
            
            ///GA Tracker
            if let duration = dataSource.loadingDuration {
                self.trackTimeForCurrentScreen("Networkdata", interval: Int(duration * 1000), name: "searchHouse")
            }
        }
        
        LoadingSpinner.shared.stop()
        self.stopSpinner()
        
        /// Track the total result only for the first request
        if(pageNo == 1) {
            
            var isFiltesOn = false
            var searchAction:String?
            if let filters = self.searchCriteria?.filters {
                isFiltesOn = filters.count > 0
            }
            
            /// GA Tracker
            searchAction = isFiltesOn ?
                GAConst.Action.SearchHouse.FilteredResult : GAConst.Action.SearchHouse.SearchResult
            
            if let searchAction = searchAction {
                self.trackEventForCurrentScreen(GAConst.Catrgory.SearchHouse,
                    action: searchAction,
                    label: GAConst.Label.SearchResult.Number,
                    value: dataSource.estimatedTotalResults)
            }
        }
        
        /// GA Tracker: Record each result page loaded by the users
        self.trackEventForCurrentScreen(GAConst.Catrgory.SearchHouse,
            action: GAConst.Action.SearchHouse.LoadPage,
            label: String(pageNo))
        
        
        ///  Set navigation bar title according to the number of result
        if(dataSource.estimatedTotalResults > 0) {
            self.navigationItem.title = "共\(dataSource.estimatedTotalResults)筆結果"
        } else {
            self.navigationItem.title = "查無資料"
            
            /// GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                action: GAConst.Action.Blocking.NoSearchResult,
                label: HouseDataRequester.getInstance().urlComp.URL?.query)
        }
        
        self.tableView.reloadData()
        
        Log.debug("\(self) onDataLoaded: Total #Item in Table: \(dataSource.getSize())")
        
        self.debugTextStr = self.dataSource.debugStr
    }
    
    private func sortByField(sortingField:String, sortingOrder:String) {
        
        Log.debug("Sorting = \(sortingField) \(sortingOrder)")
        self.searchCriteria?.sorting = "\(sortingField) \(sortingOrder)"
        self.sortingStatus[sortingField] = sortingOrder
        
        reloadDataWithNewCriteria(searchCriteria)
        
        updateSortingButton(sortingField, sortingOrder: sortingOrder)
    }
    
    private func updateSortingButton(field: String, sortingOrder: String) {
        
        var targetButton: UIButton!
        
        switch field {
        case HouseItemDocument.price:
            targetButton = sortByPriceButton
        case  HouseItemDocument.size:
            targetButton = sortBySizeButton
        case HouseItemDocument.postTime:
            targetButton = sortByPostTimeButton
        default: break
        }
        
        ///Switch from other sorting fields
        if(!targetButton.selected) {
            ///Disselect all & Clear all sorting icon for Normal state
            sortByPriceButton.selected = false
            sortByPriceButton.setImage(nil,
                forState: UIControlState.Normal)
            
            sortBySizeButton.selected = false
            sortBySizeButton.setImage(nil,
                forState: UIControlState.Normal)
            
            sortByPostTimeButton.selected = false
            sortByPostTimeButton.setImage(nil,
                forState: UIControlState.Normal)
            
            ///Select the one specified by hte user
            targetButton.selected = true
        }
        
        
        ///Set image for selected state
        if(sortingOrder == HouseItemDocument.Sorting.sortAsc) {
            targetButton.setImage(UIImage(named: "arrow_up_n"),
                forState: UIControlState.Selected)
            targetButton.setImage(UIImage(named: "arrow_up_n"),
                forState: UIControlState.Normal)
            
        } else if(sortingOrder == HouseItemDocument.Sorting.sortDesc) {
            targetButton.setImage(UIImage(named: "arrow_down_n"),
                forState: UIControlState.Selected)
            targetButton.setImage(UIImage(named: "arrow_down_n"),
                forState: UIControlState.Normal)
            
        } else {
            assert(false, "Unknown Sorting order")
        }
    }
    
    private func imageWithColor(color: UIColor) -> UIImage {
        
        let rect:CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContextRef? = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
        
    }
    
    private func reloadDataWithNewCriteria(criteria: SearchCriteria?) {
        self.dataSource.criteria = criteria
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(view)
        
        self.dataSource.initData()
        self.tableView.reloadData()//To reflect the latest table data
        
        //Update Advanced Filtet Icon Status
        updateFilterSettingButtonStatus()
    }
    
    private func getStateForSmartFilterButton(filterGroup : FilterGroup) -> Bool {
        
        let selectedFilterId = self.selectedFilterIdSet[filterGroup.id]
        
        if(selectedFilterId == nil) {
            return false
        }
        
        if(selectedFilterId?.count != filterGroup.filters.count) {
            return false
        }
        
        var state = true
        
        for filterId in filterGroup.filters.map({ (filter) -> FilterIdentifier in
            return filter.identifier
        }) {
            state = state && selectedFilterId!.contains(filterId)
        }
        
        return state
    }
    
    private func convertToFilterGroup(selectedFilterIdSet: [String: Set<FilterIdentifier>]) -> [FilterGroup] {
        
        var filterGroupResult = [FilterGroup]()
        
        ///Walk through all items to generate the list of selected FilterGroup
        for section in FilterTableViewController.filterSections {
            for group in section.filterGroups {
                if let selectedFilterId = selectedFilterIdSet[group.id] {
                    let groupCopy = group.copy() as! FilterGroup
                    
                    let selectedFilters = group.filters.filter({ (filter) -> Bool in
                        selectedFilterId.contains(filter.identifier)
                    })
                    
                    groupCopy.filters = selectedFilters
                    
                    filterGroupResult.append(groupCopy)
                }
            }
        }
        
        return filterGroupResult
    }
    
    private func updateSlectedFilterIdSet(newFilterIdSet : [String : Set<FilterIdentifier>]) {
        
        ///Remove filters not included in the newFilterIdSet
        for groupId in self.selectedFilterIdSet.keys {
            if (newFilterIdSet[groupId] == nil) {
                self.selectedFilterIdSet.removeValueForKey(groupId)
            }
        }
        
        ///Update/Add filter value
        for (groupId, valueSet) in newFilterIdSet {
            self.selectedFilterIdSet.updateValue(valueSet, forKey: groupId)
        }
        
        ///Save all selected setting
        self.filterDataStore.saveAdvancedFilterSetting(self.selectedFilterIdSet)
    }
    
    
    private func appendSlectedFilterIdSet(newFilterIdSet : [String : Set<FilterIdentifier>]) {
        
        ///Update/Add filter value
        for (groupId, valueSet) in newFilterIdSet {
            self.selectedFilterIdSet.updateValue(valueSet, forKey: groupId)
        }
        
        ///Save all selected setting
        self.filterDataStore.saveAdvancedFilterSetting(self.selectedFilterIdSet)
    }
    
    private func removeSlectedFilterIdSet(groupId : String) {
        
        selectedFilterIdSet.removeValueForKey(groupId)
        
        ///Save all selected setting
        self.filterDataStore.saveAdvancedFilterSetting(self.selectedFilterIdSet)
    }
    
    private func handleAddToCollection(houseItem: HouseItem) {
        
        /// Check if maximum collection is reached
        if (!CollectionItemService.sharedInstance.canAdd()) {
            self.alertMaxCollection()
            return
        }
        
        // Append the houseId immediately to make the UI more responsive
        // TBD: Need to discuss whether we need to retrive the data from remote again
        
        /// Update cached data
        self.collectionIdList?.append(houseItem.id)
        
        /// Prompt the user if needed
        self.tryAlertAddingToCollectionSuccess()
        
        HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
            
            if let error = error {
                Log.debug("Cannot get remote data \(error.localizedDescription)")
                return
            }
            
            if let result = result {
                
                /// Add data to CoreData
                let collectionService = CollectionItemService.sharedInstance
                collectionService.addItem(result)
                
                /// Reload collection list
                self.collectionIdList = collectionService.getIds()
                
                ///GA Tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    action: GAConst.Action.MyCollection.AddItemPrice,
                    label: String(houseItem.price))
                
                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    action: GAConst.Action.MyCollection.AddItemSize,
                    label: String(houseItem.size))
                
                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    action: GAConst.Action.MyCollection.AddItemType,
                    label: String(houseItem.purposeType))
            }
        }
    }
    
    private func handleDeleteFromCollection(houseItem: HouseItem) {
        
        /// Update Collection data in CoreData
        CollectionItemService.sharedInstance.deleteItemById(houseItem.id)
        
        /// Reload cached data
        self.collectionIdList = CollectionItemService.sharedInstance.getIds()
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
            action: GAConst.Action.MyCollection.Delete)
    }
    
    // MARK: - Control Action Handlers
    @IBAction func onSaveSearchButtonClicked(sender: UIBarButtonItem) {
        
        if let criteria = self.searchCriteria {
            
            do{
                try searchItemService.addNewSearchItem(SearchItem(criteria: criteria, type: .SavedSearch))
                
                alertSavingCurrentSearchSuccess()
                
            } catch {
                
                alertSavingCurrentSearchFailure()
            }
            
            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                action: GAConst.Action.Activity.History,
                label: GAConst.Label.History.Save)
        }
    }
    
    func onSmartFilterButtonToggled(sender: UIButton) {
        if let toogleButton = sender as? ToggleButton {
            toogleButton.toggleButtonState()
            
            let isToggleOn = toogleButton.getToggleState()
            
            if let subViews = self.smartFilterContainerView?.subviews {
                
                for subView in subViews {
                    if let smartFilterView = subView as? SmartFilterView {
                        
                        if let filterGroup = smartFilterView.filtersByButton[toogleButton] {
                            
                            var filterIdSet = [String: Set<FilterIdentifier>]()
                            
                            for smartFilter in filterGroup.filters {
                                if(isToggleOn) {
                                    ///Replaced with Smart Filter Setting
                                    filterIdSet[filterGroup.id] = [smartFilter.identifier]
                                    self.appendSlectedFilterIdSet(filterIdSet)
                                    
                                    
                                    ///GA Tracker
                                    self.trackEventForCurrentScreen(GAConst.Catrgory.SmartFilter,
                                        action: smartFilter.key,
                                        label: smartFilter.value)
                                    
                                } else {
                                    ///Clear filters under this group
                                    removeSlectedFilterIdSet(filterGroup.id)
                                }
                            }
                            
                            
                            if let searchCriteria = self.searchCriteria {
                                
                                searchCriteria.filters = self.getFilterDic(self.selectedFilterIdSet)
                                
                            }
                            
                            reloadDataWithNewCriteria(self.searchCriteria)
                        }
                    }
                }
                
            }
        }
    }
    
    @IBAction func onSortingButtonTouched(sender: UIButton) {
        
        var sortingOrder:String!
        var sortingField:String!
        
        switch sender {
        case sortByPriceButton:
            sortingField = HouseItemDocument.price
        case sortBySizeButton:
            sortingField = HouseItemDocument.size
        case sortByPostTimeButton:
            sortingField = HouseItemDocument.postTime
        default:
            assert(false, "Unknown sorting type")
            break
        }
        
        
        if(sender.selected) { ///Touch on an already selected button
            
            if let status = sortingStatus[sortingField] {
                
                ///Reverse the previous sorting order
                
                sortingOrder = ((status == HouseItemDocument.Sorting.sortAsc) ? HouseItemDocument.Sorting.sortDesc : HouseItemDocument.Sorting.sortAsc)
                
            } else {
                
                assert(false, "Incorrect sorting status")
                
            }
            
        } else { ///Switched from other sorting buttons
            
            if let status = self.sortingStatus[sortingField] {
                
                ///Use the previous sorting order
                sortingOrder = status
                
            } else {
                
                ///Use Default Ordering Asc
                sortingOrder = HouseItemDocument.Sorting.sortAsc
            }
        }
        
        sortByField(sortingField, sortingOrder: sortingOrder)
        
        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.Sorting,
            action: sortingField,
            label: sortingOrder)
    }
    
    func onSearchButtonTouched(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Log.debug("\(self) [[viewDidLoad]]")
        
        // Config navigation left bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"search_toolbar_n"), style: UIBarButtonItemStyle.Plain, target: self, action: "onSearchButtonTouched:")
        
        // Load Selected filters
        if let selectedFilterSetting = filterDataStore.loadAdvancedFilterSetting() {
            for (key, value) in selectedFilterSetting {
                self.selectedFilterIdSet[key] = value
            }
            
            //Load previous filters to search critea
            if let criteria = searchCriteria {
                criteria.filters = getFilterDic(self.selectedFilterIdSet)
            }
        }
        
        //Configure cell height
        configureTableView()
        
        //Configure Sorting Status
        configureSortingButtons()
        
        //Configure Filter Buttons
        configureFilterButtons()
        
        //Load list my collections
        collectionIdList = CollectionItemService.sharedInstance.getIds()
        
        //Setup remote data source
        self.dataSource.setDataLoadedHandler(onDataLoaded)
        self.dataSource.criteria = searchCriteria
        
        //Load the first page of data
        self.sortByField(HouseItemDocument.postTime, sortingOrder: HouseItemDocument.Sorting.sortDesc)
        
        
        //Try preload Ad
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.adItem) as! SearchResultAdCell
        cell.loadAdForController(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.debug("\(self) [[viewWillAppear]]")
        
        ///Hide tab bar
        self.tabBarController!.tabBarHidden = true
        
        //Update Smart Filter State to sync with the setting in Advanced setting UI
        updateSmartFilterState()
        
        //Update Advanced Filtet Icon Status
        updateFilterSettingButtonStatus()
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        Log.debug("\(self) [[viewDidAppear]]")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Log.debug("\(self) [[viewWillDisappear]]")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
            case ViewTransConst.showDebugInfo:
                
                let debugVc = segue.destinationViewController as UIViewController
                
                if let pVc = debugVc.presentationController {
                    pVc.delegate = self
                }
                
                let view:[UIView] = debugVc.view.subviews
                
                if let textView = view[0] as? UITextView {
                    textView.text = self.debugTextStr
                }
                
            case ViewTransConst.showAdvancedFilter:
                
                if let ftvc = segue.destinationViewController as? FilterTableViewController {
                    
                    ftvc.selectedFilterIdSet = self.selectedFilterIdSet
                    
                    ftvc.filterDelegate = self
                }
                
            case ViewTransConst.displayHouseDetail:
                
                if let hdvc = segue.destinationViewController as? HouseDetailViewController {
                    
                    var targetHouseItem: HouseItem?
                    
                    if let duplicateHouseItem = self.duplicateHouseItem {
                        
                        targetHouseItem = duplicateHouseItem
                        
                        /// Clear the duplicate house item after displaying it
                        self.duplicateHouseItem = nil
                        
                    } else if let row = tableView.indexPathForSelectedRow?.row {
                        
                        targetHouseItem = dataSource.getItemForRow(row)
                        
                    }
                    
                    hdvc.houseItem = targetHouseItem
                    hdvc.delegate = self
                    
                    if let targetHouseItem = targetHouseItem {
                        ///GA Tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemPrice,
                            label: String(targetHouseItem.price))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemSize,
                            label: String(targetHouseItem.size))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemType,
                            label: String(targetHouseItem.purposeType))
                    }
                }
                
            case ViewTransConst.displayDuplicateHouse:
                
                if let dhvc = segue.destinationViewController as? DuplicateHouseViewController {
                    
                    if let row = tableView.indexPathForSelectedRow?.row {
                        
                        let houseItem = dataSource.getItemForRow(row)
                        
                        dhvc.houseItem = houseItem
                        dhvc.delegate = self
                        dhvc.duplicateList = houseItem.children
                    }
                }
            default: break
            }
        }
    }
}

// MARK: - Table View Data Source
extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    
    private func handleResultCell(indexPath: NSIndexPath) -> SearchResultTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.houseItem, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        let houseItem = dataSource.getItemForRow(indexPath.row)
        
        cell.houseItem = houseItem
        
        var houseFlags: [SearchResultTableViewCell.HouseFlag] = []
        if let previousPrice = houseItem.previousPrice {
            if previousPrice > houseItem.price {
                houseFlags.append(SearchResultTableViewCell.HouseFlag.PRICE_CUT)
            }
        }
        cell.houseFlags = houseFlags
        
        if(FeatureOption.Collection.enableMain) {
            
            var isCollected = false
            
            /// Check if an item is already collected by the user
            if let collectionIdList = self.collectionIdList {
                isCollected = collectionIdList.contains(houseItem.id)
            }
            
            cell.enableCollection(isCollected, eventCallback: { (event, houseItem) -> Void in
                switch(event) {
                case .ADD:
                    self.handleAddToCollection(houseItem)
                case .DELETE:
                    self.handleDeleteFromCollection(houseItem)
                }
            })
        }
        
        return cell
    }
    
    private func handleAdCell(indexPath: NSIndexPath) -> SearchResultAdCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.adItem, forIndexPath: indexPath) as! SearchResultAdCell
        
        //cell.loadAdForController(self)
        
        Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Log.debug("\(self) tableView Count: \(dataSource.getSize())")
        
        return dataSource.getSize()
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell =  cell as? SearchResultAdCell {
            cell.loadAdForController(self)
        }
    }
    
    /// Do not do heavy data binding in this function. Postpone until willDisplayCell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let displayAd = (self.dataSource.getItemForRow(indexPath.row).id == "Ad")
        
        if(displayAd) {
            
            return handleAdCell(indexPath)
            
        } else {
            
            return handleResultCell(indexPath)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let houseItem = dataSource.getItemForRow(indexPath.row)
        
        Log.debug("Duplicates: \(houseItem.children?.joinWithSeparator(","))")
        
        if(houseItem.id == "Ad") {
            return
        }
        
        if let duplicates = houseItem.children {
            self.runOnMainThreadAfter(0.1, block: { () -> Void in
                self.performSegueWithIdentifier(ViewTransConst.displayDuplicateHouse, sender: self)
            })
        } else {
            self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
        }
    }
    
}

// MARK: - Scroll View Delegate
extension SearchResultViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //Log.debug("==scrollViewDidEndDecelerating==")
        //Log.debug("Content Height: \(scrollView.contentSize.height)")
        //Log.debug("Content Y-offset: \(scrollView.contentOffset.y)")
        //Log.debug("ScrollView Height: \(scrollView.frame.size.height)")
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = floor(scrollView.contentSize.height - scrollView.frame.size.height)
        let currentContentOffset = floor(scrollView.contentOffset.y)
        
        if (currentContentOffset >= yOffsetForBottom){
            Log.debug("\(self) Bounced, Scrolled To Bottom")
            
            let nextPage = self.dataSource.currentPage + 1
            
            loadHouseListPage(nextPage)
            
        }else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
            Log.debug("\(self) Bounced, Scrolled To Top")
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //Log.debug("==scrollViewDidScroll==")
        //Log.debug("Content Height: \(scrollView.contentSize.height)")
        //Log.debug("Content Y-offset: \(scrollView.contentOffset.y)")
        //Log.debug("ScrollView Height: \(scrollView.frame.size.height)")
        
        //Check for scroll direction
        if (self.lastContentOffset > scrollView.contentOffset.y){
            self.lastDirection = .ScrollDirectionDown
        } else if (self.lastContentOffset < scrollView.contentOffset.y){
            self.lastDirection = .ScrollDirectionUp
        }
        
        self.lastContentOffset = scrollView.contentOffset.y;
        
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = (scrollView.contentSize.height - self.tableView.rowHeight) - scrollView.frame.size.height
        
        if(yOffsetForBottom >= 0) {
            if (scrollView.contentOffset.y >= yOffsetForBottom){
                Log.debug("\(self) Scrolled To Bottom")
                
                let nextPage = self.dataSource.currentPage + 1
                
                if(nextPage <= dataSource.estimatedTotalResults){
                    startSpinner()
                    return
                }
                
            } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
                //Log.debug("Scrolled To Top")
            }
        }
    }
    
    
}


// MARK: - UIAdaptivePresentationControllerDelegate
extension SearchResultViewController: UIAdaptivePresentationControllerDelegate {
    
    //Need to figure out the use of this...
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}

// MARK: - UIAlertViewDelegate
extension SearchResultViewController: UIAlertViewDelegate {
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        Log.debug("Alert Dialog Button [\(buttonIndex)] Clicked")
    }
    
}

// MARK: - FilterTableViewControllerDelegate
extension SearchResultViewController: FilterTableViewControllerDelegate {
    
    private func getFilterDic(filteridSet: [String : Set<FilterIdentifier>]) -> [String:String] {
        
        let filterGroups = self.convertToFilterGroup(filteridSet)
        
        var allFiltersDic = [String:String]()
        
        for filterGroup in filterGroups {
            let filterPair = filterGroup.filterDic
            
            for (key, value) in filterPair {
                allFiltersDic[key] = value
            }
        }
        
        return allFiltersDic
    }
    
    func onFiltersReset() {
        self.filterDataStore.clearFilterSetting()
    }
    
    func onFiltersSelected(selectedFilterIdSet: [String : Set<FilterIdentifier>]) {
        
        Log.debug("onFiltersSelected: \(selectedFilterIdSet)")
        
        
        self.updateSlectedFilterIdSet(selectedFilterIdSet)
        
        if let searchCriteria = self.searchCriteria {
            
            searchCriteria.filters = self.getFilterDic(self.selectedFilterIdSet)
            
            ///GA Tracker
            dispatch_async(GlobalBackgroundQueue) {
                
                if let filters = searchCriteria.filters {
                    for (key, value) in filters {
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Filter,
                            action: key,
                            label: value)
                    }
                }
                
            }
            
        }
        
        reloadDataWithNewCriteria(self.searchCriteria)
    }
}

// MARK: - HouseDetailViewDelegate
// TODO: A better solution. A delegate for doing "my collecion" operations
extension SearchResultViewController: HouseDetailViewDelegate {
    func onHouseItemStateChanged() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Reload collection list
            self.collectionIdList = CollectionItemService.sharedInstance.getIds()
            
            // Refresh the row
            tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: UITableViewRowAnimation.None)
        }
    }
}

// MARK: - DuplicateHouseViewControllerDelegate
extension SearchResultViewController: DuplicateHouseViewControllerDelegate {
    
    internal func onDismiss() {
        /// Do nothing
    }
    
    internal func onContinue() {
        
        self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
    }
    
    internal func onViewDuplicate(houseItem: HouseItem) {
        
        self.duplicateHouseItem = houseItem
        self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
    }
}
