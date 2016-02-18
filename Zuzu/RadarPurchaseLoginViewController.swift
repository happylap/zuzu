//
//  RadarPurchaseLoginViewController.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/15/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import UIKit

private let Log = Logger.defaultLogger

class RadarPurchaseLoginViewController: UIViewController {
    
    var cancelHandler: (() -> Void)?
    var fbLoginHandler: (() -> Void)?
    var googleLoginHandler: (() -> Void)?
    
    var loginMode: Int = 1
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            /*cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()*/
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var titleText: UILabel!
    
    @IBOutlet weak var subTitleText: UILabel!
    
    @IBOutlet weak var fbButton: UIButton!{
        didSet{
            fbButton.addTarget(self, action: "onFBButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var googleButton: UIButton!{
        didSet{
            googleButton.addTarget(self, action: "onGoogleButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        view.opaque = false
        
        fbButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        fbButton.setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: .Normal)
        fbButton.layer.cornerRadius = CGFloat(5.0)
        
        googleButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        googleButton.setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: .Normal)
        googleButton.layer.cornerRadius = CGFloat(5.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        maskView.hidden = true
        
        if loginMode == 1 {
            titleText.text = "請選擇登入方式"
            subTitleText.text = "使用我的收藏功能，需要您選擇下列一種帳戶登入，日後更換裝置，收藏的物件才不會消失喔！\n\n豬豬快租絕不會以您的身份發佈任何資訊"
        } else if loginMode == 2 {
            titleText.text = "登入個人帳號"
            subTitleText.text = "請您使用下列帳號登入，豬豬快租便能為您提供個人專屬的通知服務"
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.maskView.alpha = 0.0
        self.maskView.hidden = false
        UIView.animateWithDuration(0.5, animations: {
            self.maskView.alpha = 0.3
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        maskView.hidden = true
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
