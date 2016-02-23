//
//  RadarNavigationController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/22.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

class RadarNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showConfigureRadarView()
        }else{
            self.refreshCriteria()
        }
        
    }
    

    // MARK: - refresh criteria
    
    private func refreshCriteria(){
        if let user = AmazonClientManager.sharedInstance.userLoginData?.id{
            ZuzuWebService.sharedInstance.getCriteriaByUserId(user) { (result, error) -> Void in
                if error != nil{
                    self.alertRefreshError()
                    return
                }
                
                if result != nil{
                    self.showDisplayRadarView()
                }else{
                    self.showConfigureRadarView()
                }
            }
        }else{
            self.alertRefreshError()
        }
    }
    
    private func alertRefreshError() {
        
        /*let alertView = SCLAlertView()
        
        let subTitle = "目前無法為您取得租屋雷達!可能是您所處區域的網路環境不穩定或是手機無線網路被關閉了"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("連線失敗", subTitle: subTitle, closeButtonTitle: "知道了", duration: 2.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)*/
        
        self.showRetryRadarView()
        self.popViewControllerAnimated(true)
        self.showConfigureRadarView()
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - show radar page
    
    private func showConfigureRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            self.showViewController(vc, sender: self)
        }
    }
    
    private func showDisplayRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            self.showViewController(vc, sender: self)
        }
    }
    
    private func showRetryRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            self.showViewController(vc, sender: self)
        }
    }
    
}
