//
//  NotificationItemsTableViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class NotificationItemsTableViewController: UITableViewController {

    var notificationItems = [[HouseItem]]()
    
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
        return notificationItems.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationItems[section].count
    }


    private struct Storyboard{
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! NotificationItemTableViewCell
        
        // Configure the cell...
        cell.notificationItem = notificationItems[indexPath.section][indexPath.row]
        return cell
    }
    

    func refresh(){
        //var houseList = [HouseItem]()
        let newHouse:HouseItem = HouseItem.Builder(id: "a")
            .addTitle("冠提晶華社區】全新時尚裝潢溫馨小套房")
            .addPrice(100000)
            .addSize(10)
            .addAddr("台北市基隆路100號")
            .addHouseType(1)
            .addPurposeType(1)
            .build()
        
        let newHouse2:HouseItem = HouseItem.Builder(id: "b")
            .addTitle("中山馥臨捷運美宅")
            .addPrice(5000)
            .addSize(30)
            .addAddr("台北市中山區雙城街23巷")
            .addHouseType(2)
            .addPurposeType(2)
            .build()

        let newHouse3:HouseItem = HouseItem.Builder(id: "c")
            .addTitle("華威八方全新裝潢一手無敵電梯景觀豪宅")
            .addPrice(15000)
            .addSize(100)
            .addAddr("台北市中山區八德路二段")
            .addHouseType(3)
            .addPurposeType(3)
            .build()

        let newHouse4:HouseItem = HouseItem.Builder(id: "c")
            .addTitle("免爬梯1-2樓套房,看必滿意要看請快")
            .addPrice(15000)
            .addSize(100)
            .addAddr("台北市中正區汀州路一段140巷")
            .addHouseType(4)
            .addPurposeType(4)
            .build()

        let newHouse5:HouseItem = HouseItem.Builder(id: "c")
            .addTitle("最後限時優惠!商業核心-仁富商務中心")
            .addPrice(15000)
            .addSize(100)
            .addAddr("台北市中正區汀州路一段140巷")
            .addHouseType(4)
            .addPurposeType(8)
            .build()
        
        let houseList = [newHouse, newHouse2, newHouse3, newHouse4, newHouse5]
        //houseList.append(newHouse, newHouse2)
        notificationItems.insert(houseList, atIndex: 0)
        tableView.reloadData()
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
