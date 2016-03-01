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
    
    var reach: Reachability?
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: NetworkStatus = reachability.currentReachabilityStatus()
        
        
        Log.debug("\(networkStatus.rawValue)")
        
        switch networkStatus {
        case NotReachable:
            Log.debug("[Network Status]: NotReachable")
            self.showRetryRadarView()
            return
        case ReachableViaWWAN:
            Log.debug("[Network Status]: ReachableViaWWAN")
        case ReachableViaWiFi:
            Log.debug("[Network Status]: ReachableViaWiFi")
        default:
            break
        }*/
  
        self.showCriteria()

    }

    // MARK: - show radar page
    
    func showCriteria(){
        Log.enter()
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.showConfigureRadarView()
            return
        }
        
        /*if UserDefaultsUtils.getZuzuUserId() == nil{
        self.showRetryRadarView()
        return
        }*/
        
        if let zuzuCriteria = RadarService.sharedInstance.zuzuCriteria{
            if zuzuCriteria.criteria != nil{
                self.showDisplayRadarView(zuzuCriteria)
            }else{
                self.showConfigureRadarView() // no criteria in DB
            }
        }else{
            self.showRetryRadarView() // error -> show retry
        }
        Log.exit()
    }
    
    func showConfigureRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
    func showDisplayRadarView(zuzuCriteria: ZuzuCriteria){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
            vc.zuzuCriteria = zuzuCriteria
            self.setViewControllers([vc], animated: false)
        }
    }
    
    func showRetryRadarView(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarRetryViewController") as? RadarRetryViewController {
            self.setViewControllers([vc], animated: false)
        }
    }
    
}
