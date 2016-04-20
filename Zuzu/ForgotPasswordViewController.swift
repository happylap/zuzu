//
//  ForgotPasswordViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class ForgotPasswordViewController: UIViewController {
    
    struct  Message {
        struct ValidationCode {
            
            static let mainTitle = "已寄送驗證碼至您的電子信箱"
            static let subTitle = "請輸入信件中的驗證碼以重設密碼"
            
        }
        
        struct NewPassword {
            
            static let mainTitle = "重新設定密碼"
            static let subTitle = "請設定一組新密碼"
            
        }
    }
    
    
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    
    @IBOutlet weak var formContainerView: UIView!
    
    @IBOutlet weak var backButton: UIButton! {
        
        didSet {
            
            backButton.tintColor = UIColor.whiteColor()
            
            backButton.addTarget(self, action: #selector(ForgotPasswordViewController.onBackButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
            
        }
        
    }
    
    private var resetPasswordValidationFormView:ResetPasswordValidationFormView?
    
    private var passwordFormView:PasswordFormView?
    
    // MARK: Private Utils
    
    private func setupUI() {
        
        self.mainTitleLabel.text = Message.ValidationCode.mainTitle
        self.subTitleLabel.text = Message.ValidationCode.subTitle
        
        resetPasswordValidationFormView = ResetPasswordValidationFormView(frame: self.formContainerView.bounds)
        
        if let resetPasswordValidationFormView = resetPasswordValidationFormView {
            resetPasswordValidationFormView.delegate = self
            resetPasswordValidationFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(resetPasswordValidationFormView)
        }
    }
    
    private func continueResetPassword() {
        
        UIView.transitionWithView(self.mainTitleLabel.superview!, duration: 0.6, options: [.TransitionCrossDissolve], animations: {
            self.mainTitleLabel.text = Message.NewPassword.mainTitle
            self.subTitleLabel.text = Message.NewPassword.subTitle
            }, completion: nil)
        
        self.passwordFormView = PasswordFormView(formMode: .Custom, frame: self.formContainerView.bounds)
        
        self.passwordFormView?.continueButton.setTitle("完成設定", forState: .Normal)
        
        if let resetPasswordValidationFormView = resetPasswordValidationFormView, let passwordFormView = self.passwordFormView {
            
            resetPasswordValidationFormView.removeFromSuperview()
            passwordFormView.delegate = self
            passwordFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(passwordFormView)
        }
    }
    
    // MARK: - Action Handlers
    func onBackButtonTouched(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true) { () -> Void in
            
        }
        
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        /// Send reset password validation code

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ForgotPasswordViewController: ResetPasswordFormDelegate {
    
    func onValidationCodeEntered(code:String?) {
        self.continueResetPassword()
    }
    
}

// MARK: - PasswordFormDelegate
extension ForgotPasswordViewController: PasswordFormDelegate {
    
    func onPasswordEntered(password:String?) {
        
    }
    
}

