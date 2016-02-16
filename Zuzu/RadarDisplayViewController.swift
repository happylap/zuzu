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

    var zuzuCriteria: ZuzuCriteria?
    var user: String?
    
    struct ViewTransConst {
        static let showConfigureRadar:String = "showConfigureRadar"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.user = "test"
        self.configureButton()
        self.refreshCriteria()
        // Do any additional setup after loading the view.
    }

    @IBAction func enableCriteria(sender: UISwitch) {
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
                    }
                }
            }
        }
    }
    
}
