//
//  AmazonClientManager.swift
//  Zuzu
//
//  Created by eechih on 1/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//


import Foundation
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
        static let S3_COLLECTION_BUCKET = "zuzu.mycollection"
        static let S3_ERROR_BUCKET = "zuzu.error"
    }
    
    enum Provider: String {
        case FB, GOOGLE
    }
    
    //Properties
    var completionHandler: AWSContinuationBlock?
    
    //Login Managers
    var fbLoginManager: FBSDKLoginManager?
    var googleSignIn: GIDSignIn?
    var googleToken: String?
    
    var credentialsProvider: AWSCognitoCredentialsProvider?
    var loginViewController: UIViewController?
    
    var fbLoginData: FBUserData? {
        didSet {
            if let userData = self.fbLoginData {
                self.uploadFBUserDataToS3(userData)
                self.registerSNSEndpoint()
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
        super.init()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Initialize Google sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GIDSignIn.sharedInstance().delegate = self
        
        // Initialize Facebook sign-in
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    // MARK: General Login
    
    func isConfigured() -> Bool {
        return !(AWSConstants.COGNITO_IDENTITY_POOL_ID == "YourCognitoIdentityPoolId" || AWSConstants.COGNITO_REGIONTYPE == AWSRegionType.Unknown)
    }
    
    func resumeSession(completionHandler: AWSContinuationBlock) {
        self.completionHandler = completionHandler
        
        if let provider = UserDefaultsUtils.getLoginProvider() {
            
            switch(provider) {
            case Provider.FB.rawValue:
                self.reloadFBSession()
            case Provider.GOOGLE.rawValue:
                 self.reloadGSession()
            default:
                assert(false, "Invalid Provider")
            }
            
        }
    }
    
    //Sends the appropriate URL based on login provider
    @available(iOS 9.0, *)
    func application(application: UIApplication,
        openURL url: NSURL, options: [String : AnyObject]) -> Bool {
            
            let sourceApplication: String? = options[UIApplicationOpenURLOptionsSourceApplicationKey] as? String
            let annotation: String? = options[UIApplicationOpenURLOptionsAnnotationKey] as? String
            
            if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
                return true
            }
            
            if GIDSignIn.sharedInstance().handleURL(url,
                sourceApplication: sourceApplication,
                annotation: annotation) {
                    return true
            }
            return false
    }
    
    @available(iOS, introduced=8.0, deprecated=9.0)
    func application(application: UIApplication,
        openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
            
            if FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation) {
                return true
            }
            
            if GIDSignIn.sharedInstance().handleURL(url,
                sourceApplication: sourceApplication,
                annotation: annotation) {
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
                
                Log.debug("Add new logins = \(merge)")
                self.credentialsProvider?.logins = merge
            }
            //Force a refresh of credentials to see if merge is necessary
            task = self.credentialsProvider?.refresh()
            Log.info("Task = \(task)")
        }
        
        task?.continueWithBlock {
            (task: AWSTask!) -> AnyObject! in
            
            Log.info("Credential Provider Status After Login:")
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
        
        let loginAlertView = SCLAlertView()
        loginAlertView.showCloseButton = false
        
        loginAlertView.addButton("Facebook帳號登入") {
            self.fbLogin(theViewController)
        }
        
        loginAlertView.addButton("Google帳號登入") {
            self.googleLogin(theViewController)
        }
        
        loginAlertView.addButton("取消") {
            ///GA Tracker: Login cancelled
            theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                action: GAConst.Action.Blocking.loginReject)
        }
        
        loginAlertView.showNotice(NSLocalizedString("login.title", comment: ""),
            subTitle: NSLocalizedString("login.body", comment: ""), colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
        
    }
    
    func logOut(completionHandler: AWSContinuationBlock) {
        if self.isLoggedInWithFacebook() {
            self.fbLogout()
        }
        
        if self.isLoggedInWithGoogle() {
            self.googleLogout()
        }
        
        UserDefaultsUtils.clearLoginProvider()
        
        // Wipe credentials
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito().wipe()
        self.credentialsProvider?.clearKeychain()
        
        AWSTask(result: nil).continueWithBlock(completionHandler)
    }
    
    func isLoggedIn() -> Bool {
        return isLoggedInWithFacebook() || isLoggedInWithGoogle()
    }
    
    // MARK: Facebook Login
    
    func isLoggedInWithFacebook() -> Bool {
        let loggedIn = FBSDKAccessToken.currentAccessToken() != nil
        
        return loggedIn
    }
    
    func reloadFBSession() {
        if let accessToken = FBSDKAccessToken.currentAccessToken() {
            
            Log.info("Reloading Facebook Session: \(accessToken.expirationDate.description)")
            self.completeFBLogin()
        }
    }
    
    func fbLogin(theViewController: UIViewController?) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            self.completeFBLogin()
        } else {
            if self.fbLoginManager == nil {
                self.fbLoginManager = FBSDKLoginManager()
            }
            
            self.fbLoginManager?.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: theViewController, handler: { (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
                
                if (error != nil) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.errorAlert("Facebook 登入發生錯誤: " + error.localizedDescription)
                    }
                    
                    ///GA Tracker: Login failed
                    //                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    //                        action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), \(error.userInfo)")
                    //
                    Log.warning("Error: \(error.userInfo)")
                    
                    self.fbLogout()
                    
                } else if result.isCancelled {
                    
                    ///GA Tracker: Login cancelled
                    //                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    //                        action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
                    
                    Log.warning("Cancelled")
                    
                    self.fbLogout()
                    
                } else {
                    
                    self.completeFBLogin()
                    
                    ///GA Tracker: Login successful
                    //                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    //                        action: GAConst.Action.MyCollection.Login, label: GAConst.Label.LoginType.Facebook)
                }
            })
        }
        
    }
    
    func fbLogout() {
        if self.fbLoginManager == nil {
            self.fbLoginManager = FBSDKLoginManager()
        }
        self.fbLoginManager?.logOut()
        self.fbLoginData = nil
    }
    
    
    func completeFBLogin() {

        UserDefaultsUtils.setLoginProvider(Provider.FB.rawValue)
        
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
    
    
    // MARK: Google Login
    
    func isLoggedInWithGoogle() -> Bool {
        
        if(self.googleSignIn == nil) {
            self.googleSignIn = GIDSignIn.sharedInstance()
        }
        
        let loggedIn = self.googleToken != nil
        return loggedIn
    }
    
    func reloadGSession() {
        
        if(self.googleSignIn == nil) {
            self.googleSignIn = GIDSignIn.sharedInstance()
        }
        Log.info("Reloading Google session")
        self.googleSignIn?.signInSilently()
    }
    
    func googleLogin(theViewController: UIViewController) {
        if(self.googleSignIn == nil) {
            self.googleSignIn = GIDSignIn.sharedInstance()
        }
        
        self.googleSignIn?.delegate = self
        
        if let uiDelegate = theViewController as? GIDSignInUIDelegate {
            self.googleSignIn?.uiDelegate = uiDelegate
        } else {
            self.googleSignIn?.allowsSignInWithWebView = false
        }
        
        self.googleSignIn?.signIn()
    }
    
    func googleLogout() {
        self.googleSignIn?.signOut()
        self.googleToken = nil
    }
    
    func completeGoogleLogin() {
        UserDefaultsUtils.setLoginProvider(Provider.GOOGLE.rawValue)
        
        if let idToken = self.googleToken {
            self.completeLogin(["accounts.google.com": idToken])
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
        let userData = self.fbLoginData?.facebookEmail
        let endpointArn = UserDefaultsUtils.getSNSEndpointArn()
        if endpointArn == nil && userData == nil{
            return
        }
        
        if let deviceTokenString = UserDefaultsUtils.getAPNDevicetoken(){
            if endpointArn != nil{
                let sns = AWSSNS.defaultSNS()
                let request = AWSSNSGetEndpointAttributesInput()
                request.endpointArn = endpointArn
                sns.getEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                    if task.error != nil {
                        Log.debug("Error: \(task.error)")
                        if task.error!.code == AWSSNSErrorType.NotFound.rawValue{
                            self.createEndpoint(deviceTokenString, userData:userData)
                        }
                    } else {
                        let getEndpointResponse = task.result as! AWSSNSGetEndpointAttributesResponse
                        Log.debug("token: \(getEndpointResponse.attributes!["Token"])")
                        Log.debug("Enabled: \(getEndpointResponse.attributes!["Enabled"])")
                        Log.debug("CustomUserData: \(getEndpointResponse.attributes!["CustomUserData"])")
                        var isUpdate = false
                        if let lastToken = getEndpointResponse.attributes!["Token"] as? String{
                            if deviceTokenString != lastToken{
                                isUpdate = true
                            }
                        }
                        
                        if let enabled = getEndpointResponse.attributes!["Enabled"] as? Bool{
                            if enabled == false{
                                isUpdate = true
                            }
                        }
                        
                        var customUserData = getEndpointResponse.attributes!["CustomUserData"] as? String
                        if customUserData == nil{
                            if userData != nil{
                                customUserData = userData
                                isUpdate = true
                            }
                        }
                        
                        if isUpdate == true{
                            self.updateEndpoint(deviceTokenString, endpointArn:endpointArn!, userData: customUserData)
                        }
                    }
                    
                    return nil
                })
            }else{
                self.createEndpoint(deviceTokenString, userData: userData)
            }
        }
    }
    
    func updateEndpoint(deviceTokenString: String, endpointArn:String, userData: String?){
        let sns = AWSSNS.defaultSNS()
        let request = AWSSNSSetEndpointAttributesInput()
        Log.debug("endpointArn: \(request.endpointArn)")
        request.endpointArn = endpointArn
        request.attributes = [NSObject:AnyObject]()
        request.attributes!["Token"] = deviceTokenString
        request.attributes!["Enabled"] = "true"
        if let customUserData = userData{
            request.attributes!["CustomUserData"] = customUserData
        }
        Log.debug("endpointArn: \(request.endpointArn)")
        Log.debug("Token: \(request.attributes!["Token"])")
        Log.debug("Enabled: \(request.attributes!["Enabled"])")
        sns.setEndpointAttributes(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
            if task.error != nil {
                Log.debug("Error: \(task.error)")
            } else {
                Log.debug("update SNS endpoint successful")
            }
            
            return nil
        })
        
    }
    
    func createEndpoint(deviceTokenString: String, userData: String?){
        if let customUserData = userData{
            let sns = AWSSNS.defaultSNS()
            let request = AWSSNSCreatePlatformEndpointInput()
            request.token = deviceTokenString
            request.customUserData = customUserData
            request.platformApplicationArn = AWSConstants.PLATFORM_APPLICATION_ARN
            sns.createPlatformEndpoint(request).continueWithExecutor(AWSExecutor.mainThreadExecutor(), withBlock: { (task: AWSTask!) -> AnyObject! in
                if task.error != nil {
                    Log.debug("Error: \(task.error)")
                } else {
                    let createEndpointResponse = task.result as! AWSSNSCreateEndpointResponse
                    Log.debug("endpointArn: \(createEndpointResponse.endpointArn)")
                    if let endpointArn = createEndpointResponse.endpointArn{
                        UserDefaultsUtils.setSNSEndpointArn(endpointArn)
                    }
                }
                
                return nil
            })
        }
    }
    
    
    // MARK: S3
    
    private func prepareLocalFile(fileName: String, stringContent: String) -> NSURL? {
        
        var tempFileURL: NSURL?
        
        //Create a test file in the temporary directory
        let uploadFileURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + fileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(uploadFileURL.path!) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(uploadFileURL.path!)
            } catch let error as NSError {
                Log.debug("Error: \(error.code), \(error.localizedDescription)")
            }
        }
        
        do {
            
            try stringContent.writeToURL(uploadFileURL, atomically: true, encoding: NSUTF8StringEncoding)
            
            tempFileURL = uploadFileURL
            
        } catch let error as NSError {
            Log.debug("Error: \(error.code), \(error.localizedDescription)")
        }
        
        return tempFileURL
    }
    
    private func uploadToS3(key: String, body: NSURL, bucket: String) {
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.body = body
        uploadRequest.key = key
        uploadRequest.bucket = bucket
        
        if let s3Client = self.transferManager {
            s3Client.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
                if task.result != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        Log.debug("Success!")
                    })
                }
                return nil
            }
        }
        
    }
    
    func logErrorDataToS3(errorString: String) {
        Log.enter()
        
        let randomNumber = arc4random()
        var s3UploadKeyName = "\(NSDate().timeIntervalSince1970 * 1000)\(randomNumber).txt"
        
        if let deviceId = UIDevice.currentDevice().identifierForVendor?.UUIDString {
            s3UploadKeyName = "\(deviceId).txt"
        }
        
        if let localFile = prepareLocalFile(s3UploadKeyName, stringContent: errorString) {
            
            uploadToS3(s3UploadKeyName, body: localFile, bucket: AWSConstants.S3_ERROR_BUCKET)
            
        }
    }
    
    func uploadFBUserDataToS3(userData: FBUserData) {
        Log.enter()
        
        let randomNumber = arc4random()
        
        var s3UploadKeyName = "user\(NSDate().timeIntervalSince1970 * 1000)\(randomNumber).json"
        
        if let fbId = userData.facebookId {
            s3UploadKeyName = fbId + ".json"
        }
        
        if let jsonString = Mapper().toJSONString(userData),
            let localFile = prepareLocalFile(s3UploadKeyName, stringContent: jsonString) {
                
                uploadToS3(s3UploadKeyName, body: localFile, bucket: AWSConstants.S3_COLLECTION_BUCKET)
                
        }
        
        Log.exit()
    }
    
}

extension AmazonClientManager: GIDSignInDelegate {
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
        withError error: NSError!) {
            if (error == nil) {
                
                Log.debug(user.description)
                
                // Perform any operations on signed in user here.
                let idToken = user.authentication.idToken // Safe to send to the server

                let userId = user.userID // For client-side use only!
                let name = user.profile.name
                let email = user.profile.email
                
                if self.googleToken == nil {
                    self.googleToken = idToken;
                    self.completeGoogleLogin()
                    
                    ///GA Tracker: Login successful
                    if let viewController = signIn.uiDelegate as? UIViewController {
                        viewController.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                            action: GAConst.Action.MyCollection.Login, label: GAConst.Label.LoginType.Google)
                    }
                }
            } else {
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.errorAlert("Google登入發生錯誤: " + error.localizedDescription)
                }
                
                ///GA Tracker: Login failed
                if let viewController = signIn.uiDelegate as? UIViewController {
                    viewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                        action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Google), \(error.localizedDescription)")
                }
                
                Log.warning("Error: \(error.userInfo), \(error.localizedDescription)")
            }
    }
}
