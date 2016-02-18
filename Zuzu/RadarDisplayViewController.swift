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

    var zuzuCriteria: ZuzuCriteria?{
        didSet{
            self.searchCriteria = self.zuzuCriteria?.criteria
            self.updateServiceTextLabel()
        }
    }
    
    var searchCriteria: SearchCriteria?{
        didSet{
            updateCriteriaTextLabel()
        }
    }
    
    var purchaseHistotyTableDataSource = RadarPurchaseHistoryTableViewDataSource()
    
    var user: String?
    
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
        self.user = "test"
        self.configureButton()
        self.refreshCriteria()
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
        
        if self.user != nil && self.zuzuCriteria != nil{
            let isEnable = sender.on
            ZuzuWebService.sharedInstance.enableCriteriaByUserId(self.user!,
                criteriaId: self.zuzuCriteria!.criteriaId!, enabled: isEnable) { (result, error) -> Void in
                    if error != nil{
                        //zuzualert
                    }else{
                        self.zuzuCriteria!.enabled = isEnable
                    }
            }
        }
        else{
            //zuzualert
        }
    }
    
    private func updateCriteriaTextLabel(){
        if searchCriteria != nil{
            let displayItem = RadarDisplayItem(criteria:searchCriteria!)
            self.regionLabel?.text = displayItem.title
            self.houseInfoLabel?.text = displayItem.detail
            var filterNum = 0
            if let filterGroups = self.zuzuCriteria?.criteria?.filterGroups{
                filterNum = filterGroups.count
            }
            self.otherFiltersLabel?.text = "其他\(filterNum)個過濾條件"
        }
    }
    
    private func updateServiceTextLabel(){
        var diff = 0
        var expirDate = ""
        if let expireDate = self.zuzuCriteria?.expireTime{
            let now = NSDate()
            diff = now.daysFrom(expireDate)
            expirDate = CommonUtils.getStandardDateString(expireDate)
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
                    if let criteria = self.zuzuCriteria?.criteria{
                        vc.searchCriteria = criteria
                    }else{
                        vc.searchCriteria = SearchCriteria()
                    }
                }
            default: break
                
            }
        }
    }

    private func refreshCriteria(){
        if let user = self.user{
            ZuzuWebService.sharedInstance.getCriteriaByUserId(user) { (result, error) -> Void in
                if error != nil{
                    //zuzualert
                }else{
                    self.zuzuCriteria = result
                }
            }
        }
    }
}

// MARK: - RadarViewControllerDelegate
extension RadarDisplayViewController : RadarViewControllerDelegate {
    func onCriteriaSettingDone(searchCriteria:SearchCriteria){
        if let zuzuCriteria = self.zuzuCriteria{
            if let user = self.user{
                ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(user, criteriaId: zuzuCriteria.criteriaId!, criteria: searchCriteria) { (result, error) -> Void in
                    if error != nil{
                        //zuzualert
                    }else{
                        zuzuCriteria.criteria = searchCriteria
                        self.searchCriteria = searchCriteria
                    }
                }
            }
        }
    }
    
}
