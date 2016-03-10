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
    
    var zuzuCriteria: ZuzuCriteria?
    
    var unfinishedTranscations: [SKPaymentTransaction]?
    
    var porcessTransactionNum = -1
    
    // MARK: - view life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showRetryRadarView(true)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            if AmazonClientManager.sharedInstance.isLoggedIn(){
                self.doUnfinishTransactions(unfinishedTranscations)
            }else{
                self.showConfigureRadarView()
            }
        }else{
            self.showRadar()
        }
    }
    
    // MARK: finishTransactions
    
    func doUnfinishTransactions(unfinishedTranscations:[SKPaymentTransaction]){
        self.unfinishedTranscations = unfinishedTranscations
        self.porcessTransactionNum = 0
        self.startLoadingText("重新設定租屋雷達服務...")
        self.performFinishTransactions()
    }
    
    func performFinishTransactions(){
        if let transactions = self.unfinishedTranscations{
            if self.porcessTransactionNum  < transactions.count{
                RadarService.sharedInstance.createPurchase(transactions[self.porcessTransactionNum], handler: self.handleCompleteTransaction)
            }
        }else{
            self.transactionDone()
            self.showRadar()
        }
    }
    
    func handleCompleteTransaction(result: String?, error: NSError?) -> Void{
        if error != nil{
            self.transactionDone()
            self.alertUnfinishError()
            return
        }
        
        self.porcessTransactionNum = self.porcessTransactionNum + 1
        if let transactions = self.unfinishedTranscations{
            if self.porcessTransactionNum  < transactions.count{
                self.performFinishTransactions()
                return
            }
        }
        
        self.transactionDone()
        self.showRadar()
    }
    
    func transactionDone(){
        self.unfinishedTranscations = nil
        self.porcessTransactionNum = -1
        self.stopLoadingText()
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
    
    // MARK: - alert
    
    func alertUnfinishError(){
        let msgTitle = "重新設定租屋雷達服務失敗"
        let okButton = "知道了"
        let subTitle = "很抱歉！設定租屋雷達服務無法成功！"
        let alertView = SCLAlertView()
        alertView.showCloseButton = false
        
        alertView.addButton("重新再試") {
            let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
            if unfinishedTranscations.count > 0{
                if AmazonClientManager.sharedInstance.isLoggedIn(){
                    self.doUnfinishTransactions(unfinishedTranscations)
                }
            }
        }
        
        alertView.addButton("取消") {
            self.showConfigureRadarView()
        }
        
        alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    // Loading
    
    func startLoading(){
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(self.view)
    }
    
    func stopLoading(){
        LoadingSpinner.shared.stop()
    }
    
    func startLoadingText(text: String){
        let dialog = MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        dialog.animationType = .ZoomIn
        dialog.dimBackground = true
        dialog.labelText = text
        
        self.runOnMainThread() { () -> Void in}
    }
    
    func stopLoadingText(){
        MBProgressHUD.hideHUDForView(self.view, animated: true)
    }
}


