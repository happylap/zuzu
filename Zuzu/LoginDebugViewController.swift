//
//  LoginDebugViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView
import FBSDKLoginKit

private let Log = Logger.defaultLogger

class LoginDebugViewController: UIViewController {
    
    private var responder: SCLAlertViewResponder?
    
    @IBOutlet weak var googleLogin: UIButton! {
        didSet {
            googleLogin.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var facebookLogin: UIButton! {
        didSet {
            facebookLogin.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var currentUser: UIButton! {
        didSet {
            currentUser.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var cognitoIdentity: UIButton! {
        didSet {
            cognitoIdentity.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTokenRefreshed:", name: UserLoginNotification, object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleTokenRefreshed(notification: NSNotification){
        
        self.runOnMainThread { () -> Void in
            
            Log.enter()
            
            if let status = notification.userInfo?["status"] as? Int {
                if(status == LoginStatus.Resume.rawValue) {
                    
                    if let provider = AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                        switch(provider) {
                        case .FB:
                            self.popupFacebookStatus()
                        case .GOOGLE:
                            self.popupGoogleStatus()
                        }
                    }
                }
            }
        }
        
    }
    
    private func popupGoogleStatus() {
        
        Log.enter()
        
        responder?.close()
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Google not logged in"
        
        if let googleToken = GIDSignIn.sharedInstance().currentUser?.authentication?.idToken {
            
            subTitle = "Google Token = \n\(googleToken)" +
                "\n\n Token Expiry = \(GIDSignIn.sharedInstance().currentUser?.authentication?.idTokenExpirationDate ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
        }
        
        if(AmazonClientManager.sharedInstance.isLoggedInWithGoogle()) {
            myAlert.addButton("Refresh") { () -> Void in
                AmazonClientManager.sharedInstance.reloadGSession()
            }
            
            myAlert.addButton("Validate") { () -> Void in
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, provider =  AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                    
                    if(provider == Provider.GOOGLE) {
                        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                            SCLAlertView().showInfo("Validation Result", subTitle: "Result: \(result), Error: \(error)")
                        }
                    }
                }
                
            }
        }
        
        responder = myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onGoogleLoginButtonTouched(sender: UIButton) {
        
        self.popupGoogleStatus()
        
    }
    
    
    private func popupFacebookStatus() {
        
        Log.enter()
        
        responder?.close()
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Facebook not logged in"
        
        if let fbToken = FBSDKAccessToken.currentAccessToken()?.tokenString {
            
            subTitle = "FB Token = \n\(fbToken)" +
                "\n\n Token Expiry = \(FBSDKAccessToken.currentAccessToken()?.expirationDate ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
        }
        
        if(AmazonClientManager.sharedInstance.isLoggedInWithFacebook()) {
            myAlert.addButton("Refresh") { () -> Void in
                AmazonClientManager.sharedInstance.reloadFBSession()
            }
            
            myAlert.addButton("Validate") { () -> Void in
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, provider =  AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                    
                    if(provider == Provider.FB) {
                        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                            SCLAlertView().showInfo("Validation Result", subTitle: "Result: \(result), Error: \(error)")
                        }
                    }
                }
                
            }
        }
        
        responder = myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onFacebookLoginButtonTouched(sender: UIButton) {
        self.popupFacebookStatus()
    }
    
    private func popupCognitokStatus() {
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Cognito not logged in"
        
        if let provider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration?.credentialsProvider as?  AWSCognitoCredentialsProvider {
            
            subTitle = "Cognito IdentityID = \n\(provider.identityId ?? "-")" +
                "\n\n IdentityID Expiry = \(provider.expiration ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
            
        }
        
        myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onCognitoButtonTouched(sender: UIButton) {
        self.popupCognitokStatus()
    }
    
    @IBAction func onCurrentUserButtonTouched(sender: UIButton) {
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "No current user"
        
        if let currentUser = AmazonClientManager.sharedInstance.currentUserProfile {
            
            subTitle = "UserId = \n\(currentUser.id ?? "-")" +
                "\n\n Provider = \(currentUser.provider?.rawValue ?? "-")" +
            "\n\n Email = \(currentUser.email ?? "-")"
        }
        
        myAlert.showTitle("Current User", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
