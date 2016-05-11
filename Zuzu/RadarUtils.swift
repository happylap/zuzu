//
//  RadarUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/5/3.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SCLAlertView

private let Log = Logger.defaultLogger

class RadarUtils : NSObject{
    
    class var shared: RadarUtils {
        struct Static {
            static let instance = RadarUtils()
        }
        return Static.instance
    }
    
    
    private var currentTimer: NSTimer?
    
    internal func promptAuthLocalNotification(onContinue: () -> Void) {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "要使用「租屋雷達」接收新物件通知，需要您授權接收通知\n\n請在點擊「繼續」後，允許豬豬快豬的通知權限請求"
        
        alertView.showCloseButton = false
        
        alertView.addButton("繼續") {
            
            onContinue()
            
        }
        
        alertView.showInfo("請授權接收通知", subTitle: subTitle, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
    }
    
    internal func alertLocalNotificationDisabled(title: String = "尚未授權顯示通知") {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "您尚未授權「豬豬快租」顯示通知，請按照下面步驟開啟：\n\n" +
            "進入：設定 > 通知 > 豬豬快租\n" +
            "\n• 確認開啟「允許通知」" +
            "\n• 確認開啟「通知聲」" +
            "\n• 確認開啟「App標記」" +
            "\n• 確認提示樣式為「橫幅顯示」" +
        "\n\n完成設定後，重新進入「租屋雷達」，確認本訊息不再出現"
        
        alertView.showCloseButton = true
        
        alertView.showInfo(title, subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func alertRegisterSuccess() {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "註冊成功"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("遠端推播已經註冊成功，租屋雷達現在可以向您推播即時通知", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
    }
    
    internal func alertPushNotificationDisabled(title: String = "尚未註冊遠端推播",
                                                onSuccess: (()-> Void)? = nil, onFailure: (()-> Void)? = nil) {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        let subTitle = "請先確認網路連線正常後，參考下面步驟註冊推播服務以使用「租屋雷達」：\n" +
            "\n• 點選「註冊遠端推播」按鈕" +
            "\n• 雙擊Home鍵開啟工作清單" +
            "\n• 將「豬豬快租」上滑完全關閉" +
            "\n• 重新進入「租屋雷達」" +
        "\n\n若本訊息持續出現，請聯繫粉絲團客服協助排除"
        
        alertView.showCloseButton = true
        
        alertView.addButton("註冊遠端推播") {
            
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                
                let loadingSpinner = LoadingSpinner.getInstance("enablePushNotification")
                loadingSpinner.setGraceTime(0.6)
                loadingSpinner.setMinShowTime(1)
                loadingSpinner.setOpacity(0.6)
                loadingSpinner.setText("註冊中")
                
                if let windowView = appDelegate.window?.rootViewController?.view {
                    loadingSpinner.startOnView(windowView)
                }
                
                appDelegate.setupPushNotifications({ (result) in
                    if(!result) {
                        self.currentTimer?.invalidate()
                        LoadingSpinner.getInstance("enablePushNotification").stop()
                        /// Check remote notification registered
                        
                        if(!appDelegate.isPushNotificationRegistered()) {
                            
                            self.alertPushNotificationDisabled()
                            //onFailure?()
                            
                        } else {
                            
                            self.alertRegisterSuccess()
                            //onSuccess?()
                            
                        }
                    }
                })
                
                /// Setup a timer to do the checking
                self.currentTimer?.invalidate()
                
                self.currentTimer =
                    NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(RadarUtils.onRegisterPushNotificationTimeout(_:)), userInfo: nil, repeats: false)
            }
        }
        
        alertView.showInfo(title, subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    
    func onRegisterPushNotificationTimeout(timer:NSTimer) {
        LoadingSpinner.getInstance("enablePushNotification").stop()
        
        /// Check remote notification registered
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            if(!appDelegate.isPushNotificationRegistered()) {
                
                self.alertPushNotificationDisabled()
                
            }
        }
    }
    
}
