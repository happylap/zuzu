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


class RadarPurchaseRecordTableViewCell: UITableViewCell
{
    @IBOutlet weak var purchaseDateLabel: UILabel!
    
    @IBOutlet weak var purchaseDescLabel: UILabel!
    
    @IBOutlet weak var purchaseExpireLabel: UILabel!
    
    @IBOutlet weak var purchaseImage: UIImageView!
    
    var recordItem:ZuzuPurchase?
        {
        didSet{
            updateUI()
        }
    }
    
    func updateUI()
    {
        if let dt = recordItem?.purchaseTime{
            self.purchaseDateLabel.text = CommonUtils.getLocalShortStringFromDate(dt)
        }else{
            self.purchaseDateLabel.text = ""
        }
        self.purchaseDescLabel.text = recordItem?.productTitle ?? ""
        
    }
}


class RadarPurchaseHistoryTableViewDataSource : NSObject, UITableViewDelegate, UITableViewDataSource {
        
    private var purchaseData:[ZuzuPurchase]?
    
    private let cellID = "purchaseHistoryRecord"
        
    private let uiViewController: RadarDisplayViewController!
    
    init(uiViewController: RadarDisplayViewController) {
        self.uiViewController = uiViewController
    }
    
    func refresh(){
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            ZuzuWebService.sharedInstance.getPurchaseByUserId(userId){
                (totalNum, result, error) -> Void in
                self.purchaseData = []
                if error != nil{
                    return
                }
                
                if(result != nil){
                    for purchase in result!{
                        self.purchaseData?.append(purchase)
                    }
                }
                
                self.uiViewController?.purchaseTableView.reloadData()
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var itemSize = 0
        
        if(purchaseData == nil) {
            itemSize = 0
        }else {
            itemSize = purchaseData!.count
        }
        
        Log.debug("Number of purchase history = \(itemSize)")

 
        let emptyLabel = self.uiViewController.emptyPurchaseHistoryLabel
        
        if (itemSize < 1) {
            emptyLabel.text = SystemMessage.INFO.EMPTY_HISTORICAL_PURCHASE
            emptyLabel.sizeToFit()
            emptyLabel.hidden = false
        } else {
            emptyLabel.hidden = true
        }
        
        return itemSize
    }
    
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(cellID) as? RadarPurchaseRecordTableViewCell{
            
            if let purchaseData = self.purchaseData {
                
                let purchase = purchaseData[indexPath.row]
                
                cell.recordItem = purchase
                
                return cell
            }
        } else {
            assert(false, "Failed to prepare purchase cell instance")
        }
        
        return UITableViewCell()
    }
}
