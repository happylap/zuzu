//
//  RadarDiagnosisViewController.swift
//  Zuzu
//
//  Copyright © 2016 LAP Inc. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

class RadarDiagnosisViewController: UIViewController {
    
    private let enbledButtonColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
    
    private let statusOkImage = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
    
    private let statusErrorImage = UIImage(named: "comment-alert-outline")?.imageWithRenderingMode(.AlwaysTemplate)
    
    private let localNotificationEnabledMessage = "已經授權「豬豬快租」顯示通知"
    
    private let localNotificationDisabledMessage = "您尚未允許「豬豬快租」顯示通知"
    
    private let pushNotificationEnabledMessage = "已經成功註冊此裝置接收遠端推播服務"
    
    private let pushNotificationDisabledMessage = "此裝置尚無法接收推播訊息"
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: #selector(RadarDiagnosisViewController.onCancelButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    
    @IBOutlet weak var localNotificationIcon: UIImageView! {
        
        didSet {
            localNotificationIcon.image = statusOkImage
        }
    }
    
    @IBOutlet weak var localNotificationTitle: UILabel!
    
    
    @IBOutlet weak var localNotificationFixButton: UIButton! {
        didSet {
            localNotificationFixButton.hidden = true
            localNotificationFixButton.enabled = true
            localNotificationFixButton.tintColor = enbledButtonColor
            localNotificationFixButton.setTitleColor(enbledButtonColor, forState: .Normal)
            
            localNotificationFixButton.addTarget(self, action: #selector(RadarDiagnosisViewController.onFixLocalNotificationButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    @IBOutlet weak var localNotificationMessage: UILabel! {
        
        didSet {
            
            let thickness:CGFloat = 0.5
            
            let bottomBorder = CALayer()
            bottomBorder.backgroundColor = UIColor.lightGrayColor().CGColor
            
            bottomBorder.frame = CGRect(x: 0, y: localNotificationMessage.frame.height + 8, width: localNotificationMessage.frame.width, height: thickness)
            
            localNotificationMessage.layer.addSublayer(bottomBorder)
        }
        
    }
    
    @IBOutlet weak var pushNotificationIcon: UIImageView! {
        
        didSet {
            pushNotificationIcon.image = statusOkImage
        }
    }
    
    @IBOutlet weak var pushNotificationTitle: UILabel!
    
    
    @IBOutlet weak var pushNotificationFixButton: UIButton! {
        didSet {
            pushNotificationFixButton.enabled = true
            pushNotificationFixButton.tintColor = enbledButtonColor
            pushNotificationFixButton.setTitleColor(enbledButtonColor, forState: .Normal)
            
            pushNotificationFixButton.addTarget(self, action: #selector(RadarDiagnosisViewController.onFixPushNotificationButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var pushNotificationMessage: UILabel! {
        didSet {
            
            let thickness:CGFloat = 0.5
            
            let bottomBorder = CALayer()
            bottomBorder.backgroundColor = UIColor.lightGrayColor().CGColor
            
            bottomBorder.frame = CGRect(x: 0, y: pushNotificationMessage.frame.height + 8, width: pushNotificationMessage.frame.width, height: thickness)
        }
    }
    
    @IBOutlet weak var lastSavedDeviceToken: UILabel!
    
    // MARK: - Private Util
    
    private func handleLocalNotificationEnabled() {
        localNotificationFixButton.hidden = true
        
        var notificationType = ""
        
        if let grantedSettings = UIApplication.sharedApplication().currentUserNotificationSettings(){
            
            if(grantedSettings.types.contains(.Alert)) {
                
                notificationType = "橫幅"
            }
            
            if(grantedSettings.types.contains(.Badge)) {
                
                notificationType = notificationType + ", 標記"
            }
            
            if(grantedSettings.types.contains(.Sound)) {
                
                notificationType = notificationType + ", 提示聲"
            }
        }
        
        self.localNotificationMessage.text = self.localNotificationEnabledMessage + ": " + notificationType
        self.localNotificationIcon.image = statusOkImage
        self.localNotificationIcon.tintColor = UIColor.colorWithRGB(0x1CD4C6)
    }
    
    private func handleLocalNotificationDisabled() {
        self.localNotificationFixButton.hidden = false
        self.localNotificationFixButton.enabled = true
        self.localNotificationFixButton.tintColor = enbledButtonColor
        self.localNotificationFixButton.setTitleColor(enbledButtonColor, forState: .Normal)
        
        self.localNotificationMessage.text = self.localNotificationDisabledMessage
        self.localNotificationIcon.image = statusErrorImage
        self.localNotificationIcon.tintColor = UIColor.colorWithRGB(0xFF6666)
    }
    
    private func handlePushNotificationEnable() {
        self.pushNotificationFixButton.hidden = true
        
        self.pushNotificationIcon.image = statusOkImage
        self.pushNotificationIcon.tintColor = UIColor.colorWithRGB(0x1CD4C6)
        
        self.pushNotificationMessage.text = self.pushNotificationEnabledMessage
        
        if let deviceToken = UserDefaultsUtils.getAPNDevicetoken() {
            
            self.lastSavedDeviceToken.text = "上次獲取代碼:\(deviceToken)"
            
        } else {
            
            self.lastSavedDeviceToken.text = "上次獲取代碼:−"
            
        }
    }
    
    private func handlePushNotificationDisabled() {
        self.pushNotificationFixButton.enabled = true
        self.pushNotificationFixButton.tintColor = enbledButtonColor
        self.pushNotificationFixButton.setTitleColor(enbledButtonColor, forState: .Normal)
        
        self.pushNotificationMessage.text = self.pushNotificationDisabledMessage
        self.pushNotificationIcon.image = statusErrorImage
        self.pushNotificationIcon.tintColor = UIColor.colorWithRGB(0xFF6666)
        
        if let deviceToken = UserDefaultsUtils.getAPNDevicetoken() {

            self.lastSavedDeviceToken.text = "上次獲取代碼:\(deviceToken)"
            
        } else {
            
            self.lastSavedDeviceToken.text = "上次獲取代碼:−"
            
        }
    }
    
    private func setPushNotificationMessageVisible(visible: Bool) {
        self.lastSavedDeviceToken.hidden = !visible
        self.pushNotificationIcon.hidden = !visible
        self.pushNotificationTitle.hidden = !visible
        self.pushNotificationFixButton.hidden = !visible
        self.pushNotificationMessage.hidden = !visible
    }
    
    // MARK: - Action Handlers
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.enter()
        
        self.dismissViewControllerAnimated(true){
            
        }
    }
    
    func onFixLocalNotificationButtonTouched(sender: UIButton) {
        Log.enter()
        
        RadarUtils.shared.alertLocalNotificationDisabled("通知顯示開啟方式")
    }
    
    func onFixPushNotificationButtonTouched(sender: UIButton) {
        Log.enter()
        
        RadarUtils.shared.alertPushNotificationDisabled("推播服務修復方式")
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setPushNotificationMessageVisible(false)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            
            /// Local Notification Enabled
            if(appDelegate.isLocalNotificationEnabled()) {
                
                self.handleLocalNotificationEnabled()
                
                self.setPushNotificationMessageVisible(true)
                
                /// Push Notification
                if(appDelegate.isPushNotificationRegistered()) {
                    
                    self.handlePushNotificationEnable()
                    
                } else {
                    
                    self.handlePushNotificationDisabled()
                    
                }
                
            } else {
                /// Local Notification Disabled
                self.handleLocalNotificationDisabled()

            }
            
        }else{
            assert(false, "appDelegate cannot be nil")
            Log.error("appDelegate is nil")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.presentingViewController?.tabBarController?.tabBarHidden = false
    }
}
