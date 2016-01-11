//
//  SearchResultViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/27.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

struct Const {
    static let SECTION_NUM:Int = 1
}

class SearchResultViewController: UIViewController {
    
    let cellIdentifier = "houseItemCell"
    
    struct ViewTransConst {
        static let showDebugInfo:String = "showDebugInfo"
        static let showAdvancedFilter:String = "showAdvancedFilter"
        static let displayHouseDetail:String = "displayHouseDetail"
    }
    
    enum ScrollDirection {
        case ScrollDirectionNone
        case ScrollDirectionRight
        case ScrollDirectionLeft
        case ScrollDirectionUp
        case ScrollDirectionDown
        case ScrollDirectionCrazy
    }
    
    // MARK: - Member Fields
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
    
    @IBOutlet weak var smartFilterScrollView: UIScrollView!
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    var debugTextStr: String = ""
    
    private let searchItemService : SearchItemService = SearchItemService.getInstance()
    private let dataSource: HouseItemTableDataSource = HouseItemTableDataSource()
    private var lastContentOffset:CGFloat = 0
    private var lastDirection: ScrollDirection = ScrollDirection.ScrollDirectionNone
    private var ignoreScroll = false
    
    private var sortingStatus: [String:String] = [String:String]() //Field Name, Sorting Type
    private var selectedFilterIdSet = [String : Set<FilterIdentifier>]()
    
    var searchCriteria: SearchCriteria?
    
    var collectionIdList:[String]?
    
    // MARK: - Private Utils
    
    private func configureTableView() {
        
        tableView.estimatedRowHeight = BaseLayoutConst.houseImageWidth * getCurrentScale()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "houseItemCell")
    }
    
    private func configureFilterButtons() {
        
        if let smartFilterView = smartFilterScrollView.viewWithTag(100) as? SmartFilterView {
            
            for button in smartFilterView.filterButtons {
                button.addTarget(self, action: "onFilterButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
                
                ///Check selection state
                if let filterGroup : FilterGroup = smartFilterView.filtersByButton[button] {
                    
                    button.setToggleState(getStateForSmartFilterButton(filterGroup))
                    
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
    
    private func alertAddingToCollectionSuccess() {
        
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
            NSLog("loadHouseListPage: Exceeding max number of pages [\(dataSource.estimatedTotalResults)]")
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
        
        NSLog("%@ onDataLoaded: Total #Item in Table: \(dataSource.getSize())", self)
        
        self.debugTextStr = self.dataSource.debugStr
    }
    
    private func sortByField(sortingField:String, sortingOrder:String) {
        
        NSLog("Sorting = %@ %@", sortingField, sortingOrder)
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
    
    func onFilterButtonTouched(sender: UIButton) {
        if let toogleButton = sender as? ToggleButton {
            toogleButton.toggleButtonState()
            
            let isToggleOn = toogleButton.getToggleState()
            
            if let smartFilterView = smartFilterScrollView.viewWithTag(100) as? SmartFilterView {
                
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
    
    func onAddToCollectionTouched(sender: UITapGestureRecognizer) {
        
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            AmazonClientManager.sharedInstance.loginFromView(self) {
                (task: AWSTask!) -> AnyObject! in
                return nil
            }
            
            return
        }
        
        if let imgView = sender.view {
            
            if let cell = imgView.superview?.superview as? SearchResultTableViewCell {
                
                ///Get current house ID
                let indexPath = cell.indexPath
                let houseItem = self.dataSource.getItemForRow(indexPath.row)
                
                if (self.collectionIdList == nil || self.collectionIdList!.contains(houseItem.id)){
                    CollectionItemService.sharedInstance.deleteItemById(houseItem.id)
                    // Reload collection list
                    self.collectionIdList = CollectionItemService.sharedInstance.getIds()
                    
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    
                    ///GA Tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                        action: GAConst.Action.MyCollection.Delete)
                    
                } else {
                    
                    // Append the houseId immediately to make the UI more responsive
                    // TBD: Need to discuss whether we need to retrive the data from remote again
                    self.collectionIdList?.append(houseItem.id)
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                    self.alertAddingToCollectionSuccess()
                    
                    HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
                        
                        if let error = error {
                            NSLog("Cannot get remote data %@", error.localizedDescription)
                            return
                        }
                        
                        if let result = result {
                            let collectionService = CollectionItemService.sharedInstance
                            collectionService.addItem(result)
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
            }
        }
    }
    
    
    func dismissCurrentView(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("%@ [[viewDidLoad]]", self)
        
        // Config navigation left bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"search_toolbar_n"), style: UIBarButtonItemStyle.Plain, target: self, action: "dismissCurrentView:")
        
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("%@ [[viewWillAppear]]", self)
        
        ///Hide tab bar
        self.tabBarController!.tabBarHidden = true
        
        //Configure Filter Buttons
        configureFilterButtons()
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("%@ [[viewDidAppear]]", self)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("%@ [[viewWillDisappear]]", self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@", identifier)
            
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
                    if let row = tableView.indexPathForSelectedRow?.row {
                        
                        let houseItem = dataSource.getItemForRow(row)
                        
                        hdvc.houseItem = houseItem
                        hdvc.delegate = self
                        
                        ///GA Tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemPrice,
                            label: String(houseItem.price))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemSize,
                            label: String(houseItem.size))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemType,
                            label: String(houseItem.purposeType))
                    }
                }
                
            default: break
            }
        }
    }
}

// MARK: - Table View Data Source
extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(dataSource.getSize())", self)
        
        return dataSource.getSize()
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        let houseItem = dataSource.getItemForRow(indexPath.row)
        
        cell.houseItem = houseItem
        
        if(FeatureOption.Collection.enableMain) {
            
            /// Enable add to collection button
            cell.addToCollectionButton.hidden = false
            cell.addToCollectionButton.userInteractionEnabled = true
            cell.addToCollectionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onAddToCollectionTouched:")))
            
            /// Init icon type
            if let collectionIdList = self.collectionIdList {
                if(collectionIdList.contains(houseItem.id)) {
                    cell.addToCollectionButton.image = UIImage(named: "heart_pink")
                }
            }
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
    }
    
}

// MARK: - Scroll View Delegate
extension SearchResultViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //NSLog("==scrollViewDidEndDecelerating==")
        //NSLog("Content Height: \(scrollView.contentSize.height)")
        //NSLog("Content Y-offset: \(scrollView.contentOffset.y)")
        //NSLog("ScrollView Height: \(scrollView.frame.size.height)")
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = floor(scrollView.contentSize.height - scrollView.frame.size.height)
        let currentContentOffset = floor(scrollView.contentOffset.y)
        
        if (currentContentOffset >= yOffsetForBottom){
            NSLog("%@ Bounced, Scrolled To Bottom", self)
            
            let nextPage = self.dataSource.currentPage + 1
            
            loadHouseListPage(nextPage)
            
        }else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
            NSLog("%@ Bounced, Scrolled To Top", self)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //NSLog("==scrollViewDidScroll==")
        //NSLog("Content Height: \(scrollView.contentSize.height)")
        //NSLog("Content Y-offset: \(scrollView.contentOffset.y)")
        //NSLog("ScrollView Height: \(scrollView.frame.size.height)")
        
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
                NSLog("%@ Scrolled To Bottom", self)
                
                let nextPage = self.dataSource.currentPage + 1
                
                if(nextPage <= dataSource.estimatedTotalResults){
                    startSpinner()
                    return
                }
                
            } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
                //NSLog("Scrolled To Top")
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
        NSLog("Alert Dialog Button [%d] Clicked", buttonIndex)
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
        
        NSLog("onFiltersSelected: %@", selectedFilterIdSet)
        
        
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