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

    internal var houseList: Array<House> = []
    
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
            
            NSLog("\(result)")
            
            let status = result["responseHeader", "status"].intValue
            NSLog("status \(status)")
            
            let params = result["responseHeader", "params"]
            NSLog("params \(params)")
            
            if result["responseHeader", "status"].intValue == 0 {
                
                let numOfRecord = result["response", "numFound"].intValue
                NSLog("numOfRecord \(numOfRecord)")
                
                let items = result["response", "docs"].object as! [AnyObject]
                
                if (items.count == 0) {
                    return
                }
                
                var retrievedHouses = [Dictionary<String, AnyObject>]()
                for it in items {
                    let house: Dictionary<String, AnyObject> = it as! Dictionary<String, AnyObject>
                    retrievedHouses.append(house)
                    
                    //daoHouse.deleteAll()
                    HouseDao.sharedInstance.addHouseList(retrievedHouses)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
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
//            if(self.houseList.count>0) {
//                //let  maxId = self.houseList.last!.valueForKey("postId") as! Int
//                self.loadData(11, isPullRefresh: false)
//            }
//        }
        
        self.tableView.headerBeginRefreshing()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        houseList = HouseDao.sharedInstance.getHouseList()
        self.title = String(format: "Upcoming houses (%i)", houseList.count)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.houseList.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCollectionCell", forIndexPath: indexPath) as! MyCollectionCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        let house: House! = self.houseList[indexPath.row]
        
        cell.title.text = house.title
        
//        cell.avatar.af_setImageWithURL(NSURL(string: item.valueForKey("img")[0] as! String)!, placeholderImage: nil)
//        
        cell.avatar.layer.cornerRadius = 5
        cell.avatar.layer.masksToBounds = true
        
        return cell
    }
    
    
    func loadData(maxId:Int,isPullRefresh:Bool){
        
        
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCollectionCell", forIndexPath: indexPath) as! MyCollectionCell
        cell.containerView.backgroundColor = UIColor(red: 0.85, green: 0.85, blue:0.85, alpha: 0.9)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == self.houseList.count-1 {
            
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
                
                let house: AnyObject = self.houseList[indexPath!.row]
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
            let daoHouse = HouseDao()
            daoHouse.delete(houseList[indexPath.row])
            houseList.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            self.title = String(format: "Upcoming houses (%i)", houseList.count)
        }
    }

    
}

