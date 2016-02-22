//
//  RadarDisplayViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/4.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

class RadarDisplayViewController: UIViewController {

    var zuzuCriteria = ZuzuCriteria(){
        didSet{
            if zuzuCriteria.criteria == nil{
                zuzuCriteria.criteria = SearchCriteria()
            }
            self.updateServiceTextLabel()
            self.updateCriteriaTextLabel()
        }
    }
    
    var purchaseHistotyTableDataSource = RadarPurchaseHistoryTableViewDataSource()
    
    @IBOutlet weak var regionLabel: UILabel!
    
    @IBOutlet weak var houseInfoLabel: UILabel!
    
    @IBOutlet weak var otherFiltersLabel: UILabel!
    
    @IBOutlet weak var serviceStatusLabel: UILabel!
    
    @IBOutlet weak var serviceExpireLabel: UILabel!
    
    @IBOutlet weak var purchaseTableView: UITableView!
    
    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.houseInfoLabel.numberOfLines = 0
        self.updateServiceTextLabel()
        self.updateCriteriaTextLabel()
        self.configureButton()
        self.purchaseTableView.delegate = self.purchaseHistotyTableDataSource
        self.purchaseTableView.dataSource = self.purchaseHistotyTableDataSource
        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //self.tabBarController!.tabBarHidden = false
    }
    
    @IBAction func enableCriteria(sender: UISwitch) {
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseView") as? RadarPurchaseViewController {
            ///Hide tab bar
            self.tabBarController?.tabBarHidden = true
            vc.modalPresentationStyle = .OverCurrentContext
            vc.completeHandler = { () -> Void in
                ///Show tab bar
                self.tabBarController?.tabBarHidden = false
            }
            
            presentViewController(vc, animated: true, completion: nil)
            
        }
        
        let isEnable = sender.on
        ZuzuWebService.sharedInstance.enableCriteriaByUserId(self.zuzuCriteria.userId!,
            criteriaId: self.zuzuCriteria.criteriaId!, enabled: isEnable) { (result, error) -> Void in
                if error != nil{
                    //zuzualert
                }else{
                    self.zuzuCriteria.enabled = isEnable
                }
        }
    }
    
    private func updateCriteriaTextLabel(){
        let displayItem = RadarDisplayItem(criteria:self.zuzuCriteria.criteria!)
        self.regionLabel?.text = displayItem.title
        self.houseInfoLabel?.text = displayItem.detail
        var filterNum = 0
        if let filterGroups = self.zuzuCriteria.criteria!.filterGroups{
            filterNum = filterGroups.count
        }
        self.otherFiltersLabel?.text = "其他\(filterNum)個過濾條件"
    }
    
    private func updateServiceTextLabel(){
        var diff = 0
        var expirDate = ""
        if let expireDate = self.zuzuCriteria.expireTime{
            let now = NSDate()
            diff = now.daysFrom(expireDate)
            if let dateString = CommonUtils.getLocalShortStringFromDate(expireDate) {
                expirDate = dateString
            }
        }
        self.serviceStatusLabel?.text = "您的通知服務還有\(diff)天"
        self.serviceExpireLabel?.text = "到期日: \(expirDate)"
    }
    
    private func configureButton() {
        
        /*searchButton.layer.borderWidth = 2
        searchButton.layer.borderColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
        searchButton.tintColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        searchButton
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Normal)
        searchButton
            .setTitleColor(UIColor.colorWithRGB(0x1CD4C6, alpha: 1), forState: UIControlState.Selected)*/
        
    }
    

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            self.navigationItem.backBarButtonItem?.title = "完成"
            
            switch identifier{
                
            case ViewTransConst.showConfigureRadar:
                if let vc = segue.destinationViewController as? RadarViewController {
                    self.navigationItem.backBarButtonItem?.title = "完成"
                    vc.delegate = self
                    vc.searchCriteria = self.zuzuCriteria.criteria!
                }
            default: break
                
            }
        }
    }
}

// MARK: - RadarViewControllerDelegate
extension RadarDisplayViewController : RadarViewControllerDelegate {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria){
        ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(zuzuCriteria.userId!, criteriaId: zuzuCriteria.criteriaId!, criteria: searchCriteria) { (result, error) -> Void in
            if error != nil{
                //zuzualert
                return
            }
            
            self.zuzuCriteria.criteria = searchCriteria
            self.updateCriteriaTextLabel()
        }
    }
    
}
