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

    private let houseTypeLabelMaker: LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)

    /// Control whether we need to refresh data
    var needsRefreshData = false

    var notificationService: NotificationItemService!
    var resultController: TableResultsController!

    // UILabel for empty collection list
    private let emptyLabel = UILabel()
    private let radarImage = UIImageView(image: UIImage(named: "radar_toolbar_n")?.imageWithRenderingMode(.AlwaysTemplate))

    private struct Storyboard {
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    struct TableConst {
        static let sectionNum: Int = 1
    }

    // MARK: - Private Utils
    private func getResultsController() -> TableResultsController {
        let entityName = self.notificationService.entityName
        let controller = CoreDataResultsController.Builder(entityName: entityName).addSorting("postTime", ascending: false).build()
        controller.setDelegate(self)
        return controller
    }

    private func initLocalStorage() {
        Log.enter()

        /// Load local data first
        self.resultController.refreshData()
        self.tableView.reloadData()

        Log.exit()
    }

    private func refreshData(showSpinner: Bool) {
        Log.enter()
        Log.debug("refreshData, showSpinner: \(showSpinner)")

        if let userId = UserManager.getCurrentUser()?.userId {

            /// Clear badges when notification tab is to be refreshed
            AppDelegate.clearAllBadge()

            if showSpinner == true {
                Log.debug("refresh data with loading")
                LoadingSpinner.shared.stop()
                LoadingSpinner.shared.setImmediateAppear(true)
                LoadingSpinner.shared.setOpacity(0.3)
                LoadingSpinner.shared.startOnView(self.tableView)
            } else {
                Log.debug("refresh data without loading")
            }

            /// Get latest notification item post_time
            var lastUpdateTime: NSDate?

            if let houseItem = self.notificationService.getLatestNotificationItem() {
                lastUpdateTime = houseItem.postTime
            }

            Log.debug("getNotificationItemsByUserId: \(userId), \(lastUpdateTime)")

            ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, postTime: lastUpdateTime) { (totalNum, result, error) -> Void in

                if showSpinner == true {
                    LoadingSpinner.shared.stop()
                }

                if error != nil {

                    Log.debug("getNotificationItemsByUserId fails")

                    if let nsError = error as? NSError where nsError.code == 403 {
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

            }
        }
        Log.exit()
    }

    private func setItemRead(item: NotificationHouseItem) {
        Log.debug("item = \(item.id)")

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
    private func configureTableView() {

        self.tableView.rowHeight = UIScreen.mainScreen().bounds.width * (500/1440)

        //Remove extra cells when the table height is smaller than the screen
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        // configure empty label
        if let contentView = tableView {

            /// UILabel setting
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            emptyLabel.textAlignment = NSTextAlignment.Center
            emptyLabel.numberOfLines = -1
            emptyLabel.font = UIFont.systemFontOfSize(14)
            emptyLabel.autoScaleFontSize = true
            emptyLabel.textColor = UIColor.grayColor()
            emptyLabel.hidden = true
            emptyLabel.userInteractionEnabled = true
            emptyLabel.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(NotificationItemsTableViewController.onRadarImageTouched(_:)))
            )
            contentView.addSubview(emptyLabel)

            /// Setup constraints for Label
            let xConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired

            let yConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal, toItem: radarImage, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 22)
            yConstraint.priority = UILayoutPriorityRequired

            let leftConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 16)
            leftConstraint.priority = UILayoutPriorityDefaultLow

            let rightConstraint = NSLayoutConstraint(item: emptyLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: 16)
            rightConstraint.priority = UILayoutPriorityDefaultLow

            /// UIImage setting
            radarImage.tintColor = UIColor.lightGrayColor()
            radarImage.translatesAutoresizingMaskIntoConstraints = false
            radarImage.hidden = true
            radarImage.userInteractionEnabled = true
            radarImage.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(NotificationItemsTableViewController.onRadarImageTouched(_:)))
            )

            contentView.addSubview(radarImage)

            /// Setup constraints for Image
            let wImgConstraint = NSLayoutConstraint(item: radarImage, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 45)

            let aspectImgConstraint = NSLayoutConstraint(item: radarImage, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: radarImage, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0)

            let xImgConstraint = NSLayoutConstraint(item: radarImage, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xImgConstraint.priority = UILayoutPriorityRequired

            let yImgConstraint = NSLayoutConstraint(item: radarImage, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 0.6, constant: 0)
            yImgConstraint.priority = UILayoutPriorityRequired


            /// Add constraints to contentView
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint,
                wImgConstraint, aspectImgConstraint, xImgConstraint, yImgConstraint])
        }

    }

    private func showEmpty() {
        emptyLabel.hidden = true
        emptyLabel.text = SystemMessage.INFO.EMPTY_NOTIFICATIONS
        emptyLabel.sizeToFit()

        emptyLabel.hidden = false
        radarImage.hidden = false
    }

    private func isSelectedTab() -> Bool {

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController {

            return tabViewController.selectedIndex == MainTabConstants.NOTIFICATION_TAB_INDEX

        } else {
            return false
        }

    }

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.enter()

        self.notificationService = NotificationItemService.sharedInstance
        self.resultController = self.getResultsController()
        self.refreshControl?.addTarget(self, action: #selector(NotificationItemsTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)

        self.initLocalStorage()

        /// Enable data refreshing when notification view is loaded
        self.needsRefreshData = true

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleUserLogin(_:)), name: UserLoginNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleReceiveNotifyItemsOnNotifyTab(_:)), name: ReceiveNotifyItemsOnNotifyTab, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationItemsTableViewController.handleTabBarTappedNotification(_:)), name: TabBarAgainSelectedNotification, object: nil)

        configureTableView()
        Log.exit()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()

        //Google Analytics Tracker
        self.trackScreen()

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
        if rowNum == 0 {
            showEmpty()
        } else {
            emptyLabel.hidden = true
            radarImage.hidden = true
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

    func onRadarImageTouched(sender: UITapGestureRecognizer) {

        //If fisrt time, pop up landing page
        if(UserDefaultsUtils.needsDisplayRadarLandingPage()) {

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("radarLandingPage")
            vc.modalPresentationStyle = .OverFullScreen
            presentViewController(vc, animated: true, completion: nil)

        } else {

            NSNotificationCenter.defaultCenter().postNotificationName(SwitchToTabNotification, object: self, userInfo: ["targetTab" : MainTabConstants.RADAR_TAB_INDEX])
        }

    }

    // Notification View Load > Receive new items
    // TODO: Should receive this notification when new items are received, and decide what to do by checking the selected tab
    func handleReceiveNotifyItemsOnNotifyTab(notification: NSNotification) {
        Log.enter()

        Log.debug("handleReceiveNotifyItemsOnNotifyTab")

        self.refreshData(false)

        Log.exit()
    }

    // Notification View Load > User Logged In
    func handleUserLogin(notification: NSNotification) {
        Log.enter()

        if(isSelectedTab()) {

            Log.debug("perform data refrshing")
            self.refreshData(false)

        } else {

            Log.debug("pending data refreshing until tab is shown")
            self.needsRefreshData = true

        }

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

            if let houseItem: HouseItem = item.toHouseItem() {

                if(TagUtils.getItemDisplayConfig(houseItem.source).displayDetail) {

                    if let houseDetailVC = searchSb.instantiateViewControllerWithIdentifier("HouseDetailView") as? HouseDetailViewController {

                        houseDetailVC.houseItem = houseItem
                        houseDetailVC.delegate = self

                        self.showViewController(houseDetailVC, sender: self)
                    }

                } else {

                    if let browserVC = searchSb.instantiateViewControllerWithIdentifier("BrowserView") as? BrowserViewController {

                        let sourceName = houseTypeLabelMaker.fromCodeForField("source", code: houseItem.source)

                        browserVC.viewTitle = "\(sourceName ?? "") 原始網頁"
                        browserVC.houseItem = houseItem

                        self.showViewController(browserVC, sender: self)
                    }

                }

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
