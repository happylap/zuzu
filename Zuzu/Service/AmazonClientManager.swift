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
            task = self.initializeClients(logins)
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
            
            // Synchronize core data from Cognito
            CollectionItemService.sharedInstance.synchronize()
            
            return task
            }.continueWithBlock(self.completionHandler!)
    }
    
    func initializeClients(logins: [NSObject : AnyObject]?) -> AWSTask? {
        print("Initializing Clients...")
        
        AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
        
//        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.COGNITO_REGIONTYPE, identityProvider: nil, unauthRoleArn: nil, authRoleArn: nil)
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
            // create the alert
            let alert = UIAlertController(title: "提醒", message: "請先登入", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.Default, handler: { action in
                self.displayLoginView(theViewController)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil))
            
            // show the alert
            theViewController.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func logOut(completionHandler: AWSContinuationBlock) {
        if self.isLoggedInWithFacebook() {
            self.fbLogout()
        }
        
        // Wipe credentials
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
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
    
    func fbLogin() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.completeFBLogin()
        } else {
            if self.fbLoginManager == nil {
                self.fbLoginManager = FBSDKLoginManager()
                self.fbLoginManager?.logInWithReadPermissions(nil) {
                    (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
                    
                    if (error != nil) {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.errorAlert("Error logging in with FB: " + error.localizedDescription)
                        }
                    } else if result.isCancelled {
                        //Do nothing
                    } else {
                        self.completeFBLogin()
                    }
                }
            }
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
        self.keyChain[FB_PROVIDER] = "YES"
        //self.completeLogin(["graph2.facebook.com" : FBSDKAccessToken.currentAccessToken().tokenString])
        let token = FBSDKAccessToken.currentAccessToken().tokenString
        print("Facebook token: \(token)")
        self.completeLogin([AWSCognitoLoginProviderKey.Facebook.rawValue : token])
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
