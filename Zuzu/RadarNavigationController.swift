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
    
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showConfigureRadarView()
        }else{
            if let zuzuCriteria = RadarService.sharedInstance.zuzuCriteria{
                if zuzuCriteria.criteria != nil{
                    self.showDisplayRadarView()
                }else{
                    self.showConfigureRadarView() // no criteria in DB
                }
            }else{
                self.showRetryRadarView() // error -> show retry
            }
        }
    }


    // MARK: - show radar page
    
    private func showConfigureRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
    private func showDisplayRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
    private func showRetryRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
}
