//
//  NotificationItemsTableViewController.swift
//  Zuzu
//
//  Created by Ted on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

struct NotificationItemsTableConst {
    static let SECTION_NUM:Int = 1
}

class NotificationItemsTableViewController: UITableViewController, TableResultsControllerDelegate {

    var notificationService: NotificationItemService!
    var resultController: TableResultsController!
    
    private struct Storyboard{
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    func getResultsController() -> TableResultsController{
        let entityName = self.notificationService.entityName
        let controller = CoreDataResultsController.Builder(entityName: entityName).addSorting("notificationTime", ascending: false).build()
        controller.setDelegate(self)
        return controller
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.notificationService = NotificationItemService.sharedInstance
        self.resultController = self.getResultsController()
        
        //doMockData()
        refresh()
        
        //tableView.estimatedRowHeight = tableView.rowHeight
        //tableView.rowHeight = UITableViewAutomaticDimension
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return NotificationItemsTableConst.SECTION_NUM
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.resultController.getNumberOfRowInSection(section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! NotificationItemTableViewCell
        
        // Configure the cell...
        cell.notificationItem = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem

        return cell
    }
    
    // MARK: - Data manipulation Function

    func refresh(){
        self.resultController.refreshData()
        self.tableView.reloadData()
    }
    
    
    // MARK: - swipe-left-to-delete
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if(editingStyle == .Delete) {
            if let notificationItem = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem {
                self.notificationService.deleteItem(notificationItem)
            }
        }
    }

    // MARK: - select item action
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let item = self.resultController.objectAtIndexPath(indexPath) as? NotificationHouseItem {
            if item.isRead == false{
                item.isRead = true
                var updateData = Dictionary<String, AnyObject>()
                updateData["isRead"] = true
                self.notificationService.updateItem(item, dataToUpdate: updateData)
            }
            
            let storyboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("HouseDetailView") as! HouseDetailViewController
            let houseItem = item.toHouseItem()
            vc.houseItem = houseItem
            
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
            
            self.showViewController(vc, sender: self)
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate Function
    
    func controllerWillChangeContent(controller: TableResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: TableResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: TableResultsChangeType, newIndexPath: NSIndexPath?) {
        
        NSLog("%@ didChangeObject: \(type.rawValue)", self)
        
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
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
    
    func doMockData(){
        var data = Dictionary<String, AnyObject>()
        data["source"] = 2
        data["id"] = "aHR0cDovL3JlbnQuaG91c2VmdW4uY29tLnR3L3JlbnQvaG91c2UvODg1NDgwLw=="
        data["link"] = "http://rent.housefun.com.tw/rent/house/885480/"
        data["mobile_link"] = "http://rent.housefun.com.tw/mobile/rent/house/885480"
        data["title"] = "稀有小帝寶精品電梯套房@可炊流理臺~耗資百萬裝潢˙"
        data["city"] = 400
        data["region"] = 404
        data["purpose_type"] = 1
        data["house_type"] = 1
        data["price"] = 8300
        data["size"] = 8
        data["img"] = [
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A00120140000809173235a33480.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732351.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732352.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732353.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732364.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732365.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732366.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732367.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732368.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A001201400008091732369.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A0012014000080917323610.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A0012014000080917323611.jpg?t=2011",
            "https://pic.hfcdn.com/res/DrawImage/ShowPic/600/0/HFRENT04/Z999/09d5524b-ce5c-44e4-8f0e-bf5be791e332/Z999A0012014000080917323612.jpg?t=2011"
        ]

        var currentNum = 0
        //let sectionInfo = self.resultController.sections![0] as NSFetchedResultsSectionInfo
        //let currentNum = sectionInfo.numberOfObjects
        let totalItems = self.notificationService.getAll()
        if totalItems != nil{
            currentNum = totalItems!.count
        }
        if currentNum < 1{
            self.notificationService.addItem(data)
        }
        
        
        data = Dictionary<String, AnyObject>()
        data["source"] = 2
        data["id"] = "aHR0cDovL3JlbnQuNTkxLmNvbS50dy9yZW50LWRldGFpbC0zODI5NjU1Lmh0bWw="
        data["link"] = "http://rent.591.com.tw/rent-detail-3829655.html"
        data["mobile_link"] = "http://m.591.com.tw/mobile-detail.html?houseId=R3829655"
        data["title"] = "近中山北路民權東路口透天二樓整層出租"
        data["city"] = 100
        data["region"] = 104
        data["purpose_type"] = 1
        data["house_type"] = 3
        data["price"] = 15000
        data["size"] = 22.5
        data["img"] = [
            "http://cp2.591.com.tw/house/active/2015/12/19/145053190841130908_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053280315500503_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053282033236000_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053283321717807_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053284171791107_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053284620772901_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053285239617402_600x600x579519.jpg"
        ]

        if currentNum < 1{
            self.notificationService.addItem(data)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
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
