//
//  SecondViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import FBSDKLoginKit
import AWSCore
import AWSCognito
import SCLAlertView
import BGTableViewRowActionWithImage

private let Log = Logger.defaultLogger

struct CollectionHouseItemDocument {
    
    struct Sorting {
        static let sortAsc = "asc"
        static let sortDesc = "desc"
    }
    
    static let price:String = "price"
    static let size:String = "size"
    static let collectTime:String = "collectTime"
}

class MyCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let cellReuseIdentifier = "houseItemCell"
    
    struct TableConst {
        static let sectionNum:Int = 1
    }
    
    var fetchedResultsController: NSFetchedResultsController!
    
    private var sortingStatus: [String:String] = [String:String]() //Field Name, Sorting Type
    
    var datasets: [AnyObject] = []
    
    // MARK: - Member Fields
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    
    @IBOutlet weak var sortBySizeButton: UIButton!
    
    @IBOutlet weak var sortByCollectTimeButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var syncButton: UIButton!
    
    private let noCollectionLabel = UILabel() //UILabel for displaying no collection message
    private let noCollectionImage = UIImageView(image: UIImage(named: "empty_no_collection"))
    
    // MARK: - Private Utils
    
    private func setNoCollectionMessageVisible(visible: Bool) {
        
        noCollectionLabel.hidden = !visible
        noCollectionImage.hidden = !visible
        
        if(visible) {
            noCollectionLabel.sizeToFit()
        }
        
    }
    
    private func configureTableView() {
        
        tableView.estimatedRowHeight = BaseLayoutConst.houseImageHeight * getCurrentScale()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "houseItemCell")
        
        if let contentView = tableView.superview {
            
            /// UILabel setting
            noCollectionLabel.translatesAutoresizingMaskIntoConstraints = false
            noCollectionLabel.textAlignment = NSTextAlignment.Center
            noCollectionLabel.numberOfLines = -1
            noCollectionLabel.font = UIFont.systemFontOfSize(14)
            noCollectionLabel.autoScaleFontSize = true
            noCollectionLabel.text = SystemMessage.INFO.EMPTY_COLLECTTIONS
            noCollectionLabel.textColor = UIColor.grayColor()
            noCollectionLabel.hidden = true
            contentView.addSubview(noCollectionLabel)
            
            /// Setup constraints for Label
            let xConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let yConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal, toItem: noCollectionImage, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 22)
            yConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow
            
            let rightConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow
            
            /// UIImage setting
            noCollectionImage.translatesAutoresizingMaskIntoConstraints = false
            noCollectionImage.hidden = true
            let size = noCollectionImage.intrinsicContentSize()
            noCollectionImage.frame.size = size
            
            contentView.addSubview(noCollectionImage)
            
            /// Setup constraints for Image
            let xImgConstraint = NSLayoutConstraint(item: noCollectionImage, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xImgConstraint.priority = UILayoutPriorityRequired
            
            let yImgConstraint = NSLayoutConstraint(item: noCollectionImage, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 0.6, constant: 0)
            yImgConstraint.priority = UILayoutPriorityRequired

            
            /// Add constraints to contentView
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint,
                xImgConstraint, yImgConstraint])
            
        }
    }
    
    private func configureSortingButtons() {
        let bgColorWhenSelected = UIColor.colorWithRGB(0x00E3E3, alpha: 0.6)
        self.sortByPriceButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortBySizeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortByCollectTimeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
    }
    
    
    private func loadDataBy(sortingField: String?, ascending: Bool?) {
        Log.debug("\(self) loadData")
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setMinShowTime(0.6)
        LoadingSpinner.shared.setOpacity(0.5)
        LoadingSpinner.shared.startOnView(view)
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.CollectionHouseItem.rawValue)
        
        var _sortingField = "title"
        var _ascending = true
        
        if sortingField != nil {
            _sortingField = sortingField!
        }
        
        if ascending != nil {
            _ascending = ascending!
        }
        
        Log.debug("loadData by \(_sortingField) \(_ascending)")
        let firstSort = NSSortDescriptor(key: _sortingField, ascending: _ascending)
        let secondarySort = NSSortDescriptor(key: CollectionHouseItemDocument.collectTime, ascending: false)
        fetchRequest.sortDescriptors = [firstSort, secondarySort]
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // execute fetch request
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            Log.debug("\(fetchError), \(fetchError.userInfo)")
        }
        
        LoadingSpinner.shared.stop()
        self.tableView.reloadData()
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

    private func sortByField(sortingField:String, sortingOrder:String) {
        
        Log.debug("Sorting = \(sortingField) \(sortingOrder)")

        self.sortingStatus[sortingField] = sortingOrder
        
        //self.loadData()
        if sortingOrder == CollectionHouseItemDocument.Sorting.sortAsc {
            self.loadDataBy(sortingField, ascending: true)
        } else {
            self.loadDataBy(sortingField, ascending: false)
        }
        
        updateSortingButton(sortingField, sortingOrder: sortingOrder)
    }
    
    private func updateSortingButton(field: String, sortingOrder: String) {
        
        var targetButton: UIButton!
        
        switch field {
        case CollectionHouseItemDocument.price:
            targetButton = sortByPriceButton
        case  CollectionHouseItemDocument.size:
            targetButton = sortBySizeButton
        case CollectionHouseItemDocument.collectTime:
            targetButton = sortByCollectTimeButton
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
            
            sortByCollectTimeButton.selected = false
            sortByCollectTimeButton.setImage(nil,
                forState: UIControlState.Normal)
            
            ///Select the one specified by hte user
            targetButton.selected = true
        }
        
        
        ///Set image for selected state
        if(sortingOrder == CollectionHouseItemDocument.Sorting.sortAsc) {
            targetButton.setImage(UIImage(named: "arrow_up_n"),
                forState: UIControlState.Selected)
            targetButton.setImage(UIImage(named: "arrow_up_n"),
                forState: UIControlState.Normal)
            
        } else if(sortingOrder == CollectionHouseItemDocument.Sorting.sortDesc) {
            targetButton.setImage(UIImage(named: "arrow_down_n"),
                forState: UIControlState.Selected)
            targetButton.setImage(UIImage(named: "arrow_down_n"),
                forState: UIControlState.Normal)
            
        } else {
            assert(false, "Unknown Sorting order")
        }
    }
    
    private func updateNavigationTitle() {
        var count = 0
        if fetchedResultsController.sections != nil {
            for sectionInfo: NSFetchedResultsSectionInfo in fetchedResultsController.sections! {
                count += sectionInfo.numberOfObjects
            }
        }
        
        if count > 0 {
            self.navigationItem.title = "共\(count)/\(CollectionItemService.CollectionItemConstants.MYCOLLECTION_MAX_SIZE)筆收藏"
        } else {
            self.navigationItem.title = "我的收藏"
        }
    }
    
    
    func onShowNoteEditorTouched(sender: UITapGestureRecognizer) {
        Log.debug("\(self) onShowNoteEditorTouched")
        
        if FeatureOption.Collection.enableNote {
            self.performSegueWithIdentifier("showNotes", sender: sender)
        }
    }
    
    
    // MARK: - Control Action Handlers
    
    @IBAction func onSortingButtonTouched(sender: UIButton) {
        
        var sortingField: String!
        var sortingOrder: String!
        
        switch sender {
        case sortByPriceButton:
            sortingField = CollectionHouseItemDocument.price
        case sortBySizeButton:
            sortingField = CollectionHouseItemDocument.size
        case sortByCollectTimeButton:
            sortingField = CollectionHouseItemDocument.collectTime
        default:
            assert(false, "Unknown sorting type")
            break
        }
        
        if(sender.selected) { ///Touch on an already selected button
            
            if let status = sortingStatus[sortingField] {
                
                ///Reverse the previous sorting order
                if status == CollectionHouseItemDocument.Sorting.sortAsc {
                    sortingOrder = CollectionHouseItemDocument.Sorting.sortDesc
                } else {
                    sortingOrder = CollectionHouseItemDocument.Sorting.sortAsc
                }
                
            } else {
                
                assert(false, "Incorrect sorting status")
                
            }
            
        } else { ///Switched from other sorting buttons
            
            if let status = self.sortingStatus[sortingField] {
                
                ///Use the previous sorting order
                sortingOrder = status
                
            } else {
                
                ///Use Default Ordering Asc
                sortingOrder = CollectionHouseItemDocument.Sorting.sortAsc
            }
        }
        
        sortByField(sortingField, sortingOrder: sortingOrder)
    }
    
    @IBAction func onSyncButtonTouched(sender: UIButton) {
        Log.debug("\(self) onSyncButtonTouched")
        
        if let view = self.view.window?.rootViewController?.view {
            LoadingSpinner.shared.setDimBackground(true)
            LoadingSpinner.shared.setImmediateAppear(true)
            LoadingSpinner.shared.setOpacity(0.8)
            LoadingSpinner.shared.setText("資料同步中")
            LoadingSpinner.shared.startOnView(view)
            
            LoadingSpinner.shared.stop(afterDelay: 2.0)
        }
        
        CollectionItemService.sharedInstance.syncTimeUp()
        NoteService.sharedInstance.syncTimeUp()
    }
    
    /*
    @IBAction func onLoginButtonTouched(sender: UIButton) {
        Log.debug("%@ onLoginButtonTouched", self)
        
        AmazonClientManager.sharedInstance.loginFromView(self) {
            (task: AWSTask!) -> AnyObject! in
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            return nil
        }
        
    }*/
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Log.debug("\(self) viewDidLoad")
        
        // Load data sort by collectTime
        self.sortByField(CollectionHouseItemDocument.collectTime, sortingOrder: CollectionHouseItemDocument.Sorting.sortDesc)
            
        //Configure cell height
        configureTableView()
        
        //Configure Sorting Status
        configureSortingButtons()
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.debug("\(self) viewWillAppear")
        super.viewWillAppear(animated)
        
        ///Show tab bar
        self.tabBarController?.tabBarHidden = false
        
        self.updateNavigationTitle()
        
        //self.logoutButton.hidden = !FeatureOption.Collection.enableLogout
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        ///Show tab bar
        self.tabBarController?.tabBarHidden = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            Log.debug("\(self) prepareForSegue")
            
            switch identifier {
            case "showNotes":
                let destController = segue.destinationViewController as! MyNoteViewController
                if let sender = sender as? UITapGestureRecognizer {
                    if let imgView = sender.view {
                        if let cell = imgView.superview?.superview as? SearchResultTableViewCell {
                            let indexPath = cell.indexPath
                            Log.debug("\(self) segue to showNotes: \(indexPath)")
                            if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                                
                                Log.debug("\(self) segue to showNotes: house title: \(collectionHouseItem.title)")
                                destController.collectionHouseItem = collectionHouseItem
                            }
                        }
                    }
                }
                
            default: break
            }
        }

    }
    
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
        //return fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if let sectionInfo: NSFetchedResultsSectionInfo = fetchedResultsController.sections![section] {
            count = sectionInfo.numberOfObjects
        }
        
        
        if count == 0 {
            self.setNoCollectionMessageVisible(true)
        } else {
            self.setNoCollectionMessageVisible(false)
        }
        
        return count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        //Log.debug("- TableView Prepare Cell For Row[\(indexPath.row)]")
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        if let collectionItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
            cell.houseItemForCollection = collectionItem
            
            let houseId = collectionItem.id
            
            Log.debug("Row[\(indexPath.row)] isOffShelf by id: \(houseId)")
            CollectionItemService.sharedInstance.isOffShelf(houseId) { (offShelf) -> Void in
                Log.debug("Row[\(indexPath.row)] isOffShelf is \(offShelf)")
                
                var houseFlags: [SearchResultTableViewCell.HouseFlag] = []
                
                if offShelf == true {
                    houseFlags.append(SearchResultTableViewCell.HouseFlag.OFF_SHELF)
                }
                
                Log.debug("Row[\(indexPath.row)] isPriceCut by id: \(houseId)")
                CollectionItemService.sharedInstance.isPriceCut(houseId) { (priceCut) -> Void in
                    Log.debug("Row[\(indexPath.row)] isPriceCut is \(priceCut)")
                    
                    if priceCut == true {
                        houseFlags.append(SearchResultTableViewCell.HouseFlag.PRICE_CUT)
                    }
                    
                    cell.houseFlags = houseFlags
                }
            }
        }
        
        /// Enable open note button
        cell.openItemNoteButton.userInteractionEnabled = true
        cell.openItemNoteButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MyCollectionViewController.onShowNoteEditorTouched(_:))))
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
        if let indexPath = tableView.indexPathForSelectedRow {
            if let collectionItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                
                Log.debug("Row[\(indexPath.row)] isOffShelf by id: \(collectionItem.id)")
                CollectionItemService.sharedInstance.isOffShelf(collectionItem.id) { (offShelf) -> Void in
                    Log.debug("Row[\(indexPath.row)] isOffShelf is \(offShelf)")
                    
                    if offShelf == true {
                        let loginAlertView = SCLAlertView()
                        loginAlertView.addButton("移除物件") {
                            CollectionItemService.sharedInstance.deleteItemById(collectionItem.id)
                        }
                        let subTitle = "此物件已被下架或租出，建議從\"我的收藏\"中移除"
                        loginAlertView.showNotice("物件已下架", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
                        
                    } else {
                        
                        let searchSb = UIStoryboard(name: "SearchStoryboard", bundle: nil)
                        if let houseDetailVC = searchSb.instantiateViewControllerWithIdentifier("HouseDetailView") as? HouseDetailViewController {
                            if let houseItem: HouseItem = collectionItem.toHouseItem() {
                                houseDetailVC.houseItem = houseItem
                                
                                ///GA Tracker
                                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                                    action: GAConst.Action.MyCollection.ViewItemPrice,
                                    label: String(houseItem.price))
                                
                                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                                    action: GAConst.Action.MyCollection.ViewItemSize,
                                    label: String(houseItem.size))
                                
                                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                                    action: GAConst.Action.MyCollection.ViewItemType,
                                    label: String(houseItem.purposeType))
                            }
                            self.showViewController(houseDetailVC, sender: self)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table Edit Mode
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        let cellHeight = UInt(BaseLayoutConst.houseImageHeight * getCurrentScale())
        
        let deleteButton =  BGTableViewRowActionWithImage.rowActionWithStyle(UITableViewRowActionStyle.Default, title: "  刪除  ", titleColor: UIColor.whiteColor(), backgroundColor: UIColor.colorWithRGB(0x1CD4C6), image: UIImage(named: "delete_icon")!, forCellHeight: cellHeight, andFittedWidth: false) { (action, indexPath) in
            self.tableView(tableView, commitEditingStyle: UITableViewCellEditingStyle.Delete, forRowAtIndexPath: indexPath)
        }
        
        return [deleteButton]
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                CollectionItemService.sharedInstance.deleteItemById(collectionHouseItem.id)
                
                ///GA Tracker
                self.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    action: GAConst.Action.MyCollection.Delete)
            }
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        Log.debug("\(self) didChangeObject: \(type.rawValue)")
        
        switch type {
        case .Insert:
            //FIXME: iOS 8 Bug!
            if indexPath != newIndexPath {
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            }
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as? SearchResultTableViewCell {
                cell.parentTableView = self.tableView
                cell.indexPath = indexPath
                cell.houseItemForCollection = self.fetchedResultsController.objectAtIndexPath(indexPath!) as? CollectionHouseItem
            } else {
                assert(false, "MyCollection Cell at row: \(indexPath?.row) is nil")
            }

        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.updateNavigationTitle()
        self.tableView.endUpdates()
    }
    
    
    
}

