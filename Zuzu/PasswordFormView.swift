//
//  PasswordFormView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SwiftValidator

public class CustomPasswordRule: RegexRule {

    /// Regular express string to be used in validation.
    static let regex = "^[a-zA-Z0-9@#$%^&+=]*$"

    public convenience init(message: String = "Must be 8 characters or numbers") {
        self.init(regex: CustomPasswordRule.regex, message : message)
    }
}

@objc protocol PasswordFormDelegate: class {
    func onPasswordEntered(password: String?)

    @objc optional func onForgotPassword()
}

class PasswordFormView: UIView {

    private let validator = Validator()

    private var view: UIView!

    var delegate: PasswordFormDelegate?

    var formMode: FormMode = .Register

    @IBOutlet var formValidationError: UILabel!

    @IBOutlet weak var forgotPasswordLabel: UILabel! {
        didSet {

            if(self.formMode == .Register) {

                forgotPasswordLabel.hidden = true

            } else if(self.formMode == .Custom) {

                forgotPasswordLabel.hidden = true

            } else {

                forgotPasswordLabel.hidden = false

            }

            forgotPasswordLabel.userInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(PasswordFormView.onForgotPasswordLabelTouched(_:)))
            forgotPasswordLabel.addGestureRecognizer(tap)
        }
    }

    @IBOutlet weak var passwordTextField: UITextField! {
        didSet {

            passwordTextField.becomeFirstResponder()

            passwordTextField.tintColor = UIColor.grayColor()
            passwordTextField.addTarget(self, action: #selector(PasswordFormView.textFieldDidChange(_:)),
                                        forControlEvents: UIControlEvents.EditingChanged)
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
                continueButton.setTitle("登入", forState: .Normal)
            case .Register:
                continueButton.setTitle("註冊", forState: .Normal)
            default:
                continueButton.setTitle("繼續", forState: .Normal)
            }

        }

    }

    // MARK: - Private Utils

    private func setTextFieldErrorStyle(field: UITextField) {
        field.layer.borderColor = UIColor.redColor().CGColor
        field.layer.borderWidth = 1.0
    }

    private func setTextFieldNormalStyle(field: UITextField) {
        field.layer.borderColor = UIColor.clearColor().CGColor
        field.layer.borderWidth = 0.0
    }

    private func setProcessingStateForButton(button: UIButton) {

        button.enabled = false

        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        button.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 0.5)
        button.layer.borderWidth = 2
        button.layer.borderColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 0.5).CGColor
        button.tintColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 0.5)

    }

    private func setNormalStateForButton(button: UIButton) {

        button.enabled = true

        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        button.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        button.layer.borderWidth = 2
        button.layer.borderColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
        button.tintColor =
            UIColor.colorWithRGB(0x1CD4C6, alpha: 1)

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

    private func clearErrorMessageForField(field: UITextField) {

        for (field, error) in validator.errors {
            if(field == field) {
                field.layer.borderColor = UIColor.clearColor().CGColor
                field.layer.borderWidth = 0.0
                error.errorLabel?.hidden = true
            }
        }

    }

    // MARK: - Public APIs
    func alertIncorrectPassword() {
        let errors = [self.passwordTextField : ValidationError(textField: self.passwordTextField, errorLabel: self.formValidationError, error: "您輸入的密碼有誤，請再試一次，謝謝")]
        validator.errors = errors
        self.validationFailed(errors)

        self.setNormalStateForButton(self.continueButton)
    }

    // MARK: - Action Handlers
    func onContinueButtonTouched(sender: UIButton) {

        validator.validate(self)

    }

    func onForgotPasswordLabelTouched(sender: UITapGestureRecognizer) {

        self.passwordTextField.text = nil
        self.clearErrorMessageForField(self.passwordTextField)

        self.delegate?.onForgotPassword?()

    }

    func textFieldDidChange(sender: UITextField) {

        self.clearErrorMessageForField(sender)

    }


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        validator.registerField(passwordTextField, errorLabel: formValidationError, rules: [RequiredRule(message: "請輸入密碼"),
            MinLengthRule(length: 8, message: "密碼必須要8個字元以上"),
            CustomPasswordRule(message: "密碼須由英文、數字或@#$%^&+=等符號組成")])
    }

    init(formMode: FormMode, frame: CGRect) {
        super.init(frame: frame)
        self.formMode = formMode
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

}

extension PasswordFormView: ValidationDelegate {

    func validationSuccessful() {

        self.passwordTextField.resignFirstResponder()

        self.setProcessingStateForButton(self.continueButton)

        self.setTextFieldNormalStyle(self.passwordTextField)

        delegate?.onPasswordEntered(self.passwordTextField.text)

    }

    func validationFailed(errors: [UITextField:ValidationError]) {
        // turn the fields to red
        for (field, error) in errors {
            self.setTextFieldErrorStyle(field)
            error.errorLabel?.text = error.errorMessage // works if you added labels
            error.errorLabel?.hidden = false
        }
    }

}
