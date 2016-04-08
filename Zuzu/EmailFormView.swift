//
//  EmailFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

protocol EmailFormDelegate: class {
    func onEmailEntered(email:String?)
}

class EmailFormView: UIView {
    
    var view:UIView!
    
    var delegate: EmailFormDelegate?
    
    var formMode:FormMode = .Register
    
    @IBOutlet weak var emailTextField: UITextField! {
        
        didSet {
            
            emailTextField.tintColor = UIColor.grayColor()
            
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

        delegate?.onEmailEntered(self.emailTextField.text)
        
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