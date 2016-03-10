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
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        /*let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
        self.alertUnfinishError()
        }*/
        
        self.showRadar()
    }
    
    // MARK: - alert
    
    func alertLoginForUnfinish(){
        let loginAlertView = SCLAlertView()
        loginAlertView.showCloseButton = false
        
        loginAlertView.addButton("Facebook帳號登入") {
            AmazonClientManager.sharedInstance.fbLogin(self)
        }
        
        loginAlertView.addButton("Google帳號登入") {
            AmazonClientManager.sharedInstance.googleLogin(self)
        }

        let subTitle = "之前購買的雷達尚未完成設定"
        loginAlertView.showNotice("登入", subTitle: subTitle, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
        loginAlertView.showNotice(NSLocalizedString("login.title", comment: ""),
        subTitle: NSLocalizedString("login.body", comment: ""), colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
    }
    
    func alertUnfinishError(){
        let msgTitle = "重新交易失敗"
        let okButton = "知道了"
        let subTitle = "很抱歉！交易無法成功，請重新再試！"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
            
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    
    //
    func startLoading(){
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.view)
    }
    
    func stopLoading(){
        LoadingSpinner.shared.stop()
    }
    
    // MARK: - show radar page
    
    func showRadar(){
        Log.enter()
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            if self.zuzuCriteria != nil{
                self.showDisplayRadarView(self.zuzuCriteria!)
                Log.exit()
                return
            }
            
            if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id{
                self.startLoading()
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                    if error != nil{
                        Log.error("Cannot get criteria by user id:\(userId)")
                        self.stopLoading()
                        self.showRetryRadarView(false)
                        return
                    }
                    if result != nil{
                        self.zuzuCriteria = result
                        self.stopLoading()
                        self.showDisplayRadarView(self.zuzuCriteria!)
                    }else{
                        self.stopLoading() // no criteria
                        self.stopLoading()
                        self.showConfigureRadarView()
                    }
                }
            }
        }
        else{
            self.zuzuCriteria = nil
            self.showConfigureRadarView()
        }
        
        Log.exit()
    }
    
    func showConfigureRadarView(){
        if self.viewControllers.count > 0 {
            if let vc = self.viewControllers[0] as? RadarViewController{
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
            if let vc = self.viewControllers[0] as? RadarDisplayViewController{
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
        }
    }
    
}

class ZuzuCriteriaPurchaseHandler: NSObject, ZuzuStorePurchaseHandler{
    
    func onPurchased(store: ZuzuStore, transaction: SKPaymentTransaction){
        
    }
    
    func onFailed(store: ZuzuStore, transaction: SKPaymentTransaction){
        
    }
}

