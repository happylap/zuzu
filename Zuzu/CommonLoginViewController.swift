//
//  RadarPurchaseLoginViewController.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/15/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import UIKit

private let Log = Logger.defaultLogger

protocol CommonLoginViewDelegate {
    
    func onPerformSocialLogin(provider: Provider)
    
    func onPerformZuzuLogin(needRegister: Bool)
    
    func onCancelUserLogin()
    
    func onSkipUserLogin()
    
}

class CommonLoginViewController: UIViewController {
    
    // segue to configure UI
    
    struct ViewTransConst {
        static let displayLoginForm:String = "displayLoginForm"
        static let displayRegisterForm:String = "displayRegisterForm"
    }
    
    var delegate:CommonLoginViewDelegate?
    
    var loginMode:Int = 1
    
    var isOriginallyHideTabBar = true
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.lightGrayColor()
            
            cancelButton.addTarget(self, action: #selector(CommonLoginViewController.onCancelButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var userRegisterButton: UIButton! {
        
        didSet {
            userRegisterButton.layer.borderWidth = 2
            userRegisterButton.layer.borderColor = UIColor.colorWithRGB(0x12B3A6, alpha: 1).CGColor
            userRegisterButton.backgroundColor = UIColor.colorWithRGB(0x12B3A6, alpha: 1)
            
            userRegisterButton.tintColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            
            userRegisterButton.addTarget(self, action: #selector(CommonLoginViewController.onZuzuRegisterButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
        
    }
    
    @IBOutlet weak var userLoginButton: UIButton! {
        
        didSet {
            userLoginButton.layer.borderWidth = 2
            userLoginButton.layer.borderColor = UIColor.colorWithRGB(0x12B3A6, alpha: 1).CGColor
            userLoginButton.backgroundColor = UIColor.colorWithRGB(0x12B3A6, alpha: 1)
            userLoginButton.tintColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            
            userLoginButton.addTarget(self, action: #selector(CommonLoginViewController.onZuzuLoginButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
        
    }
    
    @IBOutlet weak var customLoginLabel: UILabel! {
        
        didSet {
            if(TagUtils.shouldAllowZuzuLogin()) {
                customLoginLabel.hidden = false
            } else {
                customLoginLabel.hidden = true
            }
        }
    }
    
    @IBOutlet weak var customLoginView: UIView! {
        
        didSet {
            
            if(TagUtils.shouldAllowZuzuLogin()) {
                customLoginView.hidden = false
                
                let thickness:CGFloat = 0.5
                
                let upperBorder = CALayer()
                upperBorder.backgroundColor = UIColor.whiteColor().CGColor
                
                upperBorder.frame = CGRect(x: 0, y: 0, width: customLoginView.frame.width, height: thickness)
                
                customLoginView.layer.addSublayer(upperBorder)
                
            } else {
                customLoginView.hidden = true
                customLoginView.removeFromSuperview()
                
            }
        }
        
    }
    
    @IBOutlet weak var privacyIconView: UIImageView! {
        didSet{
            privacyIconView.image = UIImage(named: "login_icon_privacy")?.imageWithRenderingMode(.AlwaysTemplate)
             privacyIconView.tintColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
        }
    }
    
    @IBOutlet weak var fbButton: UIButton!{
        didSet{
            
            fbButton.layer.borderWidth = 2
            fbButton.layer.borderColor = UIColor.colorWithRGB(0x4990E2, alpha: 1).CGColor
            
            fbButton.setImage(UIImage(named: "login_icon_facebook")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            fbButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            fbButton.imageEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 0)
            fbButton.tintColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            
            fbButton.backgroundColor = UIColor.colorWithRGB(0x4990E2, alpha: 1)
            fbButton.setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: .Normal)
            
            let shift = (fbButton.bounds.width / 4) - (25 + 12)
            fbButton.titleEdgeInsets = UIEdgeInsetsMake(0, shift, 0, 0)
            fbButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            
            fbButton.addTarget(self, action: #selector(CommonLoginViewController.onFBButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var googleButton: UIButton!{
        didSet{
            
            googleButton.layer.borderWidth = 2
            googleButton.layer.borderColor = UIColor.colorWithRGB(0xF3364C, alpha: 1).CGColor
            
            googleButton.setImage(UIImage(named: "login_icon_google")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            googleButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            googleButton.imageEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 0)
            googleButton.tintColor = UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            
            googleButton.backgroundColor = UIColor.colorWithRGB(0xF3364C, alpha: 1)
            googleButton.setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: .Normal)
            
            let shift = (googleButton.bounds.width / 4) - (25 + 12)
            googleButton.titleEdgeInsets = UIEdgeInsetsMake(0, shift, 0, 0)
            googleButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            
            googleButton.addTarget(self, action: #selector(CommonLoginViewController.onGoogleButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    // MARK: - Action Handler
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) onCancelButtonTouched")
        
        self.dismissViewControllerAnimated(true) {
            self.delegate?.onCancelUserLogin()
        }
    }
    
    func onFBButtonTouched(sender: UIButton) {
        Log.enter()
        
        self.dismissViewControllerAnimated(true) {
            self.delegate?.onPerformSocialLogin(.FB)
        }
    }
    
    func onGoogleButtonTouched(sender: UIButton) {
        Log.enter()
        
        self.dismissViewControllerAnimated(true) {
            self.delegate?.onPerformSocialLogin(.GOOGLE)
        }
        
    }
    
    func onZuzuLoginButtonTouched(sender: UIButton) {
        Log.enter()
        
        self.dismissViewControllerAnimated(true) {
            self.delegate?.onPerformZuzuLogin(false)
        }
        
    }
    
    func onZuzuRegisterButtonTouched(sender: UIButton) {
        Log.enter()
        
        self.dismissViewControllerAnimated(true) {
            self.delegate?.onPerformZuzuLogin(true)
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
        
        if let tabBar = self.presentingViewController?.tabBarController{
            self.isOriginallyHideTabBar = tabBar.tabBarHidden
            
            if isOriginallyHideTabBar == false{
                tabBar.tabBarHidden = true
            }
        }
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //self.maskView.hidden = true
        
        if let tabBar = self.presentingViewController?.tabBarController{
            tabBar.tabBarHidden = self.isOriginallyHideTabBar
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
                
            case ViewTransConst.displayLoginForm:
                if let vc = segue.destinationViewController as? FormViewController {
                    vc.formMode = .Login
                    
                }
                
            case ViewTransConst.displayRegisterForm:
                if let vc = segue.destinationViewController as? FormViewController {
                    vc.formMode = .Register
                    
                }
            default: break
                
            }
        }
    }
}