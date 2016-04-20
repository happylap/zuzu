//
//  EmailFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftValidator

protocol EmailFormDelegate: class {
    func onEmailEntered(email:String?)
}

class EmailFormView: UIView {
    
    @IBOutlet var formValidationError: UILabel!
    
    let validator = Validator()
    
    var view:UIView!
    
    var delegate: EmailFormDelegate?
    
    var formMode:FormMode = .Register
    
    @IBOutlet weak var emailTextField: UITextField! {
        
        didSet {
            
            emailTextField.becomeFirstResponder()
            
            emailTextField.tintColor = UIColor.grayColor()
            emailTextField.addTarget(self, action: #selector(EmailFormView.textFieldDidChange(_:)), forControlEvents: UIControlEvents.TouchDown)
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
            
            continueButton.addTarget(self, action: #selector(EmailFormView.onContinueButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
            
        }
        
    }
    
    // MARK: - Private Utils
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass:self.dynamicType)
        let nib = UINib(nibName: "EmailFormView", bundle: bundle)
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
        
        validator.registerField(emailTextField, errorLabel: formValidationError, rules: [RequiredRule(message: "請輸入電子郵件"), EmailRule(message: "電子郵件格式錯誤")])
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

extension EmailFormView: ValidationDelegate {
    
    func validationSuccessful() {
        
        self.emailTextField.resignFirstResponder()
        
        delegate?.onEmailEntered(self.emailTextField.text)
        
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
