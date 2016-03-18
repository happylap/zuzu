//
//  RadarNavigationController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/22.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger


class RadarNavigationController: UINavigationController {
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true) // Use retry view as blank page
        self.showRadar()
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.enter()
        self.showRadar() // call show radar whenever appear to decide will view should be presented
        super.viewWillAppear(animated)
        Log.exit()
    }
    
    override func viewDidAppear(animated: Bool) {
        Log.enter()
        self.showRadar() // decide which view to show
        super.viewDidAppear(animated)
        Log.exit()
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
            
            ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                (result, error) ->Void in
                
                if error != nil{
                    Log.error("Cannot get Zuzu service by user id:\(userId)")
                    self.showRetryRadarView(false)
                    //stop loading if it goes to retry page
                    RadarService.sharedInstance.stopLoading(self)
                    return
                }
                
                if result == nil{
                    Log.debug("No purchased service. This user has not purchased any service")
                    self.showConfigureRadarView()
                    RadarService.sharedInstance.stopLoading(self)
                    return
                }
                
                let zuzuService = result!
                
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) {
                    (result, error) -> Void in
                    
                    if error != nil{
                        Log.error("Cannot get criteria by user id:\(userId)")
                        self.showRetryRadarView(false)
                        //stop loading if it goes to retry page
                        RadarService.sharedInstance.stopLoading(self)
                        return
                    }
                    
                    if result == nil{
                        // deliver emptry criteria to display
                        // In display UI, it will tell users that they have not configured any criteria
                        self.showDisplayRadarView(zuzuService, zuzuCriteria: ZuzuCriteria())
                    }else{
                        self.showDisplayRadarView(zuzuService, zuzuCriteria: result!)
                    }
                    
                    RadarService.sharedInstance.stopLoading(self)
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
    
    func showDisplayRadarView(zuzuService: ZuzuServiceMapper, zuzuCriteria: ZuzuCriteria){
        Log.enter()
        
        if self.viewControllers.count > 0 {
            if let vc = self.viewControllers[0] as? RadarDisplayViewController {
                vc.zuzuCriteria = zuzuCriteria
                vc.zuzuService = zuzuService
                Log.exit()
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            vc.zuzuCriteria = zuzuCriteria
            vc.zuzuService = zuzuService
            self.setViewControllers([vc], animated: false)
        }
        Log.exit()
    }
    
    func showRetryRadarView(isBlank: Bool){
        Log.enter()
        
        // initialize rety page every time
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            vc.navigationView = self
            vc.isBlank = isBlank
            self.setViewControllers([vc], animated: false)
        }
        
        Log.exit()
    }
}


