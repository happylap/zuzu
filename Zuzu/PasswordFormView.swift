//
//  LoginFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

protocol PasswordFormDelegate: class {
    func onPasswordEntered(password:String?)
}

class PasswordFormView: UIView {
    
    var delegate: PasswordFormDelegate?
    
    var formMode:FormMode = .Register
    
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
    
    func onContinueButtonTouched(sender: UIButton) {
        
        delegate?.onPasswordEntered(self.passwordTextField.text)
        
    }
    
    var view:UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
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
    
}
