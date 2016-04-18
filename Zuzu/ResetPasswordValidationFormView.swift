//
//  ResetPasswordValidationFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftValidator

class ResetPasswordValidationFormView: UIView {
    
    @IBOutlet var formValidationError: UILabel!
    
    @IBOutlet weak var resendCodeButton: UIButton! {
        
        didSet {
            resendCodeButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            resendCodeButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            resendCodeButton.layer.borderWidth = 2
            resendCodeButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            resendCodeButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
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
        }
        
    }
    
    let validator = Validator()
    
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
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
        self.addSubview(view)
    }
    
    // MARK: - Action Handlers

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
}
