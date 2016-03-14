//
//  RadarNavigationController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/22.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView
import MBProgressHUD

private let Log = Logger.defaultLogger


class RadarNavigationController: UINavigationController {
    
    var zuzuCriteria: ZuzuCriteria? //cache the acquired criteria
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true) // Use retry view as blank page
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.showRadar()
    }
    
    // MARK: - show radar page
    
    func showRadar(handler: (() -> Void)? = nil){
        Log.enter()

        if AmazonClientManager.sharedInstance.isLoggedIn(){
            if self.zuzuCriteria != nil{
                self.showDisplayRadarView(self.zuzuCriteria!)
                if handler != nil{
                    handler!()
                }
                Log.exit()
                return
            }
            
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                
                RadarService.sharedInstance.startLoading(self)
                
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                    self.runOnMainThread(){
                        if error != nil{
                            Log.error("Cannot get criteria by user id:\(userId)")
                            self.showRetryRadarView(false)
                            if handler != nil{
                                handler!()
                            }
                            return
                        }
                        
                        if result != nil{
                            self.zuzuCriteria = result
                            self.showDisplayRadarView(self.zuzuCriteria!)
                            if handler != nil{
                                handler!()
                            }
                        }else{
                             // no criteria
                            self.showConfigureRadarView()
                            if handler != nil{
                                handler!()
                            }
                        }
                    }
                }
            }
        }
        else{
            self.zuzuCriteria = nil
            self.showConfigureRadarView()
            if handler != nil{
                handler!()
            }
        }
        
        Log.exit()
    }
    
    func showConfigureRadarView(){
        if self.viewControllers.count > 0 {
            let vc = self.viewControllers[0] as? RadarViewController
            if vc != nil{
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
    func showDisplayRadarView(zuzuCriteria: ZuzuCriteria){
        if self.viewControllers.count > 0 {
            let vc = self.viewControllers[0] as? RadarDisplayViewController
            if vc != nil{
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            vc.zuzuCriteria = zuzuCriteria
            self.setViewControllers([vc], animated: false)
        }
    }
    
    func showRetryRadarView(isBlank: Bool){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            vc.isBlank = isBlank
            self.setViewControllers([vc], animated: false)
            RadarService.sharedInstance.stopLoading(self)
        }
    }
}


