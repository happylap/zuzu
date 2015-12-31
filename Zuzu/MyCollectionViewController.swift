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

class MyCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let cellReuseIdentifier = "houseItemCell"
    
    var fetchedResultsController: NSFetchedResultsController!
    
    private var sortingStatus: [String:String] = [String:String]() //Field Name, Sorting Type
    
    
    // MARK: - Member Fields
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    
    @IBOutlet weak var sortBySizeButton: UIButton!
    
    @IBOutlet weak var sortByCollectTimeButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    
    // UILabel for empty collection list
    let noCollectionLabel = UILabel()
    
    // MARK: - Private Utils
    
    private func configureTableView() {
        
        tableView.estimatedRowHeight = BaseLayoutConst.houseImageWidth * getCurrentScale()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "houseItemCell")
        
        if let contentView = tableView.superview {
            noCollectionLabel.translatesAutoresizingMaskIntoConstraints = false
            noCollectionLabel.textAlignment = NSTextAlignment.Center
            noCollectionLabel.numberOfLines = -1
            noCollectionLabel.font = UIFont.systemFontOfSize(14)
            noCollectionLabel.textColor = UIColor.grayColor()
            noCollectionLabel.hidden = true
            contentView.addSubview(noCollectionLabel)
            
            let xConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let yConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 0.8, constant: 0)
            yConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow
            
            let rightConstraint = NSLayoutConstraint(item: noCollectionLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow
            
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint])
            
        }
    }
    
    private func configureSortingButtons() {
        let bgColorWhenSelected = UIColor.colorWithRGB(0x00E3E3, alpha: 0.6)
        self.sortByPriceButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortBySizeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
        self.sortByCollectTimeButton.setBackgroundImage(imageWithColor(bgColorWhenSelected), forState:UIControlState.Selected)
    }
    
    private func loadData() {
        self.loadDataBy(nil, ascending: nil)
    }
    
    private func loadDataBy(sortingField: String?, ascending: Bool?) {
        NSLog("%@ loadData", self)
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
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
        
        print("loadData by \(_sortingField) \(_ascending)")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: _sortingField, ascending: _ascending)]
        
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // execute fetch request
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        LoadingSpinner.shared.stop()
        self.tableView.reloadData()
    }
    
    private func loadHouseListPage(pageNo: Int) {
        
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
        
        NSLog("Sorting = %@ %@", sortingField, sortingOrder)

        self.sortingStatus[sortingField] = sortingOrder
        
        //self.loadData()
        if sortingOrder == HouseItemDocument.Sorting.sortAsc {
            self.loadDataBy(sortingField, ascending: true)
        } else {
            self.loadDataBy(sortingField, ascending: false)
        }
        
        updateSortingButton(sortingField, sortingOrder: sortingOrder)
    }
    
    private func updateSortingButton(field: String, sortingOrder: String) {
        
        var targetButton: UIButton!
        
        switch field {
        case HouseItemDocument.price:
            targetButton = sortByPriceButton
        case  HouseItemDocument.size:
            targetButton = sortBySizeButton
        case "collectTime":
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
    
    
    func onShowNoteEditorTouched(sender: UITapGestureRecognizer) {
        NSLog("%@ onShowNoteEditorTouched", self)
        
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
            sortingField = HouseItemDocument.price
        case sortBySizeButton:
            sortingField = HouseItemDocument.size
        case sortByCollectTimeButton:
            sortingField = "collectTime"
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
        self.trackEventForCurrentScreen(GAConst.Catrgory.Sorting, action: sortingField, label: sortingOrder)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("%@ viewDidLoad", self)
        
            // Load the first page of data
            self.loadData()
            
            //Configure cell height
            configureTableView()
            
            //Configure Sorting Status
            configureSortingButtons()
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("%@ viewWillAppear", self)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let identifier = segue.identifier {
            
            NSLog("%@ prepareForSegue", self)
            
            switch identifier {
            case "showNotes":
                let destController = segue.destinationViewController as! MyNoteViewController
                if let sender = sender as? UITapGestureRecognizer {
                    if let imgView = sender.view {
                        if let cell = imgView.superview?.superview as? SearchResultTableViewCell {
                            let indexPath = cell.indexPath
                            NSLog("%@ segue to showNotes: \(indexPath)", self)
                            if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                                
                                NSLog("%@ segue to showNotes: house title: \(collectionHouseItem.title)", self)
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
        return Const.SECTION_NUM
        //return fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        
        if let sectionInfo: NSFetchedResultsSectionInfo = fetchedResultsController.sections![section] {
            count = sectionInfo.numberOfObjects
        }
        
        noCollectionLabel.hidden = true
        if count == 0 {
            noCollectionLabel.text = SystemMessage.INFO.EMPTY_COLLECTTIONS
            noCollectionLabel.sizeToFit()
            noCollectionLabel.hidden = false
        }
        
        return count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
            cell.houseItemForCollection = collectionHouseItem
        }
        
        /// Enable add to collection button
        cell.addToCollectionButton.userInteractionEnabled = true
        cell.addToCollectionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onShowNoteEditorTouched:")))
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let storyboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("HouseDetailView") as? HouseDetailViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                    if let houseItem: HouseItem = collectionHouseItem.toHouseItem() {
                        vc.houseItem = houseItem
                        
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
            }
            self.showViewController(vc, sender: self)
        }
    }
    
    // MARK: - Table Edit Mode
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if !FBLoginService.sharedInstance.hasActiveSession() {
            FBLoginService.sharedInstance.confirmAndLogin(self)
        } else {
            if editingStyle == .Delete {
                if let collectionHouseItem: CollectionHouseItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CollectionHouseItem {
                    CollectionHouseItemDao.sharedInstance.deleteByID(collectionHouseItem.id)
                }
            }
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        NSLog("%@ didChangeObject: \(type.rawValue)", self)
        
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! SearchResultTableViewCell
            cell.parentTableView = self.tableView
            cell.indexPath = indexPath
            cell.houseItemForCollection = self.fetchedResultsController.objectAtIndexPath(indexPath!) as? CollectionHouseItem
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
}

