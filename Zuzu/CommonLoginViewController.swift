//
//  RadarPurchaseLoginViewController.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/15/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import UIKit

private let Log = Logger.defaultLogger

class CommonLoginViewController: UIViewController {
    
    var cancelHandler: (() -> Void)?
    var fbLoginHandler: (() -> Void)?
    var googleLoginHandler: (() -> Void)?
    
    var loginMode: Int = 1
    
    var isOriginallyHideTabBar = true
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var titleText: UILabel!
    
    @IBOutlet weak var subTitleText: UILabel!
    
    @IBOutlet weak var faceImageView: UIImageView! {
        didSet{
            faceImageView.image = UIImage(named: "lock_icon")?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }
    
    @IBOutlet weak var fbButton: UIButton!{
        didSet{
            
            fbButton.layer.borderWidth = 2
            fbButton.layer.borderColor =
                UIColor.colorWithRGB(0x4990E2, alpha: 1).CGColor
            
            fbButton.setImage(UIImage(named: "facebook_icon")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            fbButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            
            fbButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 0)
            
            fbButton.tintColor =
                UIColor.colorWithRGB(0x4990E2, alpha: 1)
            
            //fbButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            fbButton.setTitleColor(UIColor.colorWithRGB(0x4990E2, alpha: 1), forState: .Normal)
            fbButton.layer.cornerRadius = CGFloat(5.0)
            
            fbButton.addTarget(self, action: "onFBButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var googleButton: UIButton!{
        didSet{
            
            googleButton.layer.borderWidth = 2
            googleButton.layer.borderColor =
                UIColor.colorWithRGB(0xF3364C, alpha: 1).CGColor
            
            googleButton.setImage(UIImage(named: "google_icon")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            googleButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            googleButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
            
            googleButton.tintColor =
                UIColor.colorWithRGB(0xF3364C, alpha: 1)
            
            //googleButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            googleButton.setTitleColor(UIColor.colorWithRGB(0xF3364C, alpha: 1), forState: .Normal)
            googleButton.layer.cornerRadius = CGFloat(5.0)
            
            googleButton.addTarget(self, action: "onGoogleButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        view.opaque = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loginMode == 1 {
            titleText.text = "登入使用我的收藏"
            subTitleText.text = "請登入使用我的收藏功能，日後更換裝置，收藏的物件才不會消失喔！"
        } else if loginMode == 2 {
            titleText.text = "登入使用租屋雷達"
            subTitleText.text = "請您使用下列帳號登入，豬豬快租便能為您提供個人專屬的通知服務"
        } else if loginMode == 3 {
            titleText.text = "登入個人帳號"
            subTitleText.text = "偵測到購買的租屋雷達尚未完成設定，\n請您使用下列帳號登入，\n豬豬快租便能為您完成設定"
        }
        
        self.maskView.alpha = 0.0
        self.maskView.hidden = false
        
        if let tabBar = self.presentingViewController?.tabBarController{
            self.isOriginallyHideTabBar = tabBar.tabBarHidden
            
            if isOriginallyHideTabBar == false{
                tabBar.tabBarHidden = true
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.5, animations: {
            self.maskView.alpha = 0.3
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.maskView.hidden = true
        
        if let tabBar = self.presentingViewController?.tabBarController{
            tabBar.tabBarHidden = self.isOriginallyHideTabBar
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Private Util
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) onCancelButtonTouched")

        dismissViewControllerAnimated(true, completion: self.cancelHandler)
    }
    
    func onFBButtonTouched(sender: UIButton) {
        Log.debug("\(self) onFBButtonTouched")
        dismissViewControllerAnimated(true, completion: self.fbLoginHandler)
    }
    
    func onGoogleButtonTouched(sender: UIButton) {
        Log.debug("\(self) onGoogleButtonTouched")
        dismissViewControllerAnimated(true, completion: self.googleLoginHandler)
    }
}
