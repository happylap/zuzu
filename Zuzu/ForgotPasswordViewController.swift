//
//  ForgotPasswordViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView

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
    
    private var validationCode:String?
    
    // Passed-In Params
    var userEmail:String?
    
    // MARK: Private Utils
    private func alertServerError(error: String) {
        
        let alertView = SCLAlertView()
        
        let subTitle = "很抱歉，目前暫時無法為您完成此操作，請稍後再試，謝謝！\n\(error)"
        
        alertView.showInfo("網路連線失敗", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        
    }
    
    private func alertInvalidCode() {
        
        let alertView = SCLAlertView()
        
        let subTitle = "很抱歉，您輸入的驗證碼已經失效，請嘗試重送驗證碼，謝謝！"
        
        alertView.showInfo("無效的驗證碼", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        
    }
    
    private func setupUI() {
        
        self.mainTitleLabel.text = Message.ValidationCode.mainTitle
        self.subTitleLabel.text = Message.ValidationCode.subTitle
        
        resetPasswordValidationFormView = ResetPasswordValidationFormView(frame: self.formContainerView.bounds)
        
        if let resetPasswordValidationFormView = resetPasswordValidationFormView {
            resetPasswordValidationFormView.delegate = self
            //resetPasswordValidationFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            resetPasswordValidationFormView.translatesAutoresizingMaskIntoConstraints = false
            self.formContainerView.addSubview(resetPasswordValidationFormView)
            
            let xConstraint = NSLayoutConstraint(item: resetPasswordValidationFormView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.formContainerView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired
            
            let leftConstraint = NSLayoutConstraint(item: resetPasswordValidationFormView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.formContainerView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0)
            leftConstraint.priority = UILayoutPriorityRequired
            
            let rightConstraint = NSLayoutConstraint(item: resetPasswordValidationFormView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.formContainerView, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0)
            rightConstraint.priority = UILayoutPriorityRequired
            
            let topConstraint = NSLayoutConstraint(item: resetPasswordValidationFormView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.formContainerView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
            topConstraint.priority = UILayoutPriorityRequired
            
            let bottomConstraint = NSLayoutConstraint(item: resetPasswordValidationFormView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.formContainerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0)
            bottomConstraint.priority = UILayoutPriorityDefaultHigh
            
            self.formContainerView.addConstraints([xConstraint, leftConstraint, rightConstraint, topConstraint, bottomConstraint])
            
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Send reset password validation code
        let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
        loadingSpinner.setGraceTime(0.6)
        loadingSpinner.setMinShowTime(0.6)
        loadingSpinner.setOpacity(0.6)
        loadingSpinner.startOnView(self.view)
        
        if let userEmail = self.userEmail {
            ZuzuWebService.sharedInstance.forgotPassword(userEmail) { (error) in
                
                loadingSpinner.stop()
                
                if let error = error {
                    self.alertServerError(String(error))
                    return
                }
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ForgotPasswordViewController: ResetPasswordFormDelegate {
    
    func onResendValidationCode() {
        
        /// Send reset password validation code
        let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
        loadingSpinner.setGraceTime(0.6)
        loadingSpinner.setMinShowTime(0.6)
        loadingSpinner.setOpacity(0.6)
        loadingSpinner.startOnView(self.view)
        
        if let userEmail = self.userEmail {
            ZuzuWebService.sharedInstance.forgotPassword(userEmail) { (error) in
                
                if let error = error {
                    self.alertServerError(String(error))
                    return
                }
                
                loadingSpinner.stop()
                
            }
        }
        
    }
    
    func onValidationCodeEntered(code:String?) {
        
        validationCode = code
        
        /// Check if validation code is valid
        let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
        loadingSpinner.setGraceTime(0.6)
        loadingSpinner.setMinShowTime(0.6)
        loadingSpinner.setOpacity(0.6)
        loadingSpinner.startOnView(self.view)
        
        if let userEmail = self.userEmail, userCode = self.validationCode {
            
            ZuzuWebService.sharedInstance.checkVerificationCode(userEmail, verificationCode: userCode, handler: { (result, error) in
                
                loadingSpinner.stop()
                
                if let error = error {
                    self.alertServerError(String(error))
                    return
                }
                
                if let result = result where result == true {
                    
                    self.continueResetPassword()
                    
                } else {
                    /// Alert Invalid Code
                    self.alertInvalidCode()
                }
                
            })
            
        }
        
        
    }
    
}

// MARK: - PasswordFormDelegate
extension ForgotPasswordViewController: PasswordFormDelegate {
    
    func onPasswordEntered(password:String?) {
        
        let loadingSpinner = LoadingSpinner.getInstance(String(self.dynamicType))
        loadingSpinner.setMinShowTime(0.6)
        loadingSpinner.setOpacity(0.6)
        loadingSpinner.startOnView(self.view)
        
        /// Reset new password
        if let userEmail = self.userEmail, newPassword = password, userCode = self.validationCode {
            ZuzuWebService.sharedInstance.resetPassword(userEmail, password: newPassword, verificationCode: userCode, handler: { (userId, error) in
                
                if let error = error {
                    self.alertServerError(String(error))
                    return
                }
                
                loadingSpinner.stop()
                
                self.dismissViewControllerAnimated(true) { () -> Void in
                    
                }
            })
        }
        
    }
    
}

