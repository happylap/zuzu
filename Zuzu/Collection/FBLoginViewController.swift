//
//  FBLoginViewController.swift
//  Zuzu
//
//  Created by eechih on 12/29/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class FBLoginViewController: UIViewController, FBSDKLoginButtonDelegate
{
    
    @IBOutlet var btnFacebook: FBSDKLoginButton!
    @IBOutlet var ivUserProfileImage: UIImageView!
    @IBOutlet var lblName: UILabel!
    @IBOutlet var btnCancel: UIButton!
    
    // MARK: - Control Action Handlers
    
    @IBAction func onCancelButtonTouched(sender: UIButton) {
        NSLog("%@ onCancelButtonTouched", self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //    MARK: ViewLifeCycle Methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        configureFacebook()
    }
    
    //    MARK: FBSDKLoginButtonDelegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!)
    {
        
        if FBLoginService.sharedInstance.hasActiveSession() {
            AmazonClientManager.sharedInstance.fbLogin()
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            
            if error != nil {
                let alertView = UIAlertView(
                    title: "提醒",
                    message: "您的網路可能發生一些問題，導致登入失敗",
                    delegate: self,
                    cancelButtonTitle: "知道了")
                
                // Configure Alert View
                alertView.tag = 2
                
                // Show Alert View
                alertView.show()
                
                // Delay the dismissal
                self.runOnMainThreadAfter(2.0) {
                    alertView.dismissWithClickedButtonIndex(-1, animated: true)
                }
            }
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!)
    {
        let loginManager: FBSDKLoginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
    
    //    MARK: Other Methods
    
    func configureFacebook()
    {
        btnFacebook.readPermissions = ["public_profile", "email", "user_friends"]
        btnFacebook.delegate = self
    }
    
}
