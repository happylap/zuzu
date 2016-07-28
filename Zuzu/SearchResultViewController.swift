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
        static let sectionNum: Int = 1
    }

    struct ViewTransConst {
        static let showDebugInfo: String = "showDebugInfo"
        static let showAdvancedFilter: String = "showAdvancedFilter"
        static let displayHouseDetail: String = "displayHouseDetail"
        static let displayDuplicateHouse: String = "displayDuplicateHouse"
    }

    enum ScrollDirection {
        case ScrollDirectionNone
        case ScrollDirectionRight
        case ScrollDirectionLeft
        case ScrollDirectionUp
        case ScrollDirectionDown
        case ScrollDirectionCrazy
    }

    // MARK: - Private Fields
    private static var alertViewResponder: SCLAlertViewResponder?
    private var networkErrorAlertView: SCLAlertView? = SCLAlertView()

    private let filterSettingOnImage = UIImage(named: "filter_on_n")
    private let filterSettingNormalImage = UIImage(named: "filter_n")

    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    private let searchItemService: SearchItemService = SearchItemService.getInstance()
    private let dataSource: HouseItemTableDataSource = HouseItemTableDataSource()
    private var lastContentOffset: CGFloat = 0
    private var lastDirection: ScrollDirection = ScrollDirection.ScrollDirectionNone
    private var ignoreScroll = false

    private var sortingStatus: [String:String] = [String:String]() //Field Name, Sorting Type
    private var selectedFilterIdSet = [String : Set<FilterIdentifier>]()

    private var duplicateHouseItem: HouseItem?

    private let noSearchResultLabel = UILabel() //UILabel for displaying no search result message
    private let noSearchResultImage = UIImageView(image: UIImage(named: "empty_no_search_result"))

    private let randomNumber = 2 + Int(arc4random_uniform(UInt32(8))) // 2 ~ 10

    ///Set the time limit within which the counter will not be incremented
    private var radarSuggestionCounterLimitTime: NSDate?

    private var totalItemNumber = 0

    // MARK: - Public Fields

    @IBOutlet weak var filterSettingButton: UIButton!

    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView! {
        didSet {
            stopSpinner()
        }
    }

    @IBOutlet weak var debugBarButton: UIBarButtonItem! {
        didSet {

            let rightItems = self.navigationItem.rightBarButtonItems

            #if DEBUG
                debugBarButton.enabled = true
            #else
                debugBarButton.enabled = false

                /// Remove debug button
                if let rightBarButtonItems = rightItems?.filter({ (button) -> Bool in
                    return (button != debugBarButton)
                }) {

                    self.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
                }

            #endif

        }
    }

    @IBAction func onRentDiscountButtonTouched(sender: AnyObject) {

        if let experimentData = TagUtils.getRentDiscountExperiment() {
            if(experimentData.isEnabled) {

                PromotionService.sharedInstance.showPopupFromViewController(self, popupStyle: CNPPopupStyle.ActionSheet, data: experimentData)

                ///GA Tracker: Campaign Displayed
                self.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                                action: GAConst.Action.Campaign.RentDiscountDisplay, label: experimentData.title)
            }
        }
    }


    @IBOutlet weak var rentDiscountButton: UIBarButtonItem! {
        didSet {

            let rightItems = self.navigationItem.rightBarButtonItems

            if let experimentData = TagUtils.getRentDiscountExperiment() where experimentData.isEnabled {

                rentDiscountButton.enabled = true

            } else {

                rentDiscountButton.enabled = false

                /// Remove debug button
                if let rightBarButtonItems = rightItems?.filter({ (button) -> Bool in
                    return (button != rentDiscountButton)
                }) {

                    self.navigationItem.setRightBarButtonItems(rightBarButtonItems, animated: false)
                }
            }

        }
    }

    @IBOutlet weak var sortByPriceButton: UIButton!

    @IBOutlet weak var sortBySizeButton: UIButton!

    @IBOutlet weak var sortByPostTimeButton: UIButton!

    @IBOutlet weak var tableView: UITableView!

    var smartFilterContainerView: SmartFilterContainerView?

    var debugTextStr: String = ""

    var searchCriteria: SearchCriteria?

    var collectionIdList: [String]?

    // MARK: - Private Utils

    //Check if we can increment the Radar suggestion counter now
    private func isRadarSuggestionTimerTimeout() -> Bool {
        Log.debug("Now = \(NSDate()), radarSuggestionCounterLimitTime = \(radarSuggestionCounterLimitTime)")
        if let timeLimit = self.radarSuggestionCounterLimitTime {
            return timeLimit.timeIntervalSinceNow < 0
        } else {
            return true
        }
    }

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

    private func updateSmartFilterState() {

        if let smartFilterContainerView = self.smartFilterContainerView {

            let smartFilterViews = smartFilterContainerView.subviews.filter { (view) -> Bool in
                return (view as? SmartFilterView) != nil
            }

            for subView in smartFilterViews {
                if let smartFilterView = subView as? SmartFilterView {
                    for button in smartFilterView.filterButtons {
                        button.addTarget(self, action: #selector(SearchResultViewController.onSmartFilterButtonToggled(_:)), forControlEvents: UIControlEvents.TouchDown)

                        ///Check selection state
                        if let filterGroup: FilterGroup = smartFilterView.filtersByButton[button] {

                            button.setToggleState(getStateForSmartFilterButton(filterGroup))

                        }
                    }
                }
            }

        }
    }

    private func setNoSearchResultMessageVisible(visible: Bool) {

        noSearchResultLabel.hidden = !visible
        noSearchResultImage.hidden = !visible

        if(visible) {
            noSearchResultLabel.sizeToFit()
        }
    }

    private func configureAutoScaleNavigationTitle() {

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFontOfSize(21)
        titleLabel.text = self.navigationItem.title
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.sizeToFit()

        self.navigationItem.titleView = titleLabel

    }

    private func configureNoSearchResultMessage() {

        if let contentView = tableView.superview {

            /// UILabel setting
            noSearchResultLabel.translatesAutoresizingMaskIntoConstraints = false
            noSearchResultLabel.textAlignment = NSTextAlignment.Center
            noSearchResultLabel.numberOfLines = -1
            noSearchResultLabel.font = UIFont.systemFontOfSize(14)
            noSearchResultLabel.autoScaleFontSize = true
            noSearchResultLabel.textColor = UIColor.grayColor()
            noSearchResultLabel.text = SystemMessage.INFO.EMPTY_SEARCH_RESULT
            noSearchResultLabel.hidden = true
            contentView.addSubview(noSearchResultLabel)

            /// Setup constraints for Label
            let xConstraint = NSLayoutConstraint(item: noSearchResultLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired

            let yConstraint = NSLayoutConstraint(item: noSearchResultLabel, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal, toItem: noSearchResultImage, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 22)
            yConstraint.priority = UILayoutPriorityRequired

            let leftConstraint = NSLayoutConstraint(item: noSearchResultLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow

            let rightConstraint = NSLayoutConstraint(item: noSearchResultLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow

            /// UIImage setting
            noSearchResultImage.translatesAutoresizingMaskIntoConstraints = false
            noSearchResultImage.hidden = true
            let size = noSearchResultImage.intrinsicContentSize()
            noSearchResultImage.frame.size = size

            noSearchResultImage.userInteractionEnabled = true
            noSearchResultImage.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(SearchResultViewController.onNoSearchResultImageTouched(_:)))
            )

            contentView.addSubview(noSearchResultImage)

            /// Setup constraints for Image

            let xImgConstraint = NSLayoutConstraint(item: noSearchResultImage, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xImgConstraint.priority = UILayoutPriorityRequired

            let yImgConstraint = NSLayoutConstraint(item: noSearchResultImage, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 0.6, constant: 0)
            yImgConstraint.priority = UILayoutPriorityRequired


            /// Add constraints to contentView
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint,
                xImgConstraint, yImgConstraint])
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

    private func configureFilterButtons() {

        /// Add SmartFilterContainerView to the parent

        if (smartFilterContainerView == nil) {
            smartFilterContainerView = SmartFilterContainerView(frame: self.view.bounds)
            self.view.addSubview(smartFilterContainerView!)
        }

        updateSmartFilterState()
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

            NSNotificationCenter.defaultCenter().postNotificationName(SwitchToTabNotification, object: self, userInfo: ["targetTab" : MainTabConstants.COLLECTION_TAB_INDEX])
        }

        alertView.addButton("不需要") {
            UserDefaultsUtils.disableMyCollectionPrompt()
        }

        alertView.showCloseButton = false

        alertView.showTitle("新增到我的收藏", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }

    private func tryPromptRadarSuggestion() {

        let allowPrompt = UserDefaultsUtils.isAllowPromptRadarSuggestion()

        if(!allowPrompt) {
            Log.debug("Do not prompt Radar suggestion")
            return
        }

        let alertView = SCLAlertView()

        let subTitle = "快來用專屬於你的「租屋雷達」\n\n" +
            "● 持續掃描滿足您條件的新物件\n" +
            "● 一小時內App即時通知到手機" +
        "\n\n幫你省時搶好屋！"

        alertView.addButton("馬上去看看") {
            //If fisrt time, pop up landing page
            if(UserDefaultsUtils.needsDisplayRadarLandingPage()) {

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("radarLandingPage")
                vc.modalPresentationStyle = .OverFullScreen
                self.presentViewController(vc, animated: true, completion: nil)

            } else {

                NSNotificationCenter.defaultCenter().postNotificationName(SwitchToTabNotification, object: self, userInfo: ["targetTab" : MainTabConstants.RADAR_TAB_INDEX])
            }

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.PromptRadarSuggestion, label: "now")
        }

        alertView.addButton("稍後再說") {
            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.PromptRadarSuggestion, label: "later")
        }

        alertView.addButton("不再顯示") {
            UserDefaultsUtils.setAllowPromptRadarSuggestion(false)

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.PromptRadarSuggestion, label: "disabled")
        }

        alertView.showCloseButton = false

        alertView.showNotice("還找不到滿意物件？", subTitle: subTitle, colorStyle: 0x1CD4C6)
    }

    private func startSpinner() {
        loadingSpinner.startAnimating()
    }

    private func stopSpinner() {
        loadingSpinner.stopAnimating()
    }

    private func loadHouseListPage(pageNo: Int) {

        let maxPageNum = ceil( Double(self.totalItemNumber) / Double(HouseItemTableDataSource.Const.pageSize))

        if(pageNo > Int(maxPageNum)) {
            Log.debug("loadHouseListPage: Exceeding max number of pages [\(dataSource.estimatedTotalResults)]")
            return
        }

        startSpinner()
        dataSource.loadDataForPage(pageNo)

    }

    private func onDataLoaded(dataSource: HouseItemTableDataSource, pageNo: Int, error: NSError?) -> Void {

        let isFirstPage = (pageNo == 1)

        if let error = error {
            // Initialize Alert View

            if(SearchResultViewController.alertViewResponder == nil) {

                if let alertView = self.networkErrorAlertView {
                    let msgTitle = NSLocalizedString("unable_to_get_data.alert.title", comment: "")
                    let subTitle = NSLocalizedString("unable_to_get_data.alert.msg", comment: "")
                    let okButton = NSLocalizedString("unable_to_get_data.alert.button.ok", comment: "")

                    alertView.showCloseButton = true

                    SearchResultViewController.alertViewResponder = alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)

                    SearchResultViewController.alertViewResponder?.setDismissBlock({ () -> Void in
                        SearchResultViewController.alertViewResponder = nil
                    })
                }
            }

            if(isFirstPage) {

                // TODO: Should use a network error image later
                self.setNoSearchResultMessageVisible(true)

            }

            /// GA Tracker
            if let duration = dataSource.loadingDuration {
                self.trackTimeForCurrentScreen("Networkdata", interval: Int(duration * 1000),
                                               name: "searchHouse", label: String(error.code))
            }
        } else {

            /// Update total item number only when data is loaded successfully
            self.totalItemNumber = dataSource.estimatedTotalResults

            /// Display rent discount experiment if needed
            if(pageNo == randomNumber) {
                if let experimentData = TagUtils.getRentDiscountExperiment() {
                    if(experimentData.isEnabled) {
                        self.runOnMainThreadAfter(2.0, block: {
                            PromotionService.sharedInstance.tryShowPopupFromViewController(self, popupStyle: CNPPopupStyle.ActionSheet, data: experimentData)

                            ///GA Tracker: Campaign Displayed
                            self.trackEventForCurrentScreen(GAConst.Catrgory.Campaign,
                                action: GAConst.Action.Campaign.RentDiscountAutoDisplay, label: experimentData.title)
                        })
                    }
                }
            }

            /// Track the total result only for the first request
            if(isFirstPage) {

                var isFiltesOn = false
                var searchAction: String?
                if let filters = self.searchCriteria?.filters {
                    isFiltesOn = filters.count > 0
                }

                /// GA Tracker
                searchAction = isFiltesOn ?
                    GAConst.Action.SearchHouse.FilteredResult : GAConst.Action.SearchHouse.SearchResult

                if let searchAction = searchAction {
                    self.trackEventForCurrentScreen(GAConst.Catrgory.SearchHouse,
                                                    action: searchAction,
                                                    label: "\(dataSource.estimatedTotalResults)")
                }

                /// Check if results hit the lower bound
                if(totalItemNumber < RadarConstants.SUGGESTION_TRIGGER_INCREMENT_THRESHOLD) {

                    /// The first time when the threshold is reached
                    if(self.radarSuggestionCounterLimitTime == nil) {
                        UserDefaultsUtils.incrementRadarSuggestionTriggerCounter()

                        // Start the timer to avoid fast counter increment
                        self.radarSuggestionCounterLimitTime = NSDate().dateByAddingTimeInterval(60)
                    }


                    /// Increment the counter when the buffer runs out
                    // So that the counter won't be incremented every time the filter button is touched
                    if(self.isRadarSuggestionTimerTimeout()) {
                        Log.debug("RadarSuggestionTimer Timeout")
                        UserDefaultsUtils.incrementRadarSuggestionTriggerCounter()
                    }

                    /// Check if we nned to prompt the user
                    let counter = UserDefaultsUtils.getRadarSuggestionTriggerCounter()

                    if(counter >= RadarConstants.SUGGESTION_TRIGGER_COUNT) {

                        /// Suggest Radar to the user
                        self.tryPromptRadarSuggestion()

                        UserDefaultsUtils.resetRadarSuggestionTriggerCounter()
                    }
                }
            }

            ///  Set navigation bar title & other UI according to the number of result
            if(totalItemNumber > 0) {
                (self.navigationItem.titleView as? UILabel)?.text = "共\(totalItemNumber)筆"

                self.setNoSearchResultMessageVisible(false)

            } else {
                (self.navigationItem.titleView as? UILabel)?.text = "查無資料"

                self.setNoSearchResultMessageVisible(true)

                /// GA Tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                                action: GAConst.Action.Blocking.NoSearchResult,
                                                label: HouseDataRequestService.getInstance().urlComp.URL?.query)
            }

            /// GA Tracker
            if let duration = dataSource.loadingDuration {
                self.trackTimeForCurrentScreen("Networkdata", interval: Int(duration * 1000), name: "searchHouse")
            }
        }

        LoadingSpinner.shared.stop()
        self.stopSpinner()

        /// GA Tracker: Record each result page loaded by the users
        self.trackEventForCurrentScreen(GAConst.Catrgory.SearchHouse,
                                        action: GAConst.Action.SearchHouse.LoadPage,
                                        label: String(pageNo))

        self.tableView.reloadData()

        Log.debug("\(self) onDataLoaded: Total #Item in Table: \(dataSource.getSize())")

        self.debugTextStr = self.dataSource.debugStr
    }

    private func sortByField(sortingField: String, sortingOrder: String) {

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

        let rect: CGRect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContextRef? = UIGraphicsGetCurrentContext()

        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)

        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image

    }

    private func reloadDataWithNewCriteria(criteria: SearchCriteria?) {
        Log.enter()

        self.dataSource.criteria = criteria

        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(view)

        self.dataSource.initData()
        self.tableView.reloadData()//To reflect the latest table data

        //Update Advanced Filtet Icon Status
        updateFilterSettingButtonStatus()

        Log.exit()
    }

    private func getStateForSmartFilterButton(filterGroup: FilterGroup) -> Bool {

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

    private func updateSelectedFilterIdSet(newFilterIdSet: [String : Set<FilterIdentifier>]) {

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


    private func appendSelectedFilterIdSet(newFilterIdSet: [String : Set<FilterIdentifier>]) {

        ///Update/Add filter value
        for (groupId, valueSet) in newFilterIdSet {
            self.selectedFilterIdSet.updateValue(valueSet, forKey: groupId)
        }

        ///Save all selected setting
        self.filterDataStore.saveAdvancedFilterSetting(self.selectedFilterIdSet)
    }

    private func removeSelectedFilterIdSet(groupId: String) {

        selectedFilterIdSet.removeValueForKey(groupId)

        ///Save all selected setting
        self.filterDataStore.saveAdvancedFilterSetting(self.selectedFilterIdSet)
    }

    private func handleAddToCollection(houseItem: HouseItem, indexPath: NSIndexPath) {

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

        LoadingSpinner.shared.stop()
        LoadingSpinner.shared.setImmediateAppear(false)
        LoadingSpinner.shared.setGraceTime(1.0)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.view)
        Log.debug("LoadingSpinner startOnView")

        HouseDataRequestService.getInstance().searchById(houseItem.id) { (result, error) -> Void in
            LoadingSpinner.shared.stop()
            Log.debug("LoadingSpinner stop")

            if let error = error {
                let alertView = SCLAlertView()
                alertView.showCloseButton = false
                alertView.addButton("知道了") {
                    /// Reload collection list
                    self.collectionIdList = CollectionItemService.sharedInstance.getIds()

                    /// Reload the table cell
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                }
                let subTitle = "您目前可能是飛航模式或是無網路的狀況，請稍後再試"
                alertView.showNotice("連線錯誤", subTitle: subTitle, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)

                Log.debug("Cannot get remote data \(error.localizedDescription)")
                return
            }

            if let result = result {

                /// Add data to CoreData
                let collectionService = CollectionItemService.sharedInstance
                collectionService.addItem(result)

                /// Reload collection list
                self.collectionIdList = collectionService.getIds()

                /// Reload the table cell
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)

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

    private func performCollectionDeletion(houseID: String, indexPath: NSIndexPath) {

        /// Update Collection data in CoreData
        CollectionItemService.sharedInstance.deleteItemById(houseID)

        /// Reload cached data
        self.collectionIdList = CollectionItemService.sharedInstance.getIds()

        /// Reload the table cell
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)

        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                                        action: GAConst.Action.MyCollection.Delete)

    }

    private func handleDeleteFromCollection(houseItem: HouseItem, indexPath: NSIndexPath) {

        let houseID = houseItem.id

        /// Ask for user confirmation if there exists notes for this item
        if(NoteService.sharedInstance.hasNote(houseID)) {

            let alertView = SCLAlertView()

            alertView.addButton("確認移除") {
                self.performCollectionDeletion(houseID, indexPath: indexPath)
            }

            alertView.showNotice("是否確認移除", subTitle: "此物件包含您撰寫筆記，將此物件從「我的收藏」中移除會一併將筆記刪除，是否確認？", closeButtonTitle: "暫時不要", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)

            return
        }

        self.performCollectionDeletion(houseID, indexPath: indexPath)

    }

    // MARK: - Control Action Handlers
    @IBAction func onSaveSearchButtonClicked(sender: UIBarButtonItem) {

        if let criteria = self.searchCriteria {

            do {
                try searchItemService.addNewSearchItem(SearchItem(criteria: criteria, type: .SavedSearch))

                alertSavingCurrentSearchSuccess()

            } catch {

                alertSavingCurrentSearchFailure()
            }

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.History,
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
                                    self.appendSelectedFilterIdSet(filterIdSet)


                                    ///GA Tracker
                                    self.trackEventForCurrentScreen(GAConst.Catrgory.SmartFilter,
                                                                    action: smartFilter.key,
                                                                    label: smartFilter.value)

                                } else {
                                    ///Clear filters under this group
                                    removeSelectedFilterIdSet(filterGroup.id)
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

        var sortingOrder: String!
        var sortingField: String!

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

    func onNoSearchResultImageTouched(sender: UITapGestureRecognizer) {
        navigationController?.popViewControllerAnimated(true)
    }

    func onSearchButtonTouched(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        Log.debug("\(self) [[viewDidLoad]]")

        // Config navigation left bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"search_toolbar_n"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SearchResultViewController.onSearchButtonTouched(_:)))

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

        configureNoSearchResultMessage()

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
        cell.setupBanner(self)
        cell.loadBanner()

        /// Setup auto-scale navigation title
        self.configureAutoScaleNavigationTitle()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.debug("\(self) [[viewWillAppear]]")

        ///Hide tab bar
        self.tabBarController?.tabBarHidden = true

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

        self.networkErrorAlertView = nil

        Log.debug("\(self) [[viewWillDisappear]]")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {

            Log.debug("prepareForSegue: \(identifier)")

            let item = UIBarButtonItem(title: "返回結果", style: .Plain, target: nil, action: nil)
            self.navigationItem.backBarButtonItem = item

            switch identifier {
            case ViewTransConst.showDebugInfo:

                let debugVc = segue.destinationViewController as UIViewController

                if let pVc = debugVc.presentationController {
                    pVc.delegate = self
                }

                let view: [UIView] = debugVc.view.subviews

                if let textView = view[0] as? UITextView {
                    textView.text = self.debugTextStr
                }

            case ViewTransConst.showAdvancedFilter:

                if let ftvc = segue.destinationViewController as? FilterTableViewController {

                    self.navigationItem.backBarButtonItem?.title = "設定完成"

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
                        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                                        action: GAConst.Action.UIActivity.ViewItemPrice,
                                                        label: String(targetHouseItem.price))

                        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                                        action: GAConst.Action.UIActivity.ViewItemSize,
                                                        label: String(targetHouseItem.size))

                        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                                        action: GAConst.Action.UIActivity.ViewItemType,
                                                        label: String(targetHouseItem.purposeType))
                    }
                }

            case ViewTransConst.displayDuplicateHouse:

                if let dhvc = segue.destinationViewController as? DuplicateHouseViewController {

                    if let row = tableView.indexPathForSelectedRow?.row {

                        let houseItem = dataSource.getItemForRow(row)

                        if let houseItem = houseItem {
                            dhvc.houseItem = houseItem
                            dhvc.delegate = self
                            dhvc.duplicateList = houseItem.children
                        }
                    }
                }
            default: break
            }
        }
    }
}

// MARK: - Table View Data Source
extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {

    private func handleResultCell(indexPath: NSIndexPath, houseItem: HouseItem) -> SearchResultTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.houseItem, forIndexPath: indexPath) as! SearchResultTableViewCell

        Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")

        cell.parentTableView = tableView
        cell.indexPath = indexPath
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

            cell.enableCollection(isCollected, eventCallback: { (event, indexPath, houseItem) -> Void in
                switch(event) {
                case .ADD:
                    self.handleAddToCollection(houseItem, indexPath: indexPath)
                case .DELETE:
                    self.handleDeleteFromCollection(houseItem, indexPath: indexPath)
                }
            })
        }

        return cell
    }

    private func handleAdCell(indexPath: NSIndexPath) -> SearchResultAdCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.adItem, forIndexPath: indexPath) as! SearchResultAdCell

        cell.setupBanner(self)

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
            cell.loadBanner()
        }
    }

    /// Do not do heavy data binding in this function. Postpone until willDisplayCell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let houseItem = self.dataSource.getItemForRow(indexPath.row) {

            let displayAd = (houseItem.id == "Ad")

            if(displayAd) {

                return handleAdCell(indexPath)

            } else {

                return handleResultCell(indexPath, houseItem: houseItem)
            }

        } else {
            assert(false, "No HouseItem for the cell \(indexPath.row)")
            return SearchResultTableViewCell()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let houseItem = dataSource.getItemForRow(indexPath.row)

        if let houseItem = houseItem {
            Log.debug("Duplicates: \(houseItem.children?.joinWithSeparator(","))")

            if(houseItem.id == "Ad") {
                return
            }

            if let _ = houseItem.children {
                self.runOnMainThreadAfter(0.1, block: { () -> Void in
                    self.performSegueWithIdentifier(ViewTransConst.displayDuplicateHouse, sender: self)
                })
            } else {
                self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
            }
        } else {
            assert(false, "No HouseItem for the cell \(indexPath.row)")
        }
    }

}

// MARK: - Scroll View Delegate
extension SearchResultViewController: UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {

        Log.enter()
        Log.debug("Content H: \(scrollView.contentSize.height), Content Y-offset: \(scrollView.contentOffset.y) ScrollView H: \(scrollView.frame.size.height)")

        let yOffsetForTop: CGFloat = 0
        let yOffsetForBottom: CGFloat = floor(scrollView.contentSize.height - scrollView.frame.size.height)
        let currentContentOffset = floor(scrollView.contentOffset.y)

        if (currentContentOffset >= yOffsetForBottom) {
            Log.debug("Bounced, Scrolled To Bottom")

            let nextPage = self.dataSource.currentPage + 1

            loadHouseListPage(nextPage)

        } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
            Log.debug("Bounced, Scrolled To Top")
        }

        Log.exit()
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {

        Log.enter()
        Log.debug("Content H: \(scrollView.contentSize.height), Content Y-offset: \(scrollView.contentOffset.y) ScrollView H: \(scrollView.frame.size.height)")

        //Check for scroll direction
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            self.lastDirection = .ScrollDirectionDown
        } else if (self.lastContentOffset < scrollView.contentOffset.y) {
            self.lastDirection = .ScrollDirectionUp
        }

        self.lastContentOffset = scrollView.contentOffset.y



        let yOffsetForTop: CGFloat = 0
        let yOffsetForBottom: CGFloat = (scrollView.contentSize.height - self.tableView.rowHeight) - scrollView.frame.size.height

        if(yOffsetForBottom >= 0) {
            if (scrollView.contentOffset.y >= yOffsetForBottom) {
                Log.debug("Scrolled To Bottom")

                let nextPage = self.dataSource.currentPage + 1

                if(nextPage <= dataSource.estimatedTotalResults) {
                    startSpinner()
                    return
                }

            } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
                Log.debug("Scrolled To Top")
            }
        }

        Log.exit()
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

        let filterGroups = convertIdentifierToFilterGroup(filteridSet)

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

        /// Update & Persist Filter Changes
        self.updateSelectedFilterIdSet(selectedFilterIdSet)
    }

    func onFiltersSelectionDone(selectedFilterIdSet: [String : Set<FilterIdentifier>]) {

        /// Filter Selection is done
        if let searchCriteria = self.searchCriteria {

            searchCriteria.filters = self.getFilterDic(self.selectedFilterIdSet)

            ///GA Tracker
            dispatch_async(GlobalQueue.Background) {

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
        if let visibleCellIndexPath = tableView.indexPathsForVisibleRows {

            // Reload collection list
            self.collectionIdList = CollectionItemService.sharedInstance.getIds()

            // Refresh the row
            tableView.reloadRowsAtIndexPaths(visibleCellIndexPath, withRowAnimation: UITableViewRowAnimation.None)
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
