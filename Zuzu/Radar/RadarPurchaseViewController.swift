//
//  RadarPurchaseViewController.swift
//  Zuzu
//
//  Created by eechih on 1/22/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit

private let Log = Logger.defaultLogger

struct MySKProduct {
    var localizedTitle: String
    var localizedDescription: String
}

class RadarPurchaseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var productIDs: Array<String!> = []
    
    var productsArray: Array<MySKProduct!> = []
    
    var selectedProductIndex: Int!
    
    var transactionInProgress = false
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private methods
    
    func requestProductInfo() {
        productsArray.append(MySKProduct(localizedTitle: "A方案: 15天", localizedDescription: "NT$30.00"))
        productsArray.append(MySKProduct(localizedTitle: "B方案: 30天", localizedDescription: "NT$50.00"))
        productsArray.append(MySKProduct(localizedTitle: "C方案: 90天", localizedDescription: "NT$100.00"))
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.productIDs.append("zuzu_radar_col1")
        self.productIDs.append("zuzu_radar_col2")
        self.productIDs.append("zuzu_radar_col3")
        
        self.requestProductInfo()
        
        //Configure table DataSource & Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.scrollEnabled = false
        self.tableView.allowsSelection = false
        
        self.tableView.registerNib(UINib(nibName: "RadarPurchaseTableViewCell", bundle: nil), forCellReuseIdentifier: "radarPurchaseTableViewCell")
        
    }
    
    // MARK: Actions
    @IBAction func cancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) cancelButtonTouched")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Table View Data Source

    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productsArray.count
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("radarPurchaseTableViewCell", forIndexPath: indexPath) as! RadarPurchaseTableViewCell
        
        cell.product = productsArray[indexPath.row]
        
//        /// Enable add to collection button
//        cell.buyButton.userInteractionEnabled = true
//        cell.buyButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onBuyButtonTouched:")))
//        
        return cell
    }
    
    

    
}