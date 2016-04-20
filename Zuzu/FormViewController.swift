//
//  InputEmailViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView
import SwiftyStateMachine

enum FormMode {
    case Login
    case Register
    case Custom
}

enum FormResult {
    case Success
    case Failed
    case Cancelled
}

protocol FormViewControllerDelegate {
    
    func onLoginDone(result: FormResult, userId: String?, zuzuToken: String?)
    
    func onRegisterDone(result: FormResult)
    
}

class FormViewController: UIViewController {
    
    struct  Message {
        struct Login {
            static let modalTitle = "登入豬豬快租"
            
            struct Email {
                static let mainTitle = "登入帳號"
                static let subTitle = "享受更多、更好的服務"
            }
            
            struct Password {
                static let mainTitle = "歡迎你回來！"
                static let subTitle = "請輸入密碼登入"
            }
            
            struct ExistingSocial {
                static let mainTitle = "歡迎你回來！"
                static let subTitle = "帳號已經存在\n請直接使用GOOGLE 或 FACEBOOK 登入"
            }
            
            struct Existing {
                static let mainTitle = "歡迎你回來！"
                static let subTitle = "帳號已經存在，請輸入密碼登入"
            }
        }
        
        
        struct Register {
            static let modalTitle = "註冊豬豬快租"
            
            struct Email {
                static let mainTitle = "註冊新帳號"
                static let subTitle = "享受更多、更好的服務"
            }
            
            struct Password {
                static let mainTitle = "歡迎加入豬豬快租"
                static let subTitle = "為你的帳號選擇一組密碼"
            }
            
            struct NonExisting {
                static let mainTitle = "您還不是會員"
                static let subTitle = "選擇一組密碼後，立即成為會員"
            }
        }
    }
    
    private enum FormState {
        case Init, LoginEmail, LoginPassword, RegisterEmail, RegisterPassword, LoginDone, RegisterDone}
    
    private enum FormStateEvent {
        case OnStartLogin, OnStartRegister,
        OnInputEmail, OnInputPassword,
        OnLoginSuccess, OnLoginFailure,
        OnRegisterSuccess, OnRegisterFailure
        
    }
    
    private var machine: StateMachine<StateMachineSchema<FormState, FormStateEvent, Void>>!
    
    private var emailFormView:EmailFormView?
    
    private var passwordFormView:PasswordFormView?
    
    private var continueSocialLoginView: ContinueSocialLoginView?
    
    private var userAccount: String?
    
    /// Passed in params
    var delegate: FormViewControllerDelegate?
    
    var formMode:FormMode = .Login
    
    @IBOutlet weak var modalTitle: UILabel!
    
    @IBOutlet weak var privacyAgreementImage: UIImageView! {
        
        didSet{
            privacyAgreementImage.image = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
    }
    
    @IBOutlet weak var privacyAgreement: UILabel! {
        didSet {
            
            privacyAgreement.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(FormViewController.onPrivacyAgreementTouched(_:)))
            privacyAgreement.addGestureRecognizer(tap)
        }
    }
    
    @IBOutlet weak var formContainerView: UIView!
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!{
        didSet {
            
            switch(self.formMode) {
            case .Login:
                backButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            case .Register:
                backButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            //                backButton.setImage(UIImage(named: "back_arrow_n")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            default: break
            }
            
            
            backButton.tintColor = UIColor.whiteColor()
            
            backButton.addTarget(self, action: #selector(FormViewController.onBackButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    // MARK: - Private Utils
    
    private func alertRegisterFailure() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "由於系統錯誤，暫時無法註冊，請您稍後再試，或者嘗試其他註冊方式，謝謝！"
        
        alertView.showInfo("註冊失敗", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func alertLoginFailure() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "由於系統錯誤，暫時無法登入，請您稍後再試，或者嘗試其他登入方式，謝謝！"
        
        alertView.showInfo("登入失敗", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    private func setupUIForLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        self.mainTitleLabel.text = Message.Login.Email.mainTitle
        self.subTitleLabel.text = Message.Login.Email.subTitle
        
        emailFormView = EmailFormView(frame: self.formContainerView.bounds)
        emailFormView?.delegate = self
        
        if let emailFormView = emailFormView {
            emailFormView.formMode = .Login
            emailFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(emailFormView)
        }
    }
    
    private func setupUIForRegister() {
        self.modalTitle.text = Message.Register.modalTitle
        self.mainTitleLabel.text = Message.Register.Email.mainTitle
        self.subTitleLabel.text = Message.Register.Email.subTitle
        
        emailFormView = EmailFormView(frame: self.formContainerView.bounds)
        emailFormView?.delegate = self
        
        if let emailFormView = emailFormView {
            emailFormView.formMode = .Register
            emailFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(emailFormView)
        }
    }
    
    // MARK: - State Transition
    private func registerToLogin() {
        
        self.formMode = .Login
        
        self.modalTitle.text = Message.Login.modalTitle
        
        if let parentView = self.mainTitleLabel.superview {
            UIView.transitionWithView(parentView, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
                self.mainTitleLabel.text = Message.Login.Existing.mainTitle
                self.subTitleLabel.text = Message.Login.Existing.subTitle
                }, completion: nil)
        }
        
        self.passwordFormView = PasswordFormView(formMode: .Login, frame: self.formContainerView.bounds)
        
        if let emailFormView = emailFormView, let passwordFormView = self.passwordFormView {
            
            emailFormView.removeFromSuperview()
            passwordFormView.delegate = self
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }
    
    private func continueLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        
        if let parentView = self.mainTitleLabel.superview {
            UIView.transitionWithView(parentView, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
                self.mainTitleLabel.text = Message.Login.Password.mainTitle
                self.subTitleLabel.text = Message.Login.Password.subTitle
                }, completion: nil)
        }
        
        self.passwordFormView = PasswordFormView(formMode: .Login, frame: self.formContainerView.bounds)
        
        if let emailFormView = emailFormView, let passwordFormView = self.passwordFormView {
            
            emailFormView.removeFromSuperview()
            passwordFormView.delegate = self
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }
    
    private func loginToRegister() {
        
        self.formMode = .Register
        
        self.modalTitle.text = Message.Register.modalTitle
        
        if let parentView = self.mainTitleLabel.superview {
            UIView.transitionWithView(parentView, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
                self.mainTitleLabel.text = Message.Register.NonExisting.mainTitle
                self.subTitleLabel.text = Message.Register.NonExisting.subTitle
                }, completion: nil)
        }
        
        self.passwordFormView = PasswordFormView(formMode: .Register, frame: self.formContainerView.bounds)
        
        if let emailFormView = emailFormView, let passwordFormView = self.passwordFormView {
            
            emailFormView.removeFromSuperview()
            passwordFormView.delegate = self
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }
    
    private func continueRegister() {
        
        self.modalTitle.text = Message.Register.modalTitle
        
        if let parentView = self.mainTitleLabel.superview {
            UIView.transitionWithView(parentView, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
                self.mainTitleLabel.text = Message.Register.Password.mainTitle
                self.subTitleLabel.text = Message.Register.Password.subTitle
                }, completion: nil)
        }
        
        self.passwordFormView = PasswordFormView(formMode: .Register, frame: self.formContainerView.bounds)
        
        if let emailFormView = emailFormView, let passwordFormView = self.passwordFormView {
            
            passwordFormView.delegate = self
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            
            emailFormView.removeFromSuperview()
            self.formContainerView.addSubview(passwordFormView)
            
            //            UIView.transitionFromView(emailFormView,
            //                                      toView: passwordFormView,
            //                                      duration: 0.6, options: .TransitionFlipFromRight, completion: nil)
        }
    }
    
    private func continueSocialLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        
        if let parentView = self.mainTitleLabel.superview {
            UIView.transitionWithView(parentView, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
                self.mainTitleLabel.text = Message.Login.ExistingSocial.mainTitle
                self.subTitleLabel.text = Message.Login.ExistingSocial.subTitle
                }, completion: nil)
        }
        
        emailFormView?.removeFromSuperview()
        
        continueSocialLoginView = ContinueSocialLoginView(frame: self.formContainerView.bounds)
        continueSocialLoginView?.delegate = self
        
        if let continueSocialLoginView = continueSocialLoginView {
            continueSocialLoginView.formMode = .Register
            continueSocialLoginView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(continueSocialLoginView)
        }
    }
    
    // MARK: - Action Handlers
    func onBackButtonTouched(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            switch(self.formMode) {
            case .Login:
                self.delegate?.onLoginDone(FormResult.Cancelled, userId: nil, zuzuToken: nil)
            case .Register:
                self.delegate?.onRegisterDone(FormResult.Cancelled)
            default: break
            }
        }
        
    }
    
    func onPrivacyAgreementTouched(sender:UITapGestureRecognizer) {
        
        let privacyUrl = "https://zuzurentals.wordpress.com/zuzu-rentals-privacy-policy/"
        
        ///Open by Facebook App
        if let url = NSURL(string: privacyUrl) {
            
            if (UIApplication.sharedApplication().canOpenURL(url)) {
                
                UIApplication.sharedApplication().openURL(url)
                
            }
        }
        
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let stateSchema = StateMachineSchema<FormState, FormStateEvent, Void>(initialState: .Init) {
            (state, event) in
            switch state {
                
            case .Init:
                switch event {
                case .OnStartLogin: return (.LoginEmail, { _ in print("LoginEmail")})
                case .OnStartRegister: return (.RegisterEmail, { _ in print("RegisterEmail")})
                default: return nil
                }
                
            case .LoginEmail:
                switch event {
                case .OnInputEmail: return (.LoginPassword, { _ in print("LoginPassword")})
                default: return nil
                }
                
            case .LoginPassword:
                switch event {
                case .OnInputPassword: return (.LoginPassword, { _ in print("LoginPassword")})
                case .OnLoginSuccess: return (.LoginDone, { _ in print("LoginDone")})
                case .OnLoginFailure: return (.LoginDone, { _ in print("LoginDone")})
                default: return nil
                }
                
            case .RegisterEmail:
                switch event {
                case .OnInputEmail: return (.RegisterPassword, { _ in print("RegisterEmail")})
                default: return nil
                }
                
            case .RegisterPassword:
                switch event {
                case .OnInputPassword: return nil
                case .OnRegisterSuccess: return (.RegisterDone, { _ in print("RegisterDone")})
                case .OnRegisterFailure: return (.RegisterDone, { _ in print("RegisterDone")})
                default: return nil
                }
            default: return nil
            }
        }
        
        self.machine = StateMachine(schema: stateSchema, subject: ())
        
        switch(self.formMode) {
        case .Login:
            self.setupUIForLogin()
            machine.handleEvent(.OnStartLogin)
            
        case .Register:
            self.setupUIForRegister()
            machine.handleEvent(.OnStartRegister)
        default: break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

// MARK: - EmailFormDelegate
extension FormViewController: EmailFormDelegate {
    
    func onEmailEntered(email:String?) {
        
        let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
        loadingSpinner.setDimBackground(false)
        loadingSpinner.setGraceTime(0.6)
        loadingSpinner.setMinShowTime(0.6)
        loadingSpinner.setOpacity(0.6)
        loadingSpinner.startOnView(self.view)
        
        // Check user type
        if let email = email {
            
            self.userAccount = email
            
            ZuzuWebService.sharedInstance.checkEmail(email) { (emailExisted, provider, error) in
                
                loadingSpinner.stopAndRemove()
                
                if let _ = error {
                    
                    switch(self.formMode) {
                    case .Login:
                        self.alertLoginFailure()
                    case .Register:
                        self.alertRegisterFailure()
                    default: break
                    }
                    
                    return
                }
                
                if(emailExisted) {
                    
                    if let provider = provider where provider != Provider.ZUZU.rawValue {
                        
                        // Existing socail login user
                        self.continueSocialLogin()
                        
                    } else {
                        
                        switch(self.formMode) {
                        case .Login:
                            self.continueLogin()
                        case .Register:
                            /// Go to login with custom message
                            self.registerToLogin()
                        default: break
                        }
                        
                    }
                    
                } else {
                    
                    switch(self.formMode) {
                    case .Login:
                        /// Go to register with custom message
                        self.loginToRegister()
                    case .Register:
                        self.continueRegister()
                    default: break
                    }
                }
            }
        }
    }
}

// MARK: - PasswordFormDelegate
extension FormViewController: PasswordFormDelegate {
    
    func onForgotPassword() {
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("forgotPasswordFormView") as? ForgotPasswordViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.userEmail = self.userAccount
            self.presentViewController(vc, animated: true, completion: nil)
        }
        
    }
    
    func onPasswordEntered(password:String?) {
        
        switch(self.formMode) {
        case .Login:
            
            let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
            loadingSpinner.setDimBackground(false)
            loadingSpinner.setGraceTime(0.6)
            loadingSpinner.setMinShowTime(0.6)
            loadingSpinner.setOpacity(0.6)
            loadingSpinner.startOnView(self.view)
            
            if let password = password, email = self.userAccount {
                
                ZuzuWebService.sharedInstance.loginByEmail(email, password: password, handler: { (userId, userToken, error) in
                    
                    loadingSpinner.stopAndRemove()
                    
                    /// Incorrect password
                    if let myerror = error where myerror._code == 500 {
                        
                        self.passwordFormView?.alertIncorrectPassword()
                        return
                    }
                    
                    /// Other abnormal server state
                    if let _ = error {
                        self.delegate?.onLoginDone(.Failed, userId: nil, zuzuToken: nil)
                        return
                    }
                    
                    // Finish login
                    dismissModalStack(self, animated: true, completionBlock: {
                        self.delegate?.onLoginDone(.Success, userId: userId, zuzuToken: userToken)
                    })
                    
                })
                
            }
            
        case .Register:
            
            let user = ZuzuUser()
            user.email = self.userAccount
            user.provider = Provider.ZUZU
            
            let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
            loadingSpinner.setDimBackground(false)
            loadingSpinner.setGraceTime(0.6)
            loadingSpinner.setMinShowTime(0.6)
            loadingSpinner.setOpacity(0.6)
            loadingSpinner.startOnView(self.view)
            
            if let password = password, email = user.email {
                ZuzuWebService.sharedInstance.registerUser(user, password: password, handler: { (userId, error) in
                    
                    if let _ = error {
                        
                        loadingSpinner.stopAndRemove()
                        
                        self.alertRegisterFailure()
                        
                        self.delegate?.onRegisterDone(FormResult.Failed)
                        
                        return
                    }
                    
                    self.delegate?.onRegisterDone(FormResult.Success)
                    
                    /// Do login
                    ZuzuWebService.sharedInstance.loginByEmail(email, password: password, handler: { (userId, userToken, error) in
                        
                        // Finish login
                        loadingSpinner.stopAndRemove()
                        
                        if let _ = error {
                            self.delegate?.onLoginDone(.Failed, userId: nil, zuzuToken: nil)
                            return
                        }
                        
                        // Finish login
                        dismissModalStack(self, animated: true, completionBlock: {
                            self.delegate?.onLoginDone(.Success, userId: userId, zuzuToken: userToken)
                        })
                        
                    })
                    
                })
            }
        default: break
        }
    }
}

// MARK: - SocialLoginDelegate
extension FormViewController: SocialLoginDelegate {
    
    func onContinue() {
        
        let presentingViewController = self.presentingViewController
        
        /// Back to common login form
        self.dismissViewControllerAnimated(true) { () -> Void in
            
            self.delegate?.onLoginDone(FormResult.Cancelled, userId: nil, zuzuToken: nil)
            
            if(!AmazonClientManager.sharedInstance.isLoggedIn()) {
                
                if let presentingViewController = presentingViewController {
                    AmazonClientManager.sharedInstance.loginFromView(presentingViewController) {
                        (task: AWSTask!) -> AnyObject! in
                        return nil
                    }
                }
            }
        }
    }
}


func dismissModalStack(viewController: UIViewController, animated: Bool, completionBlock: (() -> Void)?) {
    if viewController.presentingViewController != nil {
        var vc = viewController.presentingViewController!
        while (vc.presentingViewController != nil) {
            vc = vc.presentingViewController!
        }
        vc.dismissViewControllerAnimated(animated, completion: nil)
        
        if let c = completionBlock {
            c()
        }
    }
}


