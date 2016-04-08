//
//  PasswordFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftValidator

public class CustomPasswordRule : RegexRule {
    
    /// Regular express string to be used in validation.
    static let regex = "^[a-zA-Z0-9]*$"
    
    public convenience init(message : String = "Must be 8 characters or numbers") {
        self.init(regex: CustomPasswordRule.regex, message : message)
    }
}

protocol PasswordFormDelegate: class {
    func onPasswordEntered(password:String?)
}

class PasswordFormView: UIView {
    
    let validator = Validator()
    
    var view:UIView!
    
    var delegate: PasswordFormDelegate?
    
    var formMode:FormMode = .Register
    
    @IBOutlet var formValidationError: UILabel!
    
    @IBOutlet weak var forgotPasswordLabel: UILabel! {
        didSet {
            
            if(self.formMode == .Register) {
                forgotPasswordLabel.hidden = true
            }
            
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField! {
        didSet {
            
            passwordTextField.tintColor = UIColor.grayColor()
            passwordTextField.addTarget(self, action: #selector(PasswordFormView.textFieldDidChange(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var continueButton: UIButton! {
        
        didSet {
            continueButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            continueButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            continueButton.layer.borderWidth = 2
            continueButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            continueButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            continueButton.addTarget(self, action: #selector(PasswordFormView.onContinueButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
            
            switch(self.formMode) {
            case .Login:
                continueButton.titleLabel?.text = "登入"
            case .Register:
                continueButton.titleLabel?.text = "註冊"
            }
            
        }
        
    }
    
    // MARK: - Private Utils
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass:self.dynamicType)
        let nib = UINib(nibName: "PasswordFormView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setup() {
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
        self.addSubview(view)
    }
    
    // MARK: - Action Handlers
    func onContinueButtonTouched(sender: UIButton) {
        
        validator.validate(self)
        
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
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        validator.registerField(passwordTextField, errorLabel: formValidationError, rules: [RequiredRule(message: "請輸入密碼"),
            MinLengthRule(length: 8, message: "密碼必須要8個字元以上"),
            CustomPasswordRule(message: "密碼必須由英文字母、數字組成，不能有空白")])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
}

extension PasswordFormView: ValidationDelegate {
    
    func validationSuccessful() {
        
        delegate?.onPasswordEntered(self.passwordTextField.text)
        
    }
    
    func validationFailed(errors:[UITextField:ValidationError]) {
        // turn the fields to red
        for (field, error) in validator.errors {
            field.layer.borderColor = UIColor.redColor().CGColor
            field.layer.borderWidth = 1.0
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.hidden = false
        }
    }
    
}