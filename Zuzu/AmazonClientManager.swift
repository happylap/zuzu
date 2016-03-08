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
import AWSS3
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit
import SCLAlertView
import ObjectMapper

private let Log = Logger.defaultLogger

/// Notification that is generated when login is done.
let UserLoginNotification = "UserLoginNotification"
let UserLogoutNotification = "UserLogoutNotification"

class AmazonClientManager : NSObject {
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: AmazonClientManager {
        struct Singleton {
            static let instance = AmazonClientManager()
        }
        
        return Singleton.instance
    }
    
    // MARK: Private Members
    private struct AWSConstants {
        static let DEFAULT_SERVICE_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_REGIONTYPE = AWSRegionType.APNortheast1
        static let COGNITO_IDENTITY_POOL_ID = "ap-northeast-1:7e09fc17-5f4b-49d9-bb50-5ca5a9e34b8a"
        static let PLATFORM_APPLICATION_ARN = "arn:aws:sns:ap-northeast-1:994273935857:app/APNS_SANDBOX/zuzurentals_development"
        static let S3_SERVICE_REGIONTYPE = AWSRegionType.APSoutheast1
        static let S3_COLLECTION_BUCKET = "zuzu.mycollection"
        static let S3_ERROR_BUCKET = "zuzu.error"
    }
    
    private enum ErrorType: Int {
        case FacebookFailure
        case GoogleFailure
        case ZuzuFailure
    }
    
    //Properties
    private var completionHandler: AWSContinuationBlock?
    
    //Login Managers
    private var fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
    private var googleSignIn: GIDSignIn = GIDSignIn.sharedInstance()
    
    //Login View Controller
    private var loginViewController: UIViewController?
    
    //S3
    private var transferManager: AWSS3TransferManager?
    
    //CognitoCredentialsProvider
    private var credentialsProvider: AWSCognitoCredentialsProvider?
    
    private var transientUserProfile: UserProfile?
    
    // MARK: Public Members
    //User Login Data
    var currentUserProfile: UserProfile? {
        get {
            return UserDefaultsUtils.getUserProfile()
        }
    }
    
    var currentUserToken: String? {
        get {
            
            if(!self.isLoggedIn()) {
                return nil
            }
            
            if let provider = self.currentUserProfile?.provider {
                
                switch(provider) {
                case Provider.FB:
                    
                    return FBSDKAccessToken.currentAccessToken().tokenString
                    
                case Provider.GOOGLE:
                    
                    return self.googleSignIn.currentUser?.authentication?.idToken
                    
                default:
                    assert(false, "Invalid Provider")
                    return nil
                }
            } else {
                
                assert(false, "No previous login provider, but the user is logged in")
                return nil
            }
        }
    }
    
    // MARK: Private UI Helpers
    
    private func errorAlert(message: String) {
        let errorAlert = UIAlertController(title: "Error", message: "\(message)", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Ok", style: .Default) { (alert: UIAlertAction) -> Void in }
        
        errorAlert.addAction(okAction)
        
        self.loginViewController?.presentViewController(errorAlert, animated: true, completion: nil)
    }
    
    // MARK: Private S3 Utils
    
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
                if(task.completed) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        Log.debug("Success!")
                    })
                }
                return nil
            }
        }
        
    }
    
    private func logErrorDataToS3(errorString: String) {
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
    
    private func uploadUserDataToS3(userData: UserProfile) {
        Log.enter()
        
        Log.debug(userData.description)
        
        let randomNumber = arc4random()
        
        var s3UploadKeyName = "user\(NSDate().timeIntervalSince1970 * 1000)\(randomNumber).json"
        
        if let userId = userData.id {
            if let provider = userData.provider {
                s3UploadKeyName = "\(provider)_\(userId).json"
            } else {
                s3UploadKeyName = "\(userId).json"
            }
        }
        
        if let jsonString = Mapper().toJSONString(userData),
            let localFile = prepareLocalFile(s3UploadKeyName, stringContent: jsonString) {
                
                uploadToS3(s3UploadKeyName, body: localFile, bucket: AWSConstants.S3_COLLECTION_BUCKET)
                
        }
        
        Log.exit()
    }
    
    // MARK: Private Utils
    
    private class func toUserProfile(result : AnyObject?) -> UserProfile? {
        
        if let result = result {
            let userProfile = UserProfile(provider: Provider.FB)
            if let strId: String = result.objectForKey("id") as? String {
                userProfile.id = strId
            }
            if let strEmail: String = result.objectForKey("email") as? String {
                userProfile.email = strEmail
            }
            if let strName: String = result.objectForKey("name") as? String {
                userProfile.name = strName
            }
            if let strGender: String = result.objectForKey("gender") as? String {
                userProfile.gender = strGender
            }
            if let strBirthday: String = result.objectForKey("birthday") as? String {
                userProfile.birthday = strBirthday
            }
            if let strPictureURL: String = result.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String {
                userProfile.pictureUrl = strPictureURL
            }
            
            return userProfile
            
        } else {
            return nil
        }
    }
    
    private func dumpCognitoCredentialProviderInfo() {
        Log.info("identityId: \(self.credentialsProvider?.identityId)")
        Log.info("identityPoolId: \(self.credentialsProvider?.identityPoolId)")
        Log.info("logins: \(self.credentialsProvider?.logins)")
        Log.info("accessKey: \(self.credentialsProvider?.accessKey)")
        Log.info("secretKey: \(self.credentialsProvider?.secretKey)")
        Log.info("sessionKey: \(self.credentialsProvider?.sessionKey)")
        Log.info("expiration: \(self.credentialsProvider?.expiration)")
    }
    
    private func tryRegisterZuzuUser(userProfile : UserProfile, handler: (result: Bool) -> Void){
        Log.enter()
        
        if let userId = userProfile.id {
            
            let zuzuUser = ZuzuUser()
            zuzuUser.id = userId
            
            zuzuUser.provider = userProfile.provider?.rawValue
            zuzuUser.email = userProfile.email
            zuzuUser.name = userProfile.name
            zuzuUser.gender = userProfile.gender
            if let birthday = userProfile.birthday {
                zuzuUser.birthday = CommonUtils.getUTCDateFromString(birthday)
            }
            zuzuUser.pictureUrl = userProfile.pictureUrl
            
            
            ZuzuWebService.sharedInstance.isExistUser(userId){(result, error) -> Void in
                
                let delay =  0 //* Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                
                dispatch_after(time, dispatch_get_main_queue(), {
                    if error != nil{
                        Log.debug("isExistUser, error = \(error)")
                        handler(result: false)
                        return
                    }
                    
                    if(result == true) {
                        /// Update user account data
                        ZuzuWebService.sharedInstance.updateUser(zuzuUser){
                            (result, error) -> Void in
                            
                            if error != nil{
                                Log.debug("updateUser, error = \(error)")
                            }
                            
                        }
                        
                        /// We can say the user is logged in even the update is not successful
                        handler(result: true)
                        
                        
                    } else {
                        /// Create new user account
                        ZuzuWebService.sharedInstance.createUser(zuzuUser){(result, error) -> Void in
                            
                            Log.debug("createUser")
                            
                            if error != nil{
                                Log.debug("createUser, error = \(error)")
                                handler(result: false)
                                return
                            }
                            
                            handler(result: true)
                        }
                    }
                    
                })
                
            }
            
        } else {
            
            assert(false, "UserId cannot be nil")
            
        }
        
        Log.exit()
    }
    
    private func addLoginForCredentialsProvider(logins: [NSObject : AnyObject]?) -> AWSTask? {
        Log.enter()
        
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
        return self.credentialsProvider?.refresh()
    }
    
    private func initializeCredentialsProvider(logins: [NSObject : AnyObject]?) -> AWSTask? {
        Log.enter()
        
        #if DEBUG
            AWSLogger.defaultLogger().logLevel = AWSLogLevel.Verbose
        #else
            AWSLogger.defaultLogger().logLevel = AWSLogLevel.Info
        #endif
        
        ///Init AWSCognitoCredentialsProvider
        self.credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSConstants.COGNITO_REGIONTYPE, identityPoolId: AWSConstants.COGNITO_IDENTITY_POOL_ID)
        
        /// Clear previous IdentityId when we find the user has never logged to Cognito for
        // this installation. This would avoid the use of previous IdentityId
        // when switching to another login provider's account
        if(UserDefaultsUtils.getCognitoIdentityId() == nil) {
            // No previous Cognito identityId for current installation.
            // We don't need the previous identityId in the keychain
            Log.debug("Clear previous identityId")
            self.credentialsProvider?.clearKeychain()
        }
        
        self.credentialsProvider?.logins = logins
        
        
        if logins == nil{
            self.credentialsProvider?.clearKeychain()
        }
        
        self.dumpCognitoCredentialProviderInfo()
        
        ///Init Default AWSServiceConfiguration
        let configuration = AWSServiceConfiguration(region: AWSConstants.DEFAULT_SERVICE_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        ///Init S3 AWSServiceConfiguration
        let configurationForS3 = AWSServiceConfiguration(region: AWSConstants.S3_SERVICE_REGIONTYPE, credentialsProvider: self.credentialsProvider)
        
        self.transferManager = AWSS3TransferManager.defaultS3TransferManager()
        AWSS3TransferManager.registerS3TransferManagerWithConfiguration(configurationForS3, forKey: "S3")
        
        return self.credentialsProvider?.getIdentityId()
    }
    
    func identityDidChange(notification: NSNotification!) {
        if let userInfo = notification.userInfo as? [String: AnyObject] {
            Log.debug("userInfo = \(userInfo)")
            Log.debug("identity changed from: \(userInfo[AWSCognitoNotificationPreviousId]) to: \(userInfo[AWSCognitoNotificationNewId])")
            
            /// Save the latest Cognito identityId
            if let identityId = userInfo[AWSCognitoNotificationNewId] as? String {
                UserDefaultsUtils.setCognitoIdentityId(identityId)
            }
        }
    }
    
    override init() {
        super.init()
        
        /// IdentityId will be changed when a new provider login is set
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"identityDidChange:",
            name:AWSCognitoIdentityIdChangedNotification,
            object:nil)
    }
    
    // MARK: AppDelegate Handlers
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Initialize Google sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GIDSignIn.sharedInstance().delegate = self
        
        // Initialize Facebook sign-in
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
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
    
    // MARK: Public General Login
    
    func isCredentailsProviderExist() -> Bool {
        return self.credentialsProvider != nil
    }
    
    func resumeSession(completionHandler: AWSContinuationBlock) {
        Log.enter()
        
        self.completionHandler = completionHandler
        
        if let provider = self.currentUserProfile?.provider {
            
            Log.warning("\(self.currentUserProfile?.id), \(provider)")
            
            switch(provider) {
            case Provider.FB:
                if(self.isLoggedInWithFacebook()) {
                    self.reloadFBSession()
                } else {
                    Log.error("Reloading Facebook Session: Failure")
                }
            case Provider.GOOGLE:
                if(self.isLoggedInWithGoogle()) {
                    self.reloadGSession()
                } else {
                    Log.error("Reloading Google Session: Failure")
                }
            default:
                assert(false, "Invalid Provider")
            }
        } else {
            
            /// [Backward Compatible]
            //When there is no login provider saved in UserDefaults, Force resuming FB session
            if(FBSDKAccessToken.currentAccessToken() != nil) {
                self.reloadFBSession()
            }
            
        }
        
        Log.exit()
    }
    
    private func logOutAll() {
        
        if self.isLoggedInWithFacebook() {
            self.fbLogout()
        }
        
        if self.isLoggedInWithGoogle() {
            self.googleLogout()
        }
        
        // Clear current user profile
        UserDefaultsUtils.clearUserProfile()
        
        // Wipe credentials
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito()?.wipe()
        
        self.credentialsProvider?.clearCredentials()
        self.credentialsProvider?.clearKeychain()
    }
    
    private func cancelLogin() {
        
        LoadingSpinner.shared.stop()
        
        /// Revert the sing-in
        self.logOutAll()
    }
    
    private func failLogin(type: ErrorType) {
        
        Log.debug("Error = \(type)")
        
        let msgTitle = "登入失敗"
        let okButton = "知道了"
        var subTitle: String?
        
        LoadingSpinner.shared.stop()
        
        switch(type) {
        case .FacebookFailure:
            subTitle = "很抱歉！無法為您登入Facebook，請稍候再試！"
        case .GoogleFailure:
            subTitle = "很抱歉！無法為您登入Google，請稍候再試！"
        case .ZuzuFailure:
            subTitle = "很抱歉！由於網路問題目前無法為您登入，請稍候再試！"
            
        }
        
        if let subTitle = subTitle {
            
            let alertView = SCLAlertView()
            alertView.showCloseButton = true
            
            alertView.showInfo(msgTitle, subTitle: subTitle, closeButtonTitle: okButton, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
        }
        
        /// Revert the sing-in
        self.logOutAll()
        
        AWSTask(error: NSError(domain: "zuzu.com", code: type.rawValue, userInfo: nil)).continueWithBlock(self.completionHandler!)
        
    }
    
    private func completeLogin(logins: [NSObject : AnyObject]?) {
        
        Log.info("\(logins)")
        
        var task: AWSTask?
        
        if self.credentialsProvider == nil {
            
            task = self.initializeCredentialsProvider(logins)
            
        } else {
            
            task = self.addLoginForCredentialsProvider(logins)
        }
        
        Log.info("Task = \(task)")
        
        task?.continueWithBlock {
            (task: AWSTask!) -> AnyObject! in
            
            Log.info("Credential Provider With Login")
            self.dumpCognitoCredentialProviderInfo()
            
            if (task.error != nil) {
                assert(false, "Log in failed. Cannot get Cognito IdentityId")
                return nil
            }
            
            /// User already created before, no need to check with Zuzu backend again
            if let _ = self.currentUserProfile {
                Log.info("currentUserProfile exists. User should already be created")
                return nil
            }
            
            ///Try registering the authenticated users (FB/GOOGLE) with Zuzu backend
            if let userProfile = self.transientUserProfile {
                
                self.tryRegisterZuzuUser(userProfile, handler: { (result) -> Void in
                    if(result) {
                        
                        LoadingSpinner.shared.stop()
                        
                        /// Sign-in completed
                        Log.debug("postNotificationName: \(UserLoginNotification)")
                        NSNotificationCenter.defaultCenter().postNotificationName(UserLoginNotification, object: self, userInfo: ["userData": userProfile])
                        
                        Log.warning("Persist UserProfile")
                        UserDefaultsUtils.setUserProfile(userProfile)
                        
                        self.transientUserProfile = nil
                        
                        AWSTask(result: nil).continueWithBlock(self.completionHandler!)
                        
                    } else {
                        /// Zuzu Web Api failure
                        self.failLogin(.ZuzuFailure)
                    }
                })
                
            } else {
                assert(false, "Current Profile should not be nil after successfully sing-in")
            }
            
            return nil
        }
    }
    
    func loginFromView(theViewController: UIViewController, mode: Int = 1, withCompletionHandler completionHandler: AWSContinuationBlock) {
        Log.enter()
        
        self.completionHandler = completionHandler
        self.loginViewController = theViewController
        
        
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarPurchaseLoginView") as? RadarPurchaseLoginViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.loginMode = mode
            
            vc.cancelHandler = { () -> Void in
                ///GA Tracker: Login cancelled
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    action: GAConst.Action.Blocking.loginReject)
            }
            
            vc.fbLoginHandler = { () -> Void in
                self.fbLogin(theViewController)
            }
            vc.googleLoginHandler = { () -> Void in
                self.googleLogin(theViewController)
            }
            theViewController.presentViewController(vc, animated: true, completion: nil)
        }
        
        Log.exit()
        
    }
    
    func logOut(completionHandler: AWSContinuationBlock) {
        
        Log.enter()
        
        self.logOutAll()
        
        AWSTask(result: nil).continueWithBlock(completionHandler)
        
        Log.debug("postNotificationName: \(UserLogoutNotification)")
        NSNotificationCenter.defaultCenter().postNotificationName(UserLogoutNotification, object: self, userInfo: nil)
        
        Log.exit()
    }
    
    func isLoggedIn() -> Bool {
        if let _ = self.currentUserProfile {
            return self.isLoggedInWithFacebook() || self.isLoggedInWithGoogle()
        } else {
            return false
        }
    }
    
    // MARK: Public Facebook Login
    
    func isLoggedInWithFacebook() -> Bool {
        
        if let _ = self.currentUserProfile {
            return FBSDKAccessToken.currentAccessToken() != nil
        } else {
            return false
        }
        
    }
    
    func reloadFBSession() {
        
        Log.debug("Reloading Facebook Session: \(FBSDKAccessToken.currentAccessToken()?.expirationDate)")
        
        /// Calling Graph API would refresh token
        self.requestFBUserData() { (result: AnyObject!, error : NSError!) -> Void in
            
            if(error != nil) {
                /// Cannot get user data. No need to complain since we are still logged in
                self.failLogin(.FacebookFailure)
                Log.warning("FBSDKGraphRequest Error: \(error.localizedDescription)")
            } else {
                /// Update user data
                
                self.transientUserProfile = self.dynamicType.toUserProfile(result)
                
                self.completeFBLogin()
                
            }
            
        }
    }
    
    func fbLogin(theViewController: UIViewController) {
        
        ///Already signed in
        if self.isLoggedInWithFacebook() {
            Log.debug("FB Already Sign-in")
            return
        }
        
        Log.debug("Login FB")
        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(theViewController.view)
        
        self.fbLoginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: theViewController, handler: { (result: FBSDKLoginManagerLoginResult!, error : NSError!) -> Void in
            
            if (error != nil) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.failLogin(.FacebookFailure)
                }
                
                ///GA Tracker: Login failed
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), \(error.localizedDescription), \(error.userInfo)")
                
                Log.warning("FB Login Error: \(error.userInfo), \(error.localizedDescription)")
                
            } else if result.isCancelled {
                
                ///GA Tracker: Login cancelled
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                    action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
                
                Log.warning("FB Login Cancelled")
                
                self.cancelLogin()
                
            } else {
                self.requestFBUserData() { (result: AnyObject!, error : NSError!) -> Void in
                    
                    if(error != nil) {
                        
                        Log.warning("FBSDKGraphRequest Error: \(error.localizedDescription)")
                        
                        self.failLogin(.FacebookFailure)
                        
                        ///GA Tracker: Fetch user data failed
                        self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                            action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), \(error.localizedDescription)")
                        
                    } else {
                        
                        self.transientUserProfile = self.dynamicType.toUserProfile(result)
                        
                        self.completeFBLogin()
                    }
                    
                }
                
                ///GA Tracker: Login successful
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                    action: GAConst.Action.MyCollection.Login, label: GAConst.Label.LoginType.Facebook)
            }
        })
    }
    
    func requestFBUserData(handler: (result: AnyObject!, error: NSError!) -> Void){
        //Query Facebook User Data
        FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields":"id, email, birthday, gender, name, picture.type(large)"]).startWithCompletionHandler { (connection, result, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue()) {
                handler(result: result, error: error)
            }
            
        }
    }
    
    func fbLogout() {
        Log.enter()
        self.fbLoginManager.logOut()
        Log.exit()
    }
    
    private func completeFBLogin() {
        
        Log.debug("FB token: \(FBSDKAccessToken.currentAccessToken()?.tokenString)")
        Log.debug("FB token: \(FBSDKAccessToken.currentAccessToken()?.expirationDate)")
        
        if let accessToken = FBSDKAccessToken.currentAccessToken() {
            self.completeLogin(["graph.facebook.com" : accessToken.tokenString])
        } else {
            assert(false, "AccessToken should not be nil")
        }
    }
    
    
    // MARK: Public Google Login
    
    func isLoggedInWithGoogle() -> Bool {
        
        if let _ = self.currentUserProfile {
            if let _ = self.googleSignIn.currentUser?.authentication {
                
                return true
                
            } else {
                if GIDSignIn.sharedInstance().hasAuthInKeychain() {
                    Log.debug("has AuthInKeychain")
                    return true
                } else {
                    Log.debug("no AuthInKeychain")
                    return false
                }
            }
        } else {
            return false
        }
    }
    
    func reloadGSession() {
        Log.debug("Reloading Google Session: \(self.googleSignIn.currentUser?.authentication?.idTokenExpirationDate)")
        
        self.googleSignIn.signInSilently()
    }
    
    func googleLogin(theViewController: UIViewController) {
        
        ///Already signed in
        if let _ = self.googleSignIn.currentUser?.authentication?.idToken {
            Log.debug("Google Already Sign-in")
            return
        }
        
        self.googleSignIn.delegate = self
        self.googleSignIn.uiDelegate = self
        
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.3)
        LoadingSpinner.shared.startOnView(theViewController.view)
        
        Log.debug("Login Google")
        self.googleSignIn.signIn()
    }
    
    func googleLogout() {
        Log.enter()
        self.googleSignIn.signOut()
        Log.exit()
    }
    
    private func completeGoogleLogin() {
        
        Log.debug("Google token: \(self.googleSignIn.currentUser?.authentication?.idToken)")
        Log.debug("Google token: \(self.googleSignIn.currentUser?.authentication?.idTokenExpirationDate)")
        
        Log.debug("Google access token: \(self.googleSignIn.currentUser?.authentication?.accessToken)")
        Log.debug("Google accesstoken: \(self.googleSignIn.currentUser?.authentication?.accessTokenExpirationDate)")
        
        if let idToken = self.googleSignIn.currentUser.authentication.idToken {
            self.completeLogin(["accounts.google.com": idToken])
        } else {
            assert(false, "IdToken should not be nil")
        }
        
    }
}

// MARK: Google GIDSignInDelegate
// For getting sign-in response
extension AmazonClientManager: GIDSignInDelegate {
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!,
        withError error: NSError!) {
            Log.enter()
            
            if (error != nil) {
                
                if(error.code == -5) {
                    
                    ///GA Tracker: Login failed
                    if let viewController = signIn.uiDelegate as? UIViewController {
                        viewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                            action: GAConst.Action.Blocking.LoginCancel, label: "\(GAConst.Label.LoginType.Google), \(error.description)")
                    }
                    
                    Log.warning("Google Login Cancelled: \(error.userInfo), \(error.description)")
                    
                    self.cancelLogin()
                    
                } else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.failLogin(.GoogleFailure)
                    }
                    
                    ///GA Tracker: Login failed
                    if let viewController = signIn.uiDelegate as? UIViewController {
                        viewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                            action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Google), \(error.localizedDescription), \(error.userInfo)")
                    }
                    
                    Log.warning("Google Login Error: \(error.userInfo), \(error.localizedDescription)")
                }
                
            } else {
                
                // Perform any operations on signed in user here.
                
                if let idToken = user.authentication.idToken { // Safe to send to the server
                    
                    //Save Google User Data
                    let userProfile = UserProfile(provider: Provider.GOOGLE)
                    userProfile.id = user.userID // For client-side use only!
                    
                    userProfile.name = user.profile.name
                    
                    userProfile.email = user.profile.email
                    
                    if let pictureUrl = user.profile.imageURLWithDimension(200) {
                        userProfile.pictureUrl = pictureUrl.URLString
                    }
                    
                    self.transientUserProfile = userProfile
                    
                    self.completeGoogleLogin()
                    
                    ///GA Tracker: Login successful
                    if let viewController = signIn.uiDelegate as? UIViewController {
                        viewController.trackEventForCurrentScreen(GAConst.Catrgory.MyCollection,
                            action: GAConst.Action.MyCollection.Login, label: GAConst.Label.LoginType.Google)
                    }
                }
                
            }
    }
}

// MARK: Google GIDSignInUIDelegate
// For handling Google Signin UI Controller
extension AmazonClientManager: GIDSignInUIDelegate {
    
    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
        Log.enter()
    }
    
    // Present a view that prompts the user to sign in with Google
    func signIn(signIn: GIDSignIn!,
        presentViewController viewController: UIViewController!) {
            Log.enter()
            self.loginViewController?.presentViewController(viewController, animated: true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func signIn(signIn: GIDSignIn!,
        dismissViewController viewController: UIViewController!) {
            Log.enter()
            self.loginViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
