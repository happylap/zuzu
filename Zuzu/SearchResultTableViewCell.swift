//
//  SearchResultTableViewCell.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import Foundation

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var houseImg: UIImageView!
    
    @IBOutlet weak var houseTitle: UILabel!
    
    @IBOutlet weak var houseDesc: UILabel!
    
    @IBOutlet weak var housePrice: UILabel!
    
    weak var parentTableView: UITableView!

    var indexPath: NSIndexPath!
    
    var houseItem: HouseItem? {
        didSet {
            updateUI()
        }
    }
    
    func updateUI() {
        // reset any existing information
        houseDesc?.text = nil
        houseTitle?.text = nil
        houseImg?.image = nil
        
        // load new information (if any)
        if let houseItem = self.houseItem
        {
            houseTitle?.text =  "\(indexPath.row) : \(houseItem.title)"
            
            houseDesc?.text = houseItem.desc
            housePrice?.text = String(houseItem.price)
            houseImg?.image = UIImage(named: "house_img")
            
            if let imageURLList = houseItem.imgList {
                if let firstURL = NSURL(string: imageURLList[0]) {
                    
                    let myIndexPath = self.indexPath
                    
                    //NSLog("updateUI for: \(myIndexPath), \(self.parentTableView.cellForRowAtIndexPath(myIndexPath) as? SearchResultTableViewCell)")

                    dispatch_async(
                        dispatch_get_global_queue(NSQualityOfService.UserInitiated.rawValue, 0)) {
                            
                            if let imageData = NSData(contentsOfURL: firstURL) {
                                //NSLog("\(myIndexPath.row) -> \(firstURL) Image Loaded")
                                
                                dispatch_async(dispatch_get_main_queue()) {

                                    if let tableCell = self.parentTableView.cellForRowAtIndexPath(myIndexPath) as? SearchResultTableViewCell {
                                        
                                        //NSLog("Current TableCell Info \(tableCell.indexPath.row)")

                                        //NSLog("\(myIndexPath.row) -> \(firstURL) Image Set")
                                        
                                        assert(tableCell.indexPath.row == myIndexPath.row,
                                            "Image is already set by another thread")
                                        
                                        self.houseImg?.image = UIImage(data: imageData)
                                        
                                    } else {
                                        NSLog("Row \(myIndexPath.row) is not visible")
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
