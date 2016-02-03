//
//  NotificationItemsTableViewController.swift
//  Zuzu
//
//  Created by Ted on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

class NotificationItemsTableViewController: UITableViewController, TableResultsControllerDelegate {

    var notificationService: NotificationItemService!
    var resultController: TableResultsController!
    // UILabel for empty collection list
    let emptyLabel = UILabel()

    private struct Storyboard{
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    struct TableConst {
        static let sectionNum:Int = 1
    }
    
    func getResultsController() -> TableResultsController{
        let entityName = self.notificationService.entityName
        let controller = CoreDataResultsController.Builder(entityName: entityName).addSorting("price", ascending: true).addSorting("postTime", ascending: false).build()
        controller.setDelegate(self)
        return controller
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.notificationService = NotificationItemService.sharedInstance
        self.resultController = self.getResultsController()
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)

        refresh()
        configureTableView()
        //tableView.estimatedRowHeight = tableView.rowHeight
        //tableView.rowHeight = UITableViewAutomaticDimension
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onReceiveNofyItems:", name: "receiveNofyItems", object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear: \(self)")
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        self.parentViewController?.tabBarItem.badgeValue = nil
    }
    
    /*override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        Log.debug("viewWillDisappear: \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Confiure View
    func configureTableView(){
        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        // configure empty label
        if let contentView = tableView {
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyLabel.textAlignment = NSTextAlignment.Center
            emptyLabel.numberOfLines = -1
            emptyLabel.font = UIFont.systemFontOfSize(14)
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.hidden = true
            contentView.addSubview(emptyLabel)
            
            let xConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let yConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 0.6, constant: 0)
            yConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow
            
            let rightConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow
            
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint])
            
        }

    }
    
    func showEmpty(){
        emptyLabel.hidden = true
        emptyLabel.text = SystemMessage.INFO.EMPTY_NOTIFICATIONS
        emptyLabel.sizeToFit()
        emptyLabel.hidden = false
    }
    
    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowNum = self.resultController.getNumberOfRowInSection(section)
        if rowNum == 0{
            showEmpty()
        }else if emptyLabel.hidden == false{
            emptyLabel.hidden = true
        }
        return rowNum
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! NotificationItemTableViewCell
        
        // Configure the cell...
        cell.notificationItem = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem

        return cell
    }
    
    // MARK: - Data manipulation Function

    func refresh(){
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.tableView)
        self.refreshData()
        self.resultController.refreshData()
        self.tableView.reloadData()
    }

    func refreshData(){
        ZuzuWebService.sharedInstance.getNotificationItemsByUserId("test") { (result, error) -> Void in
            if let notifyItems: [NotifyItem] = result {
                for notifyItem: NotifyItem in notifyItems {
                    self.notificationService.add(notifyItem, isCommit: true)
                }
            }
            
            LoadingSpinner.shared.stop()
        }
    }
    
    func onReceiveNofyItems(notification:NSNotification) {
        self.refreshData()
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        // Do some reloading of data and update the table view's data source
        // Fetch more objects from a web service, for example...
        
        self.refreshData()
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }
    
    // MARK: - swipe-left-to-delete
    
    /*override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if(editingStyle == .Delete) {
            if let notificationItem = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem {
                self.notificationService.deleteItem(notificationItem)
            }
        }
    }*/

    // MARK: - select item action
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let item = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem {
            if item.isRead == false{
                item.isRead = true
                var updateData = Dictionary<String, AnyObject>()
                updateData["isRead"] = true
                self.notificationService.updateItem(item, dataToUpdate: updateData)
            }

            let searchSb = UIStoryboard(name: "SearchStoryboard", bundle: nil)
            if let houseDetailVC = searchSb.instantiateViewControllerWithIdentifier("HouseDetailView") as? HouseDetailViewController{
                if let houseItem: HouseItem = item.toHouseItem() {
                    houseDetailVC.houseItem = houseItem
                    
                    //GA Tracker
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
                                
                self.showViewController(houseDetailVC, sender: self)
            }
        }
    }
    
    // MARK: - TableResultsControllerDelegate Function
    
    func controllerWillChangeContent(controller: TableResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: TableResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: TableResultsChangeType, newIndexPath: NSIndexPath?) {
        
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
            //let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! NotificationItemTableViewCell
            //cell.notificationItem = self.resultController.objectAtIndexPath(indexPath!) as? NotificationHouseItem
            tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.None)

        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controllerDidChangeContent(controller: TableResultsController) {
        self.tableView.endUpdates()
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
