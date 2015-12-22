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

class NotificationItemsTableViewController: UITableViewController {

    var notificationItems = [NotificationHouseItem]()
    let notificationService = NotificationItemService.sharedInstance
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doMockData()
        refresh()
        NSLog("isRead:\(notificationItems[0].isRead)")
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
        return notificationItems.count
    }


    private struct Storyboard{
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! NotificationItemTableViewCell
        
        // Configure the cell...
        cell.notificationItem = notificationItems[indexPath.row]
        return cell
    }
    
    // MARK: - Data manipulation Function
    
    func refresh(){
        if let result = self.notificationService.getAll(){
            self.notificationItems = result
            NSLog("data count: \(notificationItems.count)")
            self.tableView.reloadData()
        }
        tableView.reloadData()
    }
    
    func deleteRow(indexPath: NSIndexPath){
        let item = notificationItems[indexPath.row]
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        self.notificationService.deleteItem(item)
    }
    
    
    // MARK: - swipe-left-to-delete
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if(editingStyle == .Delete) {
            deleteRow(indexPath)
        }
    }

    // MARK: - select item action
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        let item = notificationItems[indexPath.row]
        item.isRead = true
        var data = Dictionary<String, AnyObject>()
        data["isRead"] = item.isRead
        self.notificationService.updateItem(item, dataToUpdate: data)

    }
    
    func doMockData(){
        var data = Dictionary<String, AnyObject>()
        data["source"] = 1
        data["id"] = "bbc"
        data["link"] = ""
        data["mobile_link"] = ""
        data["title"] = "中山馥臨捷運美宅"
        data["title"] = "台北市中山區雙城街23巷"
        data["city"] = 100
        data["region"] = 104
        data["purpose_type"] = 1
        data["house_type"] = 1
        data["price"] = 10000
        data["size"] = 2000
        let item = self.notificationService.getItem("12345678")
        if item == nil{
            print("item is nil")
        }
        //self.notificationService.addItem(data)
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
