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

class MyCollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var data: [AnyObject] = []
    
    let cellIdentifier = "MyCollectionCell"
    
    @IBOutlet weak var sortByPriceButton: UIButton!
    @IBOutlet weak var sortBySizeButton: UIButton!
    @IBOutlet weak var sortByPostTimeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    let placeholderImg = UIImage(named: "house_img")
    
    private func loadData() {
        NSLog("%@ loadData", self)
        if let result = HouseDao.sharedInstance.getHouseList() {
            NSLog("result count: \(result.count)")
            self.data = result
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        NSLog("%@ viewDidLoad", self)
        super.viewDidLoad()
        self.loadRemoteData()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        NSLog("%@ viewWillAppear", self)
        if (self.data.count == 0) {
            self.loadData()
        }
    }

    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(data.count)", self)
        return data.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) as! MyCollectionCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        cell.houseItem = self.data[indexPath.row]
        
        
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
            let selectedItem: AnyObject = self.data[indexPath.row]
            let id = selectedItem.valueForKey("houseId") as? String
            HouseDao.sharedInstance.deleteById(id!)
            data.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        NSLog("%@ prepareForSegue", self)
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        print(segue)
        print(sender)
        
        
        if segue.identifier == "showMyCollectionDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                NSLog("%@ segue to showMyCollectionDetail: \(indexPath)", self)
                
                let destCtrl = segue.destinationViewController as! MyCollectionDetailViewController
                let selectedItem: AnyObject = self.data[indexPath.row]
                let houseId = selectedItem.valueForKey("houseId") as? String
                destCtrl.houseId = houseId!
            }
        }
    }

    

    
    private func loadRemoteData(){
        NSLog("%@ [[loadRemoteData]]", self)
        
        Alamofire.request(Router.HouseList()).responseJSON {
            closureResponse in
            
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
}

