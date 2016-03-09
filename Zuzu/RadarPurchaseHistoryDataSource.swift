//
//  RadarPurchaseHistoryDataSource.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/17.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit

private let Log = Logger.defaultLogger

class RadarPurchaseRecord: NSObject{
    
    var purchaseDate = "test date"
    var purchaseDesc = "test desc"
    var purchaseExpire = true
    
}

class RadarPurchaseRecordTableViewCell: UITableViewCell
{
    @IBOutlet weak var purchaseDateLabel: UILabel!
    
    @IBOutlet weak var purchaseDescLabel: UILabel!
    
    @IBOutlet weak var purchaseExpireLabel: UILabel!
    
    @IBOutlet weak var purchaseImage: UIImageView!
    
    var recordItem:RadarPurchaseRecord?
        {
        didSet{
            updateUI()
        }
    }
    
    func updateUI()
    {
        self.purchaseDateLabel.text = recordItem?.purchaseDate
        self.purchaseDescLabel.text = recordItem?.purchaseDesc
    }
}


class RadarPurchaseHistoryTableViewDataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
        
    private var purchaseData:[RadarPurchaseRecord]?
    
    private let cellID = "purchaseHistoryRecord"
    
    private let cellHeadrID = "purchaseHistoryHeader"
    
    private let uiViewController: RadarDisplayViewController!
    
    init(uiViewController: RadarDisplayViewController) {
        self.uiViewController = uiViewController
        let dummy = RadarPurchaseRecord()
        let p1 = RadarPurchaseRecord()
        self.purchaseData = [dummy]
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var itemSize = 0
        
        if(purchaseData == nil) {
            itemSize = 0
        }else {
            itemSize = purchaseData!.count
        }
        
        Log.debug("Number of purchase history = \(itemSize)")

 
        let emptyLabel = self.uiViewController.emptyLabel
        
        if (itemSize <= 1) {
            emptyLabel.text = SystemMessage.INFO.EMPTY_HISTORICAL_PURCHASE
            emptyLabel.sizeToFit()
            emptyLabel.hidden = false
        } else {
            emptyLabel.hidden = true
        }
        
        return itemSize
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            if let cell = tableView.dequeueReusableCellWithIdentifier(cellHeadrID){
                cell.textLabel!.text = "購買紀錄"
                cell.textLabel!.textColor = UIColor.colorWithRGB(0x6e6e70, alpha: 1)
                return cell
            } else {
                assert(false, "Failed to prepare purchase cell instance")
            }
        }else{
            if let cell = tableView.dequeueReusableCellWithIdentifier(cellID) as? RadarPurchaseRecordTableViewCell{
                
                if let purchaseData = self.purchaseData {
                    
                    let purchase = purchaseData[indexPath.row]
                    
                    cell.recordItem = purchase
                    
                    return cell
                }
            } else {
                assert(false, "Failed to prepare purchase cell instance")
            }
        }
        
        return UITableViewCell()
    }
}
