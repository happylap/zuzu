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

    var notificationItems: [NotificationHouseItem]?
    let notificationService = NotificationItemService.sharedInstance
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doMockData()
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
        if let items = self.notificationItems{
            return items.count
        }
        
        return 0
    }


    private struct Storyboard{
        static let CellReuseIdentifier = "NotificationItemCell"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.CellReuseIdentifier, forIndexPath: indexPath) as! NotificationItemTableViewCell
        
        // Configure the cell...
        cell.notificationItem = notificationItems![indexPath.row]
        return cell
    }
    
    // MARK: - Data manipulation Function
    
    func refresh(){
        if let result = self.notificationService.getAll(){
            self.notificationItems = result
            NSLog("data count: \(notificationItems!.count)")
        }
        self.tableView.reloadData()
    }
    
    func deleteRow(row: Int){
        if self.notificationItems != nil{
            let item = notificationItems![row]
            notificationItems!.removeAtIndex(row)
            self.notificationService.deleteItem(item)
        }
    }

    func setRead(item: NotificationHouseItem){
        if item.isRead == true{
            return
        }
        item.isRead = true
        var updateData = Dictionary<String, AnyObject>()
        updateData["isRead"] = true
        self.notificationService.updateItem(item, dataToUpdate: updateData)
    }
    
    // MARK: - swipe-left-to-delete
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if(editingStyle == .Delete) {
            deleteRow(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }

    // MARK: - select item action
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let item = self.notificationItems?[indexPath.row]{
            if item.isRead == false{
                setRead(item)
            }

            let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            selectedCell.contentView.backgroundColor = UIColor.whiteColor()
            
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
        if self.notificationItems?.count < 1{
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
        data["size"] = 22
        data["img"] = [
            "http://cp2.591.com.tw/house/active/2015/12/19/145053190841130908_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053280315500503_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053282033236000_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053283321717807_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053284171791107_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053284620772901_600x600x579519.jpg",
            "http://cp2.591.com.tw/house/active/2015/12/19/145053285239617402_600x600x579519.jpg"
        ]
        if self.notificationItems?.count < 2{
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
