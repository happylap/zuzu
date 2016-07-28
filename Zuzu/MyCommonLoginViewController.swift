//
//  RadarPurchaseLoginViewController.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/15/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import UIKit

private let Log = Logger.defaultLogger

class MyCommonLoginViewController: UIViewController {

    // segue to configure UI

    struct ViewTransConst {
        static let displayLoginForm: String = "displayLoginForm"
        static let displayRegisterForm: String = "displayRegisterForm"
    }

    var delegate: CommonLoginViewDelegate?

    var loginMode: Int = 1

    var allowSkip = false

    var isOriginallyHideTabBar = true

    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()

            cancelButton.addTarget(self, action: #selector(MyCommonLoginViewController.onCancelButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }

    @IBOutlet weak var userRegisterButton: UIButton! {

        didSet {
            userRegisterButton.layer.borderWidth = 2
            userRegisterButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            userRegisterButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)

            userRegisterButton.addTarget(self, action: #selector(MyCommonLoginViewController.onZuzuRegisterButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }

    }

    @IBOutlet weak var userLoginButton: UIButton! {

        didSet {
            userLoginButton.layer.borderWidth = 2
            userLoginButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            userLoginButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)

            userLoginButton.addTarget(self, action: #selector(MyCommonLoginViewController.onZuzuLoginButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
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

                let thickness: CGFloat = 0.5

                let upperBorder = CALayer()
                upperBorder.backgroundColor = UIColor.lightGrayColor().CGColor

                upperBorder.frame = CGRect(x: 0, y: 0, width: customLoginView.frame.width, height: thickness)

                customLoginView.layer.addSublayer(upperBorder)

            } else {
                customLoginView.hidden = true

                /// Remove Zuzu Login Buttons, so that the customLoginView's height can shrink
                for subview in customLoginView.subviews {
                    subview.removeFromSuperview()
                }
            }
        }

    }

    @IBOutlet weak var titleText: UILabel!

    @IBOutlet weak var subTitleText: UILabel!

    @IBOutlet weak var faceImageView: UIImageView! {
        didSet {
            faceImageView.image = UIImage(named: "lock_icon")?.imageWithRenderingMode(.AlwaysTemplate)
        }
    }

    @IBOutlet weak var skipLoginButton: UIButton! {
        didSet {

            if(allowSkip) {
                skipLoginButton.tintColor = UIColor.grayColor()
                skipLoginButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
                skipLoginButton.layer.cornerRadius = CGFloat(5.0)

                skipLoginButton.addTarget(self, action: #selector(MyCommonLoginViewController.onSkipButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)

            } else {
                skipLoginButton.removeFromSuperview()
            }

        }
    }

    @IBOutlet weak var fbButton: UIButton! {
        didSet {

            fbButton.layer.borderWidth = 2
            fbButton.layer.borderColor =
                UIColor.colorWithRGB(0x4990E2, alpha: 1).CGColor

            fbButton.setImage(UIImage(named: "facebook_icon")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            fbButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit

            fbButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 0)

            fbButton.tintColor =
                UIColor.colorWithRGB(0x4990E2, alpha: 1)

            fbButton.setTitleColor(UIColor.colorWithRGB(0x4990E2, alpha: 1), forState: .Normal)
            fbButton.layer.cornerRadius = CGFloat(5.0)

            fbButton.addTarget(self, action: #selector(MyCommonLoginViewController.onFBButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }

    @IBOutlet weak var googleButton: UIButton! {
        didSet {

            googleButton.layer.borderWidth = 2
            googleButton.layer.borderColor =
                UIColor.colorWithRGB(0xF3364C, alpha: 1).CGColor

            googleButton.setImage(UIImage(named: "google_icon")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            googleButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            googleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

            googleButton.tintColor =
                UIColor.colorWithRGB(0xF3364C, alpha: 1)

            googleButton.setTitleColor(UIColor.colorWithRGB(0xF3364C, alpha: 1), forState: .Normal)
            googleButton.layer.cornerRadius = CGFloat(5.0)

            googleButton.addTarget(self, action: #selector(MyCommonLoginViewController.onGoogleButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }


    // MARK: - Action Handler

    func onSkipButtonTouched(sender: UIButton) {
        Log.enter()

        self.dismissViewControllerAnimated(true) {
            self.delegate?.onSkipUserLogin()
        }
    }

    func onCancelButtonTouched(sender: UIButton) {
        Log.enter()

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

        if loginMode == 1 {
            titleText.text = "登入使用我的收藏"
            subTitleText.text = "請登入使用「我的收藏」，收藏的物件將會被儲存在雲端，日後更換裝置也不會不見喔！"
        } else if loginMode == 2 {
            titleText.text = "登入使用租屋雷達"
            subTitleText.text = "登入豬豬快租，讓您在不同的iOS裝置上都可以收到最即時的通知，好屋不漏接！"
        } else if loginMode == 3 {
            titleText.text = "登入啟用租屋雷達服務"
            subTitleText.text = "我們發現您有購買的租屋雷達尚未完成啟用，請您使用下列帳號登入啟用服務，以維護您的權益"
        }

        if let tabBar = self.presentingViewController?.tabBarController {
            self.isOriginallyHideTabBar = tabBar.tabBarHidden

            if isOriginallyHideTabBar == false {
                tabBar.tabBarHidden = true
            }
        }

        //Google Analytics Tracker
        self.trackScreen()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        //        UIView.animateWithDuration(0.5, animations: {
        //            self.maskView.alpha = 0.3
        //        })
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        //self.maskView.hidden = true

        if let tabBar = self.presentingViewController?.tabBarController {
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
        if let identifier = segue.identifier {

            Log.debug("prepareForSegue: \(identifier)")

            switch identifier {

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
