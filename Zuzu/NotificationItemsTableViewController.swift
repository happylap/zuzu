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
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.estimatedRowHeight = tableView.rowHeight
        //tableView.rowHeight = UITableViewAutomaticDimension
        refresh()
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
    

    func refresh(){
        doMockData()
        if let result = NotificationHouseItemDao.sharedInstance.getAll(){
            self.notificationItems = result as! [NotificationHouseItem]
            NSLog("data count: \(notificationItems.count)")
            self.tableView.reloadData()
        }
        tableView.reloadData()
    }
    
    func doMockData(){
        var data = Dictionary<String, AnyObject>()
        data["source"] = 1
        data["id"] = "aaa"
        data["link"] = ""
        data["mobile_link"] = ""
        data["title"] = "中山馥臨捷運美宅"
        data["title"] = "台北市中山區雙城街23巷"
        data["city"] = 100
        data["region"] = 104
        data["purpose_type"] = 1
        data["house_type"] = 1
        data["price"] = 10000
        data["size"] = 20
        NotificationHouseItemDao.sharedInstance.add(data, isCommit: true)
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
