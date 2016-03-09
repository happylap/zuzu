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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            self.alertUnfinishError()
        }
        
    }
    
    // MARK: - alert
    
    func alertUnfinishError(){
        let msgTitle = "重新交易失敗"
        let okButton = "知道了"
        let subTitle = "很抱歉！交易無法成功，請重新再試！"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
            
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
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

class ZuzuCriteriaPurchaseHandler: NSObject, ZuzuStorePurchaseHandler{
    
    func onPurchased(store: ZuzuStore, transaction: SKPaymentTransaction){
        
    }
    
    func onFailed(store: ZuzuStore, transaction: SKPaymentTransaction){
        
    }
}

