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
import AWSSNS
import AWSS3
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import SCLAlertView
import ObjectMapper

private let Log = Logger.defaultLogger

class AmazonClientManager : NSObject {
    static let sharedInstance = AmazonClientManager()
    
    struct AWSConstants {
        static let DEFAULT_SERVICE_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_IDENTITY_POOL_ID = "ap-northeast-1:7e09fc17-5f4b-49d9-bb50-5ca5a9e34b8a"
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS_SANDBOX/zuzurentals_development"
        static let S3_SERVICE_REGIONTYPE = AWSRegionType.APSoutheast1
        static let S3_BUCKETNAME = "zuzu.mycollection"
    }
    
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
    
    var fbLoginData: FBUserData? {
        didSet {
            if let userData = self.fbLoginData {
                self.uploadFBUserDataToS3(userData)
            }
        }
    }
    
    var transferManager: AWSS3TransferManager?
    
    private func dumpCredentialProviderInfo() {
        
        Log.info("identityId: \(self.credentialsProvider?.identityId)")
        Log.info("identityPoolId: \(self.credentialsProvider?.identityPoolId)")
        Log.info("logins: \(self.credentialsProvider?.logins)")
        Log.info("accessKey: \(self.credentialsProvider?.accessKey)")
        Log.info("secretKey: \(self.credentialsProvider?.secretKey)")
        Log.info("sessionKey: \(self.credentialsProvider?.sessionKey)")
        Log.info("expiration: \(self.credentialsProvider?.expiration)")
        
    }
    
    override init() {
        keyChain = UICKeyChainStore(service: NSBundle.mainBundle().bundleIdentifier!)
        super.init()
        
        Log.info("\(keyChain.debugDescription)")
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    // MARK: General Login
    
    func isConfigured() -> Bool {
        return !(AWSConstants.COGNITO_IDENTITY_POOL_ID == "YourCognitoIdentityPoolId" || AWSConstants.COGNITO_REGIONTYPE == AWSRegionType.Unknown)
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
        Log.info("\(logins)")
        
        var task: AWSTask?
        
        if self.credentialsProvider == nil {
            task = self.initializeCredentialsProvider(logins)
            
            Log.info("Task = \(task)")
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
                
                Log.info("Add new logins = \(merge)")
                self.credentialsProvider?.logins = merge
            }
            //Force a refresh of credentials to see if merge is necessary
            task = self.credentialsProvider?.refresh()
        }
        
        task?.continueWithBlock {
            (task: AWSTask!) -> AnyObject! in
            
            Log.info("Credential Provider Status (After FB Login):")
            self.dumpCredentialProviderInfo()

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
    
    func initializeCredentialsProvider(logins: [NSObject : AnyObject]?) -> AWSTask? {
        Log.info("Initializing Credentials Provider...")
        
        AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
        
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSConstants.COGNITO_REGIONTYPE, identityPoolId: AWSConstants.COGNITO_IDENTITY_POOL_ID)
        self.credentialsProvider?.logins = logins
        if logins == nil{
            self.credentialsProvider?.clearKeychain()
        }
        
        Log.info("Credential Provider Status (Initial):")
        self.dumpCredentialProviderInfo()
        
        let configuration = AWSServiceConfiguration(region: AWSConstants.DEFAULT_SERVICE_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        let configurationForS3 = AWSServiceConfiguration(region: AWSConstants.S3_SERVICE_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        self.transferManager = AWSS3TransferManager(configuration: configurationForS3, identifier: "S3")
        
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
            
            loginAlertView.addButton("立即登入") {
                self.fbLogin(theViewController)
            }
            
            loginAlertView.addButton("取消") {
                ///GA Tracker: Login cancelled
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
            }
            
            loginAlertView.showNotice("請登入Facebook",
                subTitle: "使用我的收藏功能，需要您使用Facebook帳戶登入\n\n日後更換裝置，收藏的物件也不會消失。豬豬快租不會張貼任何資訊到您的Facebook動態牆", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
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
            Log.info("Reloading Facebook Session")
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
        self.fbLoginData = nil
    }
    
    
    func completeFBLogin() {
        
        self.keyChain[self.FB_PROVIDER] = "YES"
        self.completeLogin(["graph.facebook.com" : FBSDKAccessToken.currentAccessToken().tokenString])
        
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
    
    // MARK: SNS Push Notifications
    
    func registerSNSEndpoint(){
        if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
            let sns = AWSSNS.defaultSNS()
            let request = AWSSNSCreatePlatformEndpointInput()
            request.token = deviceTokenString
            request.platformApplicationArn = AWSConstants.PLATFORM_APPLICATION_ARN
            sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    Log.debug("Error: \(task.error)")
                } else {
                    let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                    Log.debug("endpointArn: \(createEndpointResponse.endpointArn)")
                    NSUserDefaults.standardUserDefaults().setObject(createEndpointResponse.endpointArn, forKey: "endpointArn")
                }
                
                return nil
            })
        }
    }
    
    // MARK: S3
    
    //func uploadFBUserDataToS3(transferManager: AWSS3TransferManager, fbLoginData: FBUserData) {
    
    func uploadFBUserDataToS3(userData: FBUserData) {
        Log.debug("\(self) uploadFBUserDataToS3")
        
        let S3UploadKeyName = userData.facebookId! + ".json"
        
        //Create a test file in the temporary directory
        let uploadFileURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + S3UploadKeyName)
        let JSONString = Mapper().toJSONString(userData)
        
        
        var error: NSError? = nil
        
        if NSFileManager.defaultManager().fileExistsAtPath(uploadFileURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(uploadFileURL.path!)
            } catch let error1 as NSError {
                error = error1
            }
        }
        
        do {
            try JSONString!.writeToURL(uploadFileURL, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
        }
        
        if (error) != nil {
            Log.debug("Error: \(error!.code), \(error!.localizedDescription)");
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = uploadFileURL
        uploadRequest.key = S3UploadKeyName
        uploadRequest.bucket = AWSConstants.S3_BUCKETNAME
        
        if let S3Client = self.transferManager {
            S3Client.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
                if task.result != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        Log.debug("\(self) uploadFBUserDataToS3 sucess!")
                    })
                }
                return nil
            }
        }
    }
    
}
