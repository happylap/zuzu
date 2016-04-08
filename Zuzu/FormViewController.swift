//
//  InputEmailViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

enum FormMode {
    case Login
    case Register
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
        }
    }
    
    var formMode:FormMode = .Login
    
    var emailFormView:EmailFormView?
    
    var passwordFormView:PasswordFormView?
    
    var continueSocialLoginView: ContinueSocialLoginView?
    
    @IBOutlet weak var modalTitle: UILabel!
    
    @IBOutlet weak var privacyAgreementImage: UIImageView! {
        
        didSet{
            privacyAgreementImage.image = UIImage(named: "comment-check-outline")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
    }
    
    @IBOutlet weak var formContainerView: UIView!
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!{
        didSet {
            backButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            backButton.tintColor = UIColor.whiteColor()
            
            backButton.addTarget(self, action: #selector(FormViewController.onCancelButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    // MARK: - Private Utils
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
    
    private func continueLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        self.mainTitleLabel.text = Message.Login.Password.mainTitle
        self.subTitleLabel.text = Message.Login.Password.subTitle
        
        emailFormView?.removeFromSuperview()
        
        passwordFormView = PasswordFormView(frame: self.formContainerView.bounds)
        passwordFormView?.delegate = self
        
        if let passwordFormView = passwordFormView{
            passwordFormView.formMode = .Login
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
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
    
    private func continueRegister() {
        self.modalTitle.text = Message.Register.modalTitle
        self.mainTitleLabel.text = Message.Register.Password.mainTitle
        self.subTitleLabel.text = Message.Register.Password.subTitle
        
        emailFormView?.removeFromSuperview()
        
        passwordFormView = PasswordFormView(frame: self.formContainerView.bounds)
        passwordFormView?.delegate = self
        
        if let passwordFormView = passwordFormView{
            passwordFormView.formMode = .Register
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }
    
    private func continueSocialLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        self.mainTitleLabel.text = Message.Login.ExistingSocial.mainTitle
        self.subTitleLabel.text = Message.Login.ExistingSocial.subTitle
        
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
    func onCancelButtonTouched(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
        
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch(self.formMode) {
        case .Login:
            setupUIForLogin()
        case .Register:
            setupUIForRegister()
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
        // Validate email
        
        // Check user type
        
        // Existing socail login user
        //self.continueSocialLogin()
        
        // Existing login user
        
        
        // New user
        
        switch(self.formMode) {
        case .Login:
            self.continueLogin()
        case .Register:
            self.continueRegister()
        }
        
        
    }
}

// MARK: - PasswordFormDelegate
extension FormViewController: PasswordFormDelegate {
    
    func onPasswordEntered(password:String?) {
        // Validate password
        
        // Finish login or register
        dismissModalStack(self, animated: true, completionBlock: nil)
    }
}

// MARK: - SocialLoginDelegate
extension FormViewController: SocialLoginDelegate {
    
    func onContinue() {
        
        /// Back to common login form
        self.dismissViewControllerAnimated(true) { () -> Void in
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


