//
//  SecondViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class MyCollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var houseList: [House] = []
    
    let cellIdentifier = "MyCollectionCell"
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    @IBOutlet weak var sortBySizeButton: UIButton!
    @IBOutlet weak var sortByPostTimeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private func loadData() {
        NSLog("%@ loadData", self)
        if let result = HouseDao.sharedInstance.getHouseList() {
            NSLog("result count: \(result.count)")
            self.houseList = result
            self.tableView.reloadData()
        }
        
        if let result2 = HouseDao.sharedInstance.getHouseIdList() {
            NSLog("result2 count: \(result2.count)")
            print(result2)
        }
    }
    
    override func viewDidLoad() {
        NSLog("%@ viewDidLoad", self)
        super.viewDidLoad()
        //self.loadRemoteData()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSLog("%@ viewWillAppear", self)
        self.loadData()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(self.houseList.count)", self)
        return self.houseList.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! MyCollectionCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        cell.houseItem = self.houseList[indexPath.row]
        
        
        //cell.houseImg.layer.cornerRadius = cell.houseImg.frame.size.width / 2
        //cell.houseImg?.clipsToBounds = true
        
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
    
    // MARK: - Table edit mode
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let houseItem: House = self.houseList[indexPath.row]
            HouseDao.sharedInstance.deleteByObjectId(houseItem.objectID)
            houseList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
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
}

