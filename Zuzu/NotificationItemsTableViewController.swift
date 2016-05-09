//
//  NotificationItemsTableViewController.swift
//  Zuzu
//
//  Created by Ted on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

class NotificationItemsTableViewController: UITableViewController {
    
    /// Control whether we need to refresh data
    var needsRefreshData = false
    
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
    
    // MARK: - Private Utils
    private func getResultsController() -> TableResultsController{
        let entityName = self.notificationService.entityName
        let controller = CoreDataResultsController.Builder(entityName: entityName).addSorting("postTime", ascending: false).build()
        controller.setDelegate(self)
        return controller
    }
    
    private func initLocalStorage(){
        Log.enter()
        
        /// Load local data first
        self.resultController.refreshData()
        self.tableView.reloadData()
        
        Log.exit()
    }
    
    private func refreshData(showSpinner: Bool){
        Log.enter()
        Log.debug("refreshData, showSpinner: \(showSpinner)")
        
        if(!AmazonClientManager.sharedInstance.isLoggedIn()){
            Log.debug("Cannot refresh data because user is not logged in")
            return
        }
        
        /// The check is currently for Google-Signin
        if(AmazonClientManager.sharedInstance.currentUserToken == nil) {
            Log.debug("Cannot refresh data because user token is not retrieved yet")
            return
        }
        
        
        if let userId = UserManager.getCurrentUser()?.userId {
            if showSpinner == true{
                Log.debug("refresh data with loading")
                LoadingSpinner.shared.stop()
                LoadingSpinner.shared.setImmediateAppear(true)
                LoadingSpinner.shared.setOpacity(0.3)
                LoadingSpinner.shared.startOnView(self.tableView)
            }else{
                Log.debug("refresh data without loading")
            }
            
            /// Get latest notification item post_time
            var lastUpdateTime: NSDate?
            
            if let houseItem = self.notificationService.getLatestNotificationItem() {
                lastUpdateTime = houseItem.postTime
            }
            
            Log.debug("getNotificationItemsByUserId: \(userId), \(lastUpdateTime)")
            
            ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, postTime: lastUpdateTime) { (totalNum, result, error) -> Void in
                
                if showSpinner == true{
                    LoadingSpinner.shared.stop()
                }
                
                if error != nil{
                    
                    Log.debug("getNotificationItemsByUserId fails")
                    
                    if let nsError = error as? NSError where nsError.code == 403{
                        Log.debug("forbidden to getNotificationItemsByUserId")
                    }
                    
                    return
                }
                
                /// Remove data over the max limit
                if totalNum > 0 {
                    /// Try to remove old items if max number of items is reached
                    self.notificationService.removeExtra(true)
                    
                    /// Insert new notification items
                    if let notifyItems: [NotifyItem] = result {
                        for notifyItem: NotifyItem in notifyItems {
                            self.notificationService.add(notifyItem, isCommit: true)
                        }
                    }
                }
                
                /// Finish loading items
                AppDelegate.clearAllBadge()
                
            }
        }
        Log.exit()
    }
    
    private func setItemRead(item: NotificationHouseItem) {
        if !AmazonClientManager.sharedInstance.isLoggedIn() {
            return
        }
        if let userId = UserManager.getCurrentUser()?.userId {
            
            ZuzuWebService.sharedInstance.setReadNotificationByUserId(userId, itemId: item.id) { (result, error) -> Void in
                if (result == true) {
                    var updateData = Dictionary<String, AnyObject>()
                    updateData["isRead"] = true
                    self.notificationService.updateItem(item, dataToUpdate: updateData)
                }
            }
            
        }
    }
    
    // Confiure TableView
    private func configureTableView(){
        
        self.tableView.rowHeight = UIScreen.mainScreen().bounds.width * (500/1440)
        
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
            emptyLabel.autoScaleFontSize = true
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
    
    private func showEmpty(){
        emptyLabel.hidden = true
        emptyLabel.text = SystemMessage.INFO.EMPTY_NOTIFICATIONS
        emptyLabel.sizeToFit()
        emptyLabel.hidden = false
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.enter()
        self.notificationService = NotificationItemService.sharedInstance
        self.resultController = self.getResultsController()
        self.refreshControl?.addTarget(self, action: #selector(NotificationItemsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        self.initLocalStorage()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleUserLogin(_:)), name: UserLoginNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleReceiveNotifyItemsOnNotifyTab(_:)), name: "receiveNotifyItemsOnNotifyTab", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleTabBarTappedNotification(_:)), name: TabBarAgainSelectedNotification, object: nil)
        
        configureTableView()
        Log.exit()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()
        
        /// Refresh data when needed
        if(self.needsRefreshData) {
            self.refreshData(true)
            self.needsRefreshData = false
            
            Log.exit()
            return
        }
        
        /// Refresh data on receiving new items
        let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
        if(badgeNumber > 0) {
            Log.debug("badgeNumber > 0, refreshData")
            self.refreshData(true)
        }
        
        Log.exit()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.enter()
        
        self.tabBarController?.tabBarHidden = false
        
        Log.exit()
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
    
    // MARK: - Acion/Notification Handlers
    
    // Receive new items
    func handleReceiveNotifyItemsOnNotifyTab(notification:NSNotification) {
        Log.enter()
        
        Log.debug("handleReceiveNotifyItemsOnNotifyTab")
        
        self.refreshData(false)
        
        Log.exit()
    }
    
    // User logged in
    func handleUserLogin(notification: NSNotification){
        Log.enter()
        
        Log.debug("set refreshForUserLogin as true")
        self.needsRefreshData = true
        
        Log.exit()
    }
    
    // Pull to update
    func handleRefresh(refreshControl: UIRefreshControl) {
        Log.enter()
        self.refreshData(false)
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
        Log.exit()
    }
    
    // Try to scroll to top
    func handleTabBarTappedNotification(aNotification: NSNotification) {
        Log.debug("didTabBarAgainSelectedNotification")
        if let tabIndex = aNotification.userInfo?["tabIndex"] as? Int {
            if tabIndex == MainTabConstants.NOTIFICATION_TAB_INDEX {
                self.scrollToFirstRow()
            }
        }
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
            //            if item.isRead == false{
            //                item.isRead = true
            //                self.setItemRead(item)
            //            }
            
            let searchSb = UIStoryboard(name: "SearchStoryboard", bundle: nil)
            if let houseDetailVC = searchSb.instantiateViewControllerWithIdentifier("HouseDetailView") as? HouseDetailViewController{
                if let houseItem: HouseItem = item.toHouseItem() {
                    houseDetailVC.houseItem = houseItem
                    houseDetailVC.delegate = self
                    
                    dispatch_async(GlobalQueue.Background) {
                        
                        //GA Tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarNotification,
                                                        action: GAConst.Action.ZuzuRadarNotification.ReadNotificationPrice,
                                                        label: String(houseItem.price))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarNotification,
                                                        action: GAConst.Action.ZuzuRadarNotification.ReadNotificationSize,
                                                        label: String(houseItem.size))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.ZuzuRadarNotification,
                                                        action: GAConst.Action.ZuzuRadarNotification.ReadNotificationType,
                                                        label: String(houseItem.purposeType))
                        
                    }
                    
                }
                
                self.showViewController(houseDetailVC, sender: self)
            }
        }
    }
}

// MARK: - TableResultsControllerDelegate
extension NotificationItemsTableViewController: TableResultsControllerDelegate {
    
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
    
    func scrollToFirstRow() {
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        let rowNum = self.tableView.numberOfRowsInSection(0)
        if rowNum > 0 {
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
}

// MARK: - HouseDetailViewDelegate
extension NotificationItemsTableViewController: HouseDetailViewDelegate {
    
    func onHouseItemLoaded(result: Bool) {
        if (result == true) {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                if let item = self.resultController.objectAtIndexPath(selectedIndexPath) as? NotificationHouseItem {
                    if item.isRead == false {
                        item.isRead = true
                        self.setItemRead(item)
                    }
                }
            }
        }
    }
    
}
