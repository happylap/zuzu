//
//  ForgotPasswordViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var formContainerView: UIView!
    
    @IBOutlet weak var backButton: UIButton! {
        
        didSet {
            
            backButton.tintColor = UIColor.whiteColor()
            
            backButton.addTarget(self, action: #selector(ForgotPasswordViewController.onBackButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
            
        }
        
    }
    private var resetPasswordValidationFormView:ResetPasswordValidationFormView?
    
    // MARK: Private Utils
    
    private func setupUI() {
        resetPasswordValidationFormView = ResetPasswordValidationFormView(frame: self.formContainerView.bounds)
        
        if let resetPasswordValidationFormView = resetPasswordValidationFormView {
            resetPasswordValidationFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(resetPasswordValidationFormView)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
