//
//  AmazonClientManager.swift
//  Zuzu
//
//  Created by eechih on 1/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//


import Foundation
import UICKeyChainStore
import AWSCore
import AWSCognito
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import SCLAlertView

class AmazonClientManager : NSObject {
    static let sharedInstance = AmazonClientManager()
    
    enum Provider: String {
        case FB
    }
    
    //KeyChain Constants
    let FB_PROVIDER = Provider.FB.rawValue
    
    //Properties
    var keyChain: UICKeyChainStore
    var completionHandler: AWSContinuationBlock?
    var fbLoginManager: FBSDKLoginManager?
    var fbLoginData: FBUserData?
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var loginViewController: UIViewController?
    
    override init() {
        keyChain = UICKeyChainStore(service: NSBundle.mainBundle().bundleIdentifier!)
        
        super.init()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    // MARK: General Login
    
    func isConfigured() -> Bool {
        return !(Constants.COGNITO_IDENTITY_POOL_ID == "YourCognitoIdentityPoolId" || Constants.COGNITO_REGIONTYPE == AWSRegionType.Unknown)
    }
    
    func resumeSession(completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        
        if self.keyChain[FB_PROVIDER] != nil {
            self.reloadFBSession()
        }
        
        if self.credentialsProvider == nil {
            self.completeLogin(nil)
        }
    }
    
    //Sends the appropriate URL based on login provider
    func application(application: UIApplication,
        openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
            
            if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
                return true
            }
            return false
    }
    
    func completeLogin(logins: [NSObject : AnyObject]?) {
        
        var task: AWSTask?
        
        if self.credentialsProvider == nil {
            task = self.initializeCredentialsProvider()
        } else {
            var merge = [NSObject : AnyObject]()
            
            //Add existing logins
            if let previousLogins = self.credentialsProvider?.logins {
                merge = previousLogins
            }
            
            //Add new logins
            if let unwrappedLogins = logins {
                for (key, value) in unwrappedLogins {
                    merge[key] = value
                }
                self.credentialsProvider?.logins = merge
            }
            //Force a refresh of credentials to see if merge is necessary
            task = self.credentialsProvider?.refresh()
        }

        task?.continueWithBlock {
            (task: AWSTask!) -> AnyObject! in
            if (task.error != nil) {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let currentDeviceToken: NSData? = userDefaults.objectForKey(Constants.DEVICE_TOKEN_KEY) as? NSData
                var currentDeviceTokenString : String
                
                if currentDeviceToken != nil {
                    currentDeviceTokenString = currentDeviceToken!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
                } else {
                    currentDeviceTokenString = ""
                }
                
                if currentDeviceToken != nil && currentDeviceTokenString != userDefaults.stringForKey(Constants.COGNITO_DEVICE_TOKEN_KEY) {
                    
                    AWSCognito.defaultCognito().registerDevice(currentDeviceToken).continueWithBlock { (task: AWSTask!) -> AnyObject! in
                        if (task.error == nil) {
                            userDefaults.setObject(currentDeviceTokenString, forKey: Constants.COGNITO_DEVICE_TOKEN_KEY)
                            userDefaults.synchronize()
                        }
                        return nil
                    }
                }
            }
            
            return task
            }.continueWithBlock(self.completionHandler!)
    }
    
    func initializeCredentialsProvider() -> AWSTask? {
        print("Initializing Credentials Provider...")
        
        AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityPoolId: Constants.COGNITO_IDENTITY_POOL_ID)
        
        let configuration = AWSServiceConfiguration(region: Constants.COGNITO_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        return self.credentialsProvider?.getIdentityId()
    }
    
    func loginFromView(theViewController: UIViewController, withCompletionHandler completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        self.loginViewController = theViewController
        
        if self.isLoggedIn() {
            self.displayLoginView(theViewController)
        } else {
            
            let loginAlertView = SCLAlertView()
            loginAlertView.showCloseButton = false
            
            loginAlertView.addButton("立即登入 Facebook") {
                self.fbLogin(theViewController)
            }
            
            loginAlertView.addButton("取消") {
                ///GA Tracker: Login cancelled
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
            }
            
            loginAlertView.showNotice("提醒您", subTitle: "此功能需登入Facebook才能使用喔!", duration: 5.0, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        }
        
    }
    
    func logOut(completionHandler: AWSContinuationBlock) {
        if self.isLoggedInWithFacebook() {
            self.fbLogout()
        }
        
        // Wipe credentials
        self.credentialsProvider?.logins = nil
        //AWSCognito.defaultCognito().wipe()
        self.credentialsProvider?.clearKeychain()
        
        AWSTask(result: nil).continueWithBlock(completionHandler)
    }
    
    func isLoggedIn() -> Bool {
        return isLoggedInWithFacebook()
    }
    
    // MARK: Facebook Login
    
    func isLoggedInWithFacebook() -> Bool {
        let loggedIn = FBSDKAccessToken.currentAccessToken() != nil
        
        return self.keyChain[FB_PROVIDER] != nil && loggedIn
    }
    
    func reloadFBSession() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            print("Reloading Facebook Session")
            self.completeFBLogin()
        }
    }
    
    func fbLogin(theViewController: UIViewController) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.completeFBLogin()
        } else {
            if self.fbLoginManager == nil {
                self.fbLoginManager = FBSDKLoginManager()
            }
            
            self.fbLoginManager?.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: theViewController, handler: { (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
                if (error != nil) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.errorAlert("Error logging in with FB: " + error.localizedDescription)
                    }
                    
                    ///GA Tracker: Login failed
                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                        action: GAConst.Action.Blocking.LoginError, label: GAConst.Label.LoginType.Facebook)
                    
                } else if result.isCancelled {
                    
                    ///GA Tracker: Login cancelled
                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                        action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
                    
                } else {
                    self.completeFBLogin()
                    
                    ///GA Tracker: Login successful
                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                        action: GAConst.Action.MyCollection.Login, label: GAConst.Label.LoginType.Facebook)
                }
            })
        }
        
    }
    
    func fbLogout() {
        if self.fbLoginManager == nil {
            self.fbLoginManager = FBSDKLoginManager()
        }
        self.fbLoginManager?.logOut()
        self.keyChain[FB_PROVIDER] = nil
    }
    
    
    func completeFBLogin() {
        
        FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields":"id, email, birthday, gender, name, first_name, last_name, bio, picture.type(large)"]).startWithCompletionHandler { (connection, result, error) -> Void in
            if error == nil {
                
                let fbLoginData = FBUserData()
                if let strId: String = result.objectForKey("id") as? String {
                    fbLoginData.facebookId = strId
                }
                if let strEmail: String = result.objectForKey("email") as? String {
                    fbLoginData.facebookEmail = strEmail
                }
                if let strName: String = result.objectForKey("name") as? String {
                    fbLoginData.facebookName = strName
                }
                if let strFirstName: String = result.objectForKey("first_name") as? String {
                    fbLoginData.facebookFirstName = strFirstName
                }
                if let strLastName: String = result.objectForKey("last_name") as? String {
                    fbLoginData.facebookLastName = strLastName
                }
                if let strGender: String = result.objectForKey("gender") as? String {
                    fbLoginData.facebookGender = strGender
                }
                if let strBirthday: String = result.objectForKey("birthday") as? String {
                    fbLoginData.facebookBirthday = strBirthday
                }
                if let strPictureURL: String = result.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String {
                    fbLoginData.facebookPictureUrl = strPictureURL
                }
                
                self.fbLoginData = fbLoginData
                self.keyChain[self.FB_PROVIDER] = "YES"
                self.completeLogin([AWSCognitoLoginProviderKey.Facebook.rawValue : FBSDKAccessToken.currentAccessToken().tokenString])
            }
        }
    }
    
    // MARK: UI Helpers
    
    func displayLoginView(theViewController: UIViewController) {
        let storyboard = UIStoryboard(name: "MyCollectionStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("FBLoginView") as? FBLoginViewController {
            theViewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func errorAlert(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Default) { (alert: UIAlertAction) -> Void in }
        
        errorAlert.addAction(okAction)
        
        self.loginViewController?.presentViewController(errorAlert, animated: true, completion: nil)
    }
}
