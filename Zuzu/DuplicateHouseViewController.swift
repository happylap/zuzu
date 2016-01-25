//
//  DuplicateHouseViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

protocol DuplicateHouseViewControllerDelegate: class {
    func onDismiss()
    func onContinue()
    func onViewDuplicate(houseItme: HouseItem)
}

class DuplicateHouseViewController: UIViewController {
    
    private let enableAutoForward = false
    
    struct TableConst {
        static let sectionNum:Int = 1
        static let houseCellIdentifier = "houseItemCell"
    }
    
    struct ViewTransConst {
        static let displayHouseDetail:String = "displayHouseDetail"
    }
    
    private let countDownInterval = 1.0
    
    private var duplicateHouses:[HouseItem]?
    
    private var currentTimer:NSTimer?
    
    private var countDown = 10
    
    @IBOutlet weak var firstSubtitleLabel: UILabel! {
        didSet {
            
            var duplicateCount = 0
            
            if let duplicateList = self.duplicateList {
                duplicateCount = duplicateList.count
            }
            
            firstSubtitleLabel.text = String(format: "豬豬為您過濾了 %d 筆重複的物件", duplicateCount)
        }
    }
    
    @IBOutlet weak var duplicateTableView: UITableView!
    
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.addTarget(self, action: "onContinueButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
            
            var title = String(format: "繼續")
            
            if(enableAutoForward) {
                title = String(format: "繼續(\(countDown))")
            }
            
            continueButton.setTitle(title,
                forState: [.Normal])
            
            
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    internal var delegate: DuplicateHouseViewControllerDelegate?
    
    internal var houseItem:HouseItem?
    
    internal var duplicateList:[String]?
    
    internal var collectionIdList:[String]?
    
    private func configureTableView() {
        
        duplicateTableView.estimatedRowHeight = BaseLayoutConst.houseImageHeight * getCurrentScale()
        
        duplicateTableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        duplicateTableView.dataSource = self
        duplicateTableView.delegate = self
        duplicateTableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "houseItemCell")
    }
    
    private func fetchDuplicateHouses(houseIdList:[String]) {
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.view)
        
        HouseDataRequester.getInstance().searchByIds(houseIdList) { (totalNum, result, facetResult, error) -> Void in
            self.duplicateHouses = result
            self.duplicateTableView.reloadData()
            
            LoadingSpinner.shared.stop()
        }
    }
    
    // MARK: - Private Utils
    
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
    
    func onContinueButtonTouched(sender: UIButton) {
        
        self.delegate?.onContinue()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onCancelButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.onDismiss()
        }
    }
    
    func onCheckForwardTriggered() {
        
        countDown--
        
        if(countDown <= 0) {
            currentTimer?.invalidate()
            
            self.delegate?.onContinue()
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        } else {
            
            let title = String(format: "繼續(%d)", self.countDown)
            continueButton.setTitle(title,
                forState: [.Normal])
        }
        
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        
        if let duplicateIdList = self.duplicateList {
            fetchDuplicateHouses(duplicateIdList)
        }
        
        /// Load list my collections
        collectionIdList = CollectionItemService.sharedInstance.getIds()
        
        /// Setup Timer for auto forwarding
        
        if(enableAutoForward) {
            currentTimer = NSTimer.scheduledTimerWithTimeInterval(countDownInterval, target: self, selector: "onCheckForwardTriggered", userInfo: nil, repeats: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


// MARK: - Table View Data Source / Delegate
extension DuplicateHouseViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let duplicateHouses = self.duplicateHouses {
            return duplicateHouses.count
        } else {
            return 0
        }
        
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TableConst.houseCellIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        Log.debug("- Cell Instance [\(cell)] Prepare Cell For Row[\(indexPath.row)]")
        
        if let duplicateHouses = self.duplicateHouses {
            
            cell.parentTableView = tableView
            cell.indexPath = indexPath
            
            let houseItem = duplicateHouses[row]
            
            cell.houseItem = houseItem
            
            
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
            
        } else {
            
            assert(false, "This should not happen when there is no duplicate houses")
            
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let duplicateHouses = self.duplicateHouses {
            
            let houseItem = duplicateHouses[indexPath.row]
            
            self.delegate?.onViewDuplicate(houseItem)
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }
    }
    
}
