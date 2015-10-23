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

class MyCollectionTableViewController: UITableViewController {

    internal var data:[AnyObject] = [AnyObject]()
    
    var loading:Bool = false
    
    private func getDefaultData(){
        
        let dalHouse = HouseDal()
        
        let result = dalHouse.getHouseList()
        
        if result != nil {
            self.data = result!
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        NSLog("%@ [[viewDidLoad]]", self)
        
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 120;
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        
        self.tableView.addHeaderWithCallback{
            
            self.loadData(0, isPullRefresh: true)
        }
        
        self.tableView.addFooterWithCallback{
            
            if(self.data.count>0) {
                self.loadData(11, isPullRefresh: false)
            }
        }
        
        self.tableView.headerBeginRefreshing()
        
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
        return self.data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("myCollectionCell", forIndexPath: indexPath) as! MyCollectionCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        let item: AnyObject = self.data[indexPath.row]
        
        NSLog("%@ [[tableView]] cell \(item)", self)
        
        let title = item.valueForKey("title") as? String
        
        NSLog("title: \(title)")
        
        //cell.title.text = item.valueForKey("title") as? String
        
        return cell
    }
    
    
    func loadData(maxId:Int,isPullRefresh:Bool){
        
        NSLog("%@ [[loadData]]", self)
        
        if self.loading {
            return
        }
        self.loading = true
        
        
        Alamofire.request(Router.HouseList(maxId: maxId, count: 16)).responseJSON {
            closureResponse in
            
            self.loading = false
            
            if(isPullRefresh){
                self.tableView.headerEndRefreshing()
            }
            else{
                self.tableView.footerEndRefreshing()
            }
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
                
                if(items.count==0){
                    return
                }
                
                if(isPullRefresh){
                    
                    let dalHouse = HouseDal()
                    dalHouse.deleteAll()
                    
                    dalHouse.addHouseList(items)
                    
                    self.data.removeAll(keepCapacity: false)
                }
                
                for it in items {
                    
                    self.data.append(it);
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    
                    self.tableView.reloadData()
                }

            }
        }
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! MyCollectionCell
        //cell.containerView.backgroundColor = UIColor(red: 0.85, green: 0.85, blue:0.85, alpha: 0.9)
    }
    
    
    var prototypeCell:MyCollectionCell?
    
    private func configureCell(cell:MyCollectionCell,indexPath: NSIndexPath,isForOffscreenUse:Bool){
        
        let item: AnyObject = self.data[indexPath.row]
        //cell.title.text = item.valueForKey("title") as? String
        cell.selectionStyle = .None;
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if prototypeCell == nil
        {
            self.prototypeCell = self.tableView.dequeueReusableCellWithIdentifier("myCollectionCell") as? MyCollectionCell
        }
        
        self.configureCell(prototypeCell!, indexPath: indexPath, isForOffscreenUse: false)
        
        self.prototypeCell?.setNeedsUpdateConstraints()
        self.prototypeCell?.updateConstraintsIfNeeded()
        self.prototypeCell?.setNeedsLayout()
        self.prototypeCell?.layoutIfNeeded()
        
        
        let size = self.prototypeCell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        return size.height;
        
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

    
}

