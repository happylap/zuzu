//
//  SecondViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class MyCollectionViewController: UIViewController {
    
    var houseList: [House] = []
    
    var sortingField: String?
    var sortingOrder: String?
    
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
    
    private func loadHouseListPage(pageNo: Int) {
        
    }

    
    let cellIdentifier = "houseItemCell"
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    @IBOutlet weak var sortBySizeButton: UIButton!
    @IBOutlet weak var sortByPostTimeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("%@ viewDidLoad", self)
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
    
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
}

extension MyCollectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(self.houseList.count)", self)
        return self.houseList.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        cell.houseItemForCollection = self.houseList[indexPath.row]
//        cell.houseItem = self.houseList[indexPath.row]
        
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
            let houseItem: House = self.houseList[indexPath.row]
            HouseDao.sharedInstance.deleteByObjectId(houseItem.objectID)
            houseList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
}


extension MyCollectionViewController: UIScrollViewDelegate {

    // MARK: - Scroll View Delegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
    }
    
}
