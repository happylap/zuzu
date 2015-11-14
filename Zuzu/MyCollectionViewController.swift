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

class MyCollectionViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let cellReuseIdentifier = "houseItemCell"
    
    var houseList: [House] = []
    
    var fetchedResultsController: NSFetchedResultsController!
    
    var sortingStatus = [String: Bool]()  // SortingField Name, Ascending
    
    private func loadData() {
        NSLog("%@ loadData", self)
        
        let fetchRequest = NSFetchRequest(entityName: EntityTypes.House.rawValue)
        
        if !sortingStatus.isEmpty {
            for (sortingField, _ascending) in sortingStatus {
                print("\(sortingField): \(_ascending)")
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortingField, ascending: _ascending)]
            }
        }
        else {
            let defaultSorting = NSSortDescriptor(key: "title", ascending: true)
            fetchRequest.sortDescriptors = [defaultSorting]
        }
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        // execute fetch request
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
        
        self.tableView.reloadData()
    }
    
    private func loadHouseListPage(pageNo: Int) {
        
    }

    private func sortByField(button: UIButton, sortingOrder: String) {
        
        ///Switch from other sorting fields
        if(!button.selected) {
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
            button.selected = true
        }
        
        
        ///Set image for selected state
        if(sortingOrder == HouseItemDocument.Sorting.sortAsc) {
            button.setImage(UIImage(named: "sort-ascending"),
                forState: UIControlState.Selected)
            button.setImage(UIImage(named: "sort-ascending"),
                forState: UIControlState.Normal)
            
        } else if(sortingOrder == HouseItemDocument.Sorting.sortDesc) {
            button.setImage(UIImage(named: "sort-descending"),
                forState: UIControlState.Selected)
            button.setImage(UIImage(named: "sort-descending"),
                forState: UIControlState.Normal)
            
        } else {
            assert(false, "Unknown Sorting order")
        }
    }
    
    func onShowNoteEditorTouched(sender: UITapGestureRecognizer) {
        NSLog("%@ onShowNoteEditorTouched", self)
        if let imgView = sender.view {
        
        }
    }
    
    
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    @IBOutlet weak var sortBySizeButton: UIButton!
    @IBOutlet weak var sortByPostTimeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Control Action Handlers
    
    @IBAction func onSortingButtonTouched(sender: UIButton) {
        NSLog("%@ onSortingButtonTouched", self)
        
        var sortingField: String?
        var sortingOrder: String?
        
        switch sender {
        case sortByPriceButton:
            sortingField = HouseItemDocument.price
        case sortBySizeButton:
            sortingField = HouseItemDocument.size
        case sortByPostTimeButton:
            sortingField = "postTime"
        default: break
        }
        
        if let fieldName = sortingField {
            if self.sortingStatus.keys.contains(fieldName) {
                self.sortingStatus[fieldName] = (self.sortingStatus[fieldName] == true ? false : true)
            }
            else {
                self.sortingStatus = [fieldName: true]
            }
            
            sortingOrder = (self.sortingStatus[fieldName] == true ? HouseItemDocument.Sorting.sortAsc : HouseItemDocument.Sorting.sortDesc)
        }
        
        
        NSLog("%@ onSortingButtonTouched: \(sortingField)", self)
        
        self.loadData()
        
        if let sortingOrder = sortingOrder {
            self.sortByField(sender, sortingOrder: sortingOrder)
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("%@ viewDidLoad", self)
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
    
        // Load the first page of data
        self.loadData()
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
        
        if let indexPath = self.tableView.indexPathForSelectedRow {
            
            if segue.identifier == "showMyCollectionDetail" {
                
                NSLog("%@ segue to showMyCollectionDetail: \(indexPath)", self)
                
                let destController = segue.destinationViewController as! MyCollectionDetailViewController
                if let houseItem: House = self.houseList[indexPath.row] {
                    destController.houseItem = houseItem
                }
                
            }
        }
    }
    
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
        //return fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(self.houseList.count)", self)
        //return self.houseList.count
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellReuseIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        cell.houseItemForCollection = self.fetchedResultsController.objectAtIndexPath(indexPath) as! House
        
        /// Enable add to collection button
        cell.addToCollectionButton.userInteractionEnabled = true
        cell.addToCollectionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onShowNoteEditorTouched:")))
        
        return cell
    }
    
    
    
    //    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //
    //        let callActionHandler = { (action: UIAlertAction!) -> Void in
    //            let alertMessage = UIAlertController(title: "Service Unavailable", message: "Sorry, the call feature is not available yet. Please retry later.", preferredStyle: .Alert)
    //            alertMessage.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    //            self.presentViewController(alertMessage, animated: true, completion: nil)
    //        }
    //
    //        let optionMenu = UIAlertController(title: nil, message: "確認聯絡李先生 (代理人)", preferredStyle: .ActionSheet)
    //
    //        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    //        optionMenu.addAction(cancelAction)
    //
    //        let house = self.data[indexPath.row]
    //        let phone = house.valueForKey("phone")?[0] as? String
    //        let callAction = UIAlertAction(title: "手機: \(phone!)", style: .Default, handler: callActionHandler)
    //        optionMenu.addAction(callAction)
    //
    //        self.presentViewController(optionMenu, animated: true, completion: nil)
    //    }
    
    
    // MARK: - Table Edit Mode
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let houseItem: House = self.fetchedResultsController.objectAtIndexPath(indexPath) as? House {
                HouseDao.sharedInstance.deleteByObjectId(houseItem.objectID)
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
            cell.houseItemForCollection = self.fetchedResultsController.objectAtIndexPath(indexPath!) as? House
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
}

