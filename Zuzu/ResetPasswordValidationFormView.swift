//
//  ResetPasswordValidationFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftValidator

protocol ResetPasswordFormDelegate: class {
    func onValidationCodeEntered(code:String?)
    func onResendValidationCode()
}

class ResetPasswordValidationFormView: UIView {
    
    @IBOutlet var formValidationError: UILabel!
    
    @IBOutlet weak var validationCodeTextField: UITextField! {
        didSet {
            
            validationCodeTextField.tintColor = UIColor.grayColor()
            validationCodeTextField.addTarget(self, action: #selector(ResetPasswordValidationFormView.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
            
        }
    }
    
    @IBOutlet weak var resendCodeButton: UIButton! {
        
        didSet {
            resendCodeButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            resendCodeButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            resendCodeButton.layer.borderWidth = 2
            resendCodeButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            resendCodeButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            
            resendCodeButton.addTarget(self, action: #selector(ResetPasswordValidationFormView.onResendCodeButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
        
    }
    
    @IBOutlet weak var continueResetButton: UIButton! {
        
        didSet {
            continueResetButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            continueResetButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            continueResetButton.layer.borderWidth = 2
            continueResetButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            continueResetButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            
            continueResetButton.addTarget(self, action: #selector(ResetPasswordValidationFormView.onContinueResetButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
        
    }
    
    let validator = Validator()
    
    var delegate: ResetPasswordFormDelegate?
    
    var view:UIView!
    
    // MARK: - Private Utils
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass:self.dynamicType)
        let nib = UINib(nibName: "ResetPasswordValidationFormView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        //view.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
        self.addSubview(view)
        
        
        /// Set constrains between subview and superview to make superview expand to the size of the subviews
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let leftConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0)
        leftConstraint.priority = UILayoutPriorityRequired
        
        let rightConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0)
        rightConstraint.priority = UILayoutPriorityRequired
        
        let topConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
        topConstraint.priority = UILayoutPriorityDefaultHigh
        
        let bottomConstraint = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0)
        bottomConstraint.priority = UILayoutPriorityDefaultHigh
        
        self.addConstraints([leftConstraint, rightConstraint, topConstraint, bottomConstraint])
    }
    
    private func setTextFieldErrorStyle(field: UITextField) {
        field.layer.borderColor = UIColor.redColor().CGColor
        field.layer.borderWidth = 1.0
    }
    
    private func setTextFieldNormalStyle(field: UITextField) {
        field.layer.borderColor = UIColor.clearColor().CGColor
        field.layer.borderWidth = 0.0
    }
    
    // MARK: - Action Handlers
    func onContinueResetButtonTouched(sender: UIButton) {
        
        validator.validate(self)
        
    }
    
    func onResendCodeButtonTouched(sender: UIButton) {
        
        self.delegate?.onResendValidationCode()
        
    }
    
    func textFieldDidChange(sender: UITextField) {
        
        for (field, error) in validator.errors {
            if(field == sender) {
                field.layer.borderColor = UIColor.clearColor().CGColor
                field.layer.borderWidth = 0.0
                error.errorLabel?.hidden = true
            }
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //self.view.frame = self.bounds
        
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        validator.registerField(validationCodeTextField, errorLabel: formValidationError, rules: [RequiredRule(message: "請輸入4位數驗證碼"), ExactLengthRule(length: 4, message: "驗證碼須為4位數")])
    }
    
    // MARK: - Inititializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
}

extension ResetPasswordValidationFormView: ValidationDelegate {
    
    func validationSuccessful() {
        
        self.validationCodeTextField.resignFirstResponder()
        
        self.setTextFieldNormalStyle(self.validationCodeTextField)
        
        delegate?.onValidationCodeEntered(self.validationCodeTextField.text)
    }
    
    func validationFailed(errors:[UITextField:ValidationError]) {
        for (field, error) in validator.errors {
            self.setTextFieldErrorStyle(field)
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.hidden = false
        }
    }
    
}