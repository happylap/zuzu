//
//  RadarRetryViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

class RadarRetryViewController: UIViewController {
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleResetCriteria:", name: ResetCriteriaNotification, object: nil)
    }
    
    func handleResetCriteria(notification: NSNotification){
        Log.enter()
        if let zuzuCriteria = RadarService.sharedInstance.zuzuCriteria{
            NSNotificationCenter.defaultCenter().removeObserver(self)
            if zuzuCriteria.criteria != nil{
                if let vc = self.navigationController as? RadarNavigationController{
                    vc.showDisplayRadarView(zuzuCriteria)
                }
            }else{
                if let vc = self.navigationController as? RadarNavigationController{
                    vc.showConfigureRadarView()
                }
            }
        }
        
        Log.exit()
    }
}
