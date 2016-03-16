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
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true) // Use retry view as blank page
        self.showRadar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        Log.enter()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.enter()
    }
    
    
    // MARK: - Show radar page
    
    func showRadar(){
        Log.enter()
        
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showConfigureRadarView()
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            RadarService.sharedInstance.startLoading(self)
            
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                self.runOnMainThread(){
                    if error != nil{
                        RadarService.sharedInstance.stopLoading(self)
                        Log.error("Cannot get criteria by user id:\(userId)")
                        self.showRetryRadarView(false)
                        return
                    }
                    
                    if result != nil{
                        // don't need to stop loading here, the next view to show may keep loading
                        self.showDisplayRadarView(result!)
                    }else{
                        // no criteria
                        // don't need to stop loading here, the next view to show may keep loading
                        self.showConfigureRadarView()
                    }
                }
            }
        }else{
            assert(false, "user id should not be nil")
        }
        
        Log.exit()
    }
    
    func showConfigureRadarView(){
        Log.enter()
        
        if self.viewControllers.count > 0 {
            if let _ = self.viewControllers[0] as? RadarViewController {
                Log.exit()
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            vc.navigationView = self
            self.setViewControllers([vc], animated: false)
        }
        
        Log.exit()
    }
    
    func showDisplayRadarView(zuzuCriteria: ZuzuCriteria){
        Log.enter()
        
        if self.viewControllers.count > 0 {
            if let _ = self.viewControllers[0] as? RadarDisplayViewController {
                Log.exit()
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            vc.navigationView = self
            vc.zuzuCriteria = zuzuCriteria
            self.setViewControllers([vc], animated: false)
        }
        Log.exit()
    }
    
    func showRetryRadarView(isBlank: Bool){
        Log.enter()
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            vc.navigationView = self
            vc.isBlank = isBlank
            self.setViewControllers([vc], animated: false)
        }
        
        Log.exit()
    }
}


