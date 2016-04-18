//
//  ForgotPasswordViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var formContainerView: UIView!
    
    private var resetPasswordValidationFormView:ResetPasswordValidationFormView?
    
    // MARK: Private Utils
    
    private func setupUI() {
        resetPasswordValidationFormView = ResetPasswordValidationFormView(frame: self.formContainerView.bounds)
        
        if let resetPasswordValidationFormView = resetPasswordValidationFormView {
            resetPasswordValidationFormView.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
            self.formContainerView.addSubview(resetPasswordValidationFormView)
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
