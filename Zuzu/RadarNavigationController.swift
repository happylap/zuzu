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
    
    var zuzuCriteria: ZuzuCriteria?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true) // Use retry view as blank page
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.enter()
        self.showRadar() // call show radar whenever appear to decide will view should be presented
        super.viewWillAppear(animated)
        Log.exit()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Log.debug("viewDidAppear")
    }
    
    
    // MARK: - Show radar page
    
    func showRadar(onCompleteHandler: (() -> Void)? = nil){
        Log.enter()
        
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showConfigureRadarView(onCompleteHandler)
            RadarService.sharedInstance.stopLoading(self)
            return
        }
        
        if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
            
            RadarService.sharedInstance.startLoading(self)
            
            UserServiceStatusManager.shared.getRadarServiceStatusByUserId(userId){
                
                (result, success) -> Void in

                if success == false{
                    Log.error("Cannot get Zuzu service by user id:\(userId)")
                    self.showRetryRadarView(false, onCompleteHandler: onCompleteHandler)
                    //stop loading if it goes to retry page
                    RadarService.sharedInstance.stopLoading(self)
                    return
                }
                
                
                if let zuzuService = result, _ = zuzuService.status, _ = zuzuService.expireTime{
 
                    if let criteria = self.zuzuCriteria, _ = criteria.criteriaId {
                        self.showDisplayRadarView(zuzuService, zuzuCriteria: self.zuzuCriteria!, onCompleteHandler:onCompleteHandler)
                        RadarService.sharedInstance.stopLoading(self)
                        return
                    }
                    
                    ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) {
                        (result, error) -> Void in
                        
                        if error != nil{
                            Log.error("Cannot get criteria by user id:\(userId)")
                            self.showRetryRadarView(false, onCompleteHandler:onCompleteHandler)
                            //stop loading if it goes to retry page
                            RadarService.sharedInstance.stopLoading(self)
                            return
                        }
                        
                        
                        if result == nil{
                            // deliver emptry criteria to display
                            // In display UI, it will tell users that they have not configured any criteria
                            self.zuzuCriteria = result
                            self.showDisplayRadarView(zuzuService, zuzuCriteria: ZuzuCriteria(), onCompleteHandler:onCompleteHandler)
                        }else{
                            self.zuzuCriteria = result
                            self.showDisplayRadarView(zuzuService, zuzuCriteria: result!, onCompleteHandler:onCompleteHandler)
                        }
                        
                        RadarService.sharedInstance.stopLoading(self)
                    }
                    
                }else{
                    Log.debug("No purchased service. This user has not purchased any service")
                    self.showConfigureRadarView(onCompleteHandler)
                    RadarService.sharedInstance.stopLoading(self)
                    return
                }
            }
            
        }else{
            RadarService.sharedInstance.stopLoading(self)
            assert(false, "user id should not be nil")
        }
        
        Log.exit()
    }
    
    private func showConfigureRadarView(onCompleteHandler: (() -> Void)? = nil){
        Log.enter()
        
        if self.viewControllers.count > 0 {
            if let _ = self.viewControllers[0] as? RadarViewController {
                onCompleteHandler?()
                Log.exit()
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            self.setViewControllers([vc], animated: true)
            onCompleteHandler?()
        }
        
        Log.exit()
    }
    
    private func showDisplayRadarView(zuzuService: ZuzuServiceMapper, zuzuCriteria: ZuzuCriteria, onCompleteHandler: (() -> Void)? = nil){
        Log.enter()
        
        if self.viewControllers.count > 0 {
            if let vc = self.viewControllers[0] as? RadarDisplayViewController {
                vc.zuzuCriteria = zuzuCriteria
                vc.zuzuService = zuzuService
                onCompleteHandler?()
                Log.exit()
                return
            }
        }
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            vc.zuzuCriteria = zuzuCriteria
            vc.zuzuService = zuzuService
            self.setViewControllers([vc], animated: true)
            onCompleteHandler?()
        }
        Log.exit()
    }
    
    private func showRetryRadarView(isBlank: Bool, onCompleteHandler: (() -> Void)? = nil){
        Log.enter()
        
        // initialize rety page every time
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            vc.navigationView = self
            vc.isBlank = isBlank
            self.setViewControllers([vc], animated: true)
        }
        
        onCompleteHandler?()
        
        Log.exit()
    }
}


