//
//  SecondViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SwiftyJSON

class MyCollectionTableViewController: UITableViewController {

    var data: [AnyObject] = [AnyObject]()
    
    var loading:Bool = false
    
    private func loadRemoteData(){
        
        NSLog("%@ [[loadRemoteData]]", self)
        
        if self.loading {
            return
        }
        self.loading = true
        
        
        Alamofire.request(Router.HouseList()).responseJSON {
            closureResponse in
            
            self.loading = false
            
            if closureResponse.2.isFailure {
                let alert = UIAlertView(title: "網路異常", message: "請檢查網路設定", delegate: nil, cancelButtonTitle: "確定")
                alert.show()
                return
            }
            
            
            let json = closureResponse.2.value
            var result = JSON(json!)
            
            //NSLog("\(result)")
            
            if result["responseHeader", "status"].intValue == 0 {
                
                let numOfRecord = result["response", "numFound"].intValue
                NSLog("numOfRecord \(numOfRecord)")
                
                let items = result["response", "docs"].object as! [AnyObject]
                
                if (items.count == 0) {
                    return
                }
                
                NSLog("items count \(items.count)")
                
                var retrievedHouses = [Dictionary<String, AnyObject>]()
                for it in items {
                    let house: Dictionary<String, AnyObject> = it as! Dictionary<String, AnyObject>
                    retrievedHouses.append(house)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    HouseDao.sharedInstance.deleteAll()
                    HouseDao.sharedInstance.addHouseList(retrievedHouses)
                    self.tableView.reloadData()
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        NSLog("%@ [[viewDidLoad]]", self)
        
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 120;
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        loadRemoteData()
        
//        self.tableView.addHeaderWithCallback{
//            NSLog("addHeaderWithCallback")
//            self.loadData(0, isPullRefresh: true)
//        }
//        
//        self.tableView.addFooterWithCallback{
//            NSLog("addFooterWithCallback")
//            if(self.data.count>0) {
//                //let  maxId = self.data.last!.valueForKey("postId") as! Int
//                self.loadData(11, isPullRefresh: false)
//            }
//        }
        
        self.tableView.headerBeginRefreshing()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        if let result = HouseDao.sharedInstance.getHouseList() {
            self.data = result
            NSLog("data count: \(data.count)")
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCollectionCell", forIndexPath: indexPath) as! MyCollectionCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)

        cell.parentTableView = tableView
        cell.indexPath = indexPath
        cell.houseItem = self.data[indexPath.row]
 
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCollectionCell", forIndexPath: indexPath) as! MyCollectionCell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == self.data.count-1 {
            
            // self.tableView.footerBeginRefreshing()
            //  loadData(self.data[indexPath.row].valueForKey("postId") as! Int,isPullRefresh:false)
            
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "HouseDetail" {
            
            if segue.destinationViewController is HouseDetailController {
                let view = segue.destinationViewController as! HouseDetailController
                let indexPath = self.tableView.indexPathForSelectedRow
                
                let house: AnyObject = self.data[indexPath!.row]
                view.house = house
                
                
            }
        }
    }
    
    // MARK: - Table edit mode
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let selectedItem: AnyObject = self.data[indexPath.row]
            let id = selectedItem.valueForKey("id") as? String
            HouseDao.sharedInstance.deleteById(id!)
            data.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

    
}

