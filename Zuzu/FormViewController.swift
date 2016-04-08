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
                static let subTitle = "請輸入密碼以登入"
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
    
    var emailFormView:EmailFormView?
    var passwordFormView:PasswordFormView?
    
    var formMode:FormMode = .Login
    
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
            
            backButton.addTarget(self, action: Selector("onCancelButtonTouched:"), forControlEvents: UIControlEvents.TouchDown)
        }
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
    
    private func continueLogin() {
        self.modalTitle.text = Message.Login.modalTitle
        self.mainTitleLabel.text = Message.Login.Password.mainTitle
        self.subTitleLabel.text = Message.Login.Password.subTitle
        
        emailFormView?.removeFromSuperview()
        
        passwordFormView = PasswordFormView(frame: self.formContainerView.bounds)
        
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
        
        if let passwordFormView = passwordFormView{
            passwordFormView.formMode = .Register
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }

    
    func onCancelButtonTouched(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch(self.formMode) {
        case .Login:
            setupUIForLogin()
        case .Register:
            setupUIForRegister()
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


extension FormViewController: EmailFormDelegate {
    
    func onEmailEntered(email:String?) {
        // Validate email
        
        
        switch(self.formMode) {
        case .Login:
            self.continueLogin()
        case .Register:
            self.continueRegister()
        }
        
        
    }
}
