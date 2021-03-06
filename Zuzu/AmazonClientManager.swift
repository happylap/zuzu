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


enum LoginResult: Int {
    case Success
    case Cancelled
    case Skip
}

enum LoginStatus: Int {
    case New
    case Resume
}

enum LoginErrorType: Int {
    case FacebookFailure = 1
    case FacebookCancel = 2
    case GoogleFailure = 3
    case GoogleCancel = 4
    case ZuzuFailure = 5
    case ZuzuCancel = 6
}

class AmazonClientManager: NSObject {

    //Share Instance for interacting with the AmazonClientManager
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
        static let S3_SERVICE_REGIONTYPE = AWSRegionType.APSoutheast1
        static let S3_COLLECTION_BUCKET = "zuzu.mycollection"
        static let S3_ERROR_BUCKET = "zuzu.error"
    }

    //Properties
    private var completionHandler: AWSContinuationBlock?

    //The custom Cognito auth provider name
    private let customProviderName = "com.lap.zuzu.login"

    /// Login transient data
    //The provider type for the login in progress
    private var currentProvider: Provider?
    //The user profile for the social login (FB/ GOOGLE) in progress
    private var transientUserProfile: UserProfile?

    /// Login Managers
    private var fbLoginManager: FBSDKLoginManager = FBSDKLoginManager()
    private var googleSignIn: GIDSignIn = GIDSignIn.sharedInstance()
    private var zuzuAuthClient: ZuzuAuthenticator = ZuzuAuthenticator()

    //Login View Controller
    private var loginViewController: UIViewController?

    //S3
    private var transferManager: AWSS3TransferManager?

    //CognitoCredentialsProvider
    private var credentialsProvider: AWSCognitoCredentialsProvider?

    private var currentTimer: NSTimer?

    // MARK: Public Members
    //User Login Data
    //    var currentUserProfile: ZuzuUser? {
    //        get {
    //            return UserDefaultsUtils.getUserProfile()
    //        }
    //    }

    var currentUserToken: (provider: Provider, userId: String, token: String?)? {
        get {

            //TODO: Allow token access even when the logged in process is not completely finished
            //Since we need the token to finish our login process. Need to refine the whole process.

            if let provider = UserDefaultsUtils.getLoginProvider(), userId = UserDefaultsUtils.getLoginUser(),
                token = self.getTokenByProvider(provider) {

                return (provider, userId, token)

            } else {
                return nil
            }
        }
    }

    // MARK: Private UI Helpers

    private func getTokenByProvider(provider: Provider) -> String? {

        switch(provider) {
        case Provider.FB:

            return FBSDKAccessToken.currentAccessToken()?.tokenString

        case Provider.GOOGLE:

            if let token = self.googleSignIn.currentUser?.authentication?.idToken {
                return token
            } else {
                return UserDefaultsUtils.getGoogleToken()
            }

        case Provider.ZUZU:

            return ZuzuAccessToken.currentAccessToken.token
        }

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

    private class func toUserProfile(result: AnyObject?) -> UserProfile? {

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

    private func tryRegisterZuzuUser(userProfile: UserProfile, handler: (userId: String?, result: Bool) -> Void) {
        Log.enter()

        if let userEmail = userProfile.email {

            ZuzuWebService.sharedInstance.checkEmail(userEmail) {(emailExisted, provider, error) -> Void in

                if error != nil {
                    Log.debug("checkEmail, error = \(error)")
                    handler(userId: nil, result: false)
                    return
                }

                if(emailExisted) {

                    if let provider = self.currentProvider,
                        let token = self.getTokenByProvider(provider) {

                        ZuzuWebService.sharedInstance.loginBySocialToken(token, provider: provider.rawValue, handler: { (userId, email, error) in

                            if error != nil {
                                Log.debug("loginBySocialToken, error = \(error)")
                                handler(userId: nil, result: false)
                                return
                            }

                            handler(userId: userId, result: true)

                        })

                    }

                } else {
                    /// Create new user account

                    if let provider = self.currentProvider {

                        let zuzuUser = ZuzuUser()
                        zuzuUser.provider = provider // The login provider for the account creation
                        zuzuUser.email = userProfile.email
                        zuzuUser.name = userProfile.name
                        zuzuUser.gender = userProfile.gender
                        if let birthday = userProfile.birthday {
                            zuzuUser.birthday = CommonUtils.getUTCDateFromString(birthday)
                        }
                        zuzuUser.pictureUrl = userProfile.pictureUrl

                        ZuzuWebService.sharedInstance.registerUser(zuzuUser) {(userId, error) -> Void in

                            Log.debug("createUser")

                            if error != nil {
                                Log.debug("createUser, error = \(error)")
                                handler(userId: nil, result: false)
                                return
                            }

                            handler(userId: userId, result: true)

                        }

                    } else {
                        assert(false, "No login provider for current user")
                        handler(userId: nil, result: false)
                    }

                }

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

        let identityProvider = ZuzuAuthenticatedIdentityProvider(providerName: self.customProviderName, authenticator: self.zuzuAuthClient, regionType: AWSConstants.COGNITO_REGIONTYPE, identityId: nil, identityPoolId: AWSConstants.COGNITO_IDENTITY_POOL_ID, logins: nil)


        ///Init AWSCognitoCredentialsProvider
        self.credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: AWSConstants.COGNITO_REGIONTYPE,
            identityProvider: identityProvider,
            unauthRoleArn:nil,
            authRoleArn:nil)

        /// [Remove Cognito IdentityId for previous installation]
        // Clear previous IdentityId if the user has never logged to Cognito for this installation.
        // This would avoid the use of previous Cognito IdentityId when switching to another login provider's account
        if(UserDefaultsUtils.getLoginUser() == nil) {
            // Not login for current installation.
            // We don't need the previous identityId in the keychain
            Log.debug("Clear previous identityId")
            self.credentialsProvider?.clearKeychain()
        }

        if logins == nil {
            self.credentialsProvider?.clearKeychain()
        }

        self.credentialsProvider?.logins = logins

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
        }
    }

    override init() {
        super.init()

        /// IdentityId will be changed when a new provider login is set
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:#selector(AmazonClientManager.identityDidChange(_:)),
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

        //Set sign-in language by device locale
        var language = "zh-TW"
        if let langId = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String,
            let countryId = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String {
            language = "\(langId)-\(countryId)" // en-US on my machine
            Log.debug("current language = \(language)")
        }

        GIDSignIn.sharedInstance().language = language

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

    /// Setup a timer that trigger token refreshing just after the token times out
    internal func triggerTokenRefreshingTimer() {

        var interval = 0.0
        var refreshTime: NSDate?
        var timerProvider: String?

        self.currentTimer?.invalidate()

        if let provider = UserDefaultsUtils.getLoginProvider() {
            switch(provider) {
            case .FB:
                if let expiryTime = FBSDKAccessToken.currentAccessToken()?.expirationDate {
                    refreshTime = expiryTime.add(seconds: 1)
                }
                timerProvider = provider.rawValue
            case .GOOGLE:
                if let expiryTime = self.googleSignIn.currentUser?.authentication?.idTokenExpirationDate {
                    refreshTime = expiryTime.add(seconds: 1)
                }

                timerProvider = provider.rawValue
            case Provider.ZUZU:
                // TODO
                Log.info("provider is \(provider.rawValue)")
                timerProvider = provider.rawValue
            }
        }

        if let refreshTime = refreshTime, let timerProvider = timerProvider {
            Log.debug("Start token refreshing timer, trigger time = \(refreshTime)")

            /// If the interval is less than 0 (refresh time has passed), the timer will be triggered almost immediately
            interval = refreshTime.timeIntervalSinceNow

            self.currentTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: #selector(AmazonClientManager.onTokenNeedRefreshing(_:)), userInfo: ["provider", timerProvider], repeats: false)
        }

    }

    /// Cancel the timer
    internal func stopTokenRefreshingTimer() {

        self.currentTimer?.invalidate()

    }

    // Token refreshing timer callback method
    func onTokenNeedRefreshing(timer: NSTimer) {

        Log.enter()

        self.resumeSession { (task) -> AnyObject? in

            Log.debug("The login session is resumed")
            return nil
        }

    }

    func resumeSession(completionHandler: AWSContinuationBlock) {
        Log.enter()

        self.completionHandler = completionHandler

        if let userId = self.currentUserToken?.userId {

            if let provider = UserDefaultsUtils.getLoginProvider() {

                Log.warning("Current Login: \(userId), \(provider)")

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
                case Provider.ZUZU:
                    if(self.isLoggedInWithZuzu()) {
                        self.reloadZuzuSession()
                    } else {
                        Log.error("Reloading Zuzu Session: Failure")
                    }
                }
            }

        }

        Log.exit()
    }

    /// [Backward Compatible]
    func resumeSessionForUpgrade(provider: Provider, completionHandler: AWSContinuationBlock) {
        Log.enter()

        self.completionHandler = completionHandler

        switch(provider) {
        case .FB:
            //v0.93.1 -> v1.1: There is no saved userID, provider in UserDefaults, still resume FB session anyway
            if(FBSDKAccessToken.currentAccessToken() != nil) {

                self.reloadFBSession()

            }
        case .GOOGLE:
            //v1.0 -> v1.1: There is no Google token, still resume Google session anyway
            // Google's token will be nil when app is relaunched
            if(self.isLoggedInWithGoogle()) {

                self.reloadGSession()

            }
        default: break
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

        if self.isLoggedInWithZuzu() {
            self.zuzuLogout()
        }

        // Clear free trial history
        UserDefaultsUtils.clearUsedFreeTrial(ZuzuProducts.ProductRadarFreeTrial1)
        UserDefaultsUtils.clearUsedFreeTrial(ZuzuProducts.ProductRadarFreeTrial2)

        // Clear current user profile
        UserDefaultsUtils.clearUserProfile()

        // Clear current login provider/user
        UserDefaultsUtils.clearLoginProvider()
        UserDefaultsUtils.clearLoginUser()

        // Wipe credentials
        self.credentialsProvider?.logins = nil
        AWSCognito.defaultCognito()?.wipe()

        self.credentialsProvider?.clearCredentials()
        self.credentialsProvider?.clearKeychain()

        // Cancel current timer
        self.currentTimer?.invalidate()
    }

    private func cancelLogin(type: LoginErrorType) {

        LoadingSpinner.shared.stop()

        /// Revert the sing-in
        self.logOutAll()

        AWSTask(error: NSError(domain: "zuzu.com", code: type.rawValue, userInfo: nil)).continueWithBlock(self.completionHandler!)
    }

    private func failLogin(type: LoginErrorType) {

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
        default:
            assert(false, "Invalid Error Type")
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

    private func finishLogin(provider: Provider, userId: String) {

        Log.debug("Persist login user, provider = \(provider), userId = \(userId)")

        /// Save Login Data
        UserDefaultsUtils.setLoginProvider(provider)
        UserDefaultsUtils.setLoginUser(userId)

        /// Sign-in completed
        Log.debug("postNotificationName: \(UserLoginNotification)")
        NSNotificationCenter.defaultCenter().postNotificationName(UserLoginNotification, object: self,
                                                                  userInfo: ["userData": userId, "status": LoginStatus.New.rawValue])

        self.triggerTokenRefreshingTimer()
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

            if let error = task.error {
                assert(false, "Log in failed. Cannot get Cognito IdentityId, error = \(error)")
                return nil
            }

            /// Resume User Session
            if let userId = self.currentUserToken?.userId {
                Log.info("currentUserProfile exists. User should already be created")

                /// Resume completed
                Log.debug("postNotificationName: \(UserLoginNotification)")
                NSNotificationCenter.defaultCenter().postNotificationName(UserLoginNotification, object: self,
                    userInfo: ["userData": userId, "status": LoginStatus.Resume.rawValue])

                self.triggerTokenRefreshingTimer()

                task.continueWithBlock(self.completionHandler!)

                return nil
            }

            if let provider = self.currentProvider {

                switch(provider) {
                case .ZUZU:
                    if let userId = ZuzuAccessToken.currentAccessToken.userId {

                        /// The login process is finished
                        self.finishLogin(provider, userId: userId)

                        AWSTask(result: nil).continueWithBlock(self.completionHandler!)

                    } else {
                        assert(false, "ZuzuUser Id cannot be nil")
                        /// Zuzu Web Api failure
                        self.failLogin(.ZuzuFailure)
                    }
                    break

                case .FB, .GOOGLE:

                    ///Try registering the authenticated users (FB/GOOGLE) with Zuzu backend
                    if let userProfile = self.transientUserProfile {

                        self.tryRegisterZuzuUser(userProfile, handler: { (userId, result) -> Void in

                            if(result) {

                                LoadingSpinner.shared.stop()

                                if let userId = userId {

                                    /// The login process is finished
                                    self.finishLogin(provider, userId: userId)

                                    AWSTask(result: nil).continueWithBlock(self.completionHandler!)

                                    self.transientUserProfile = nil

                                } else {

                                    assert(false, "ZuzuUser Id cannot be nil")
                                    /// Zuzu Web Api failure
                                    self.failLogin(.ZuzuFailure)

                                }

                            } else {
                                /// Zuzu Web Api failure
                                self.failLogin(.ZuzuFailure)
                            }
                        })

                    } else {
                        assert(false, "Current Profile should not be nil after successfully sing-in")
                    }

                    break
                }
            }

            return nil
        }
    }

    func loginFromView(theViewController: UIViewController,
                       mode: Int = 1, allowSkip: Bool = false,
                       withCompletionHandler completionHandler: AWSContinuationBlock) {
        Log.enter()

        /// Store cancel & complete callback
        self.completionHandler = completionHandler
        self.loginViewController = theViewController


        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("myCommonLoginView") as? MyCommonLoginViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.allowSkip = allowSkip
            vc.loginMode = mode
            vc.delegate = self
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
        if let _ = self.currentUserToken {
            return self.isLoggedInWithFacebook() || self.isLoggedInWithGoogle() || self.isLoggedInWithZuzu()
        } else {
            return false
        }
    }

    // MARK: Public Facebook Login

    func isLoggedInWithFacebook() -> Bool {

        if let provider = UserDefaultsUtils.getLoginProvider() where provider == Provider.FB {
            return FBSDKAccessToken.currentAccessToken() != nil
        } else {
            return false
        }

    }

    func reloadFBSession() {

        Log.debug("Reloading Facebook Session: \(FBSDKAccessToken.currentAccessToken()?.expirationDate)")

        /// Calling Graph API would refresh token
        self.requestFBUserData() { (result: AnyObject!, error: NSError!) -> Void in

            if(error != nil) {
                /// Cannot get user data.

                if let _ = self.currentUserToken {
                    if let accessToken = FBSDKAccessToken.currentAccessToken(),
                        expiry = FBSDKAccessToken.currentAccessToken().expirationDate {

                        if(expiry.timeIntervalSinceNow > 0) {
                            Log.debug("Cannot resume Facebook, but FB token is still valid. token = \(accessToken), expiry = \(expiry)")

                            /// Complete resume action

                            self.completeLogin(["graph.facebook.com" : accessToken.tokenString])

                            return
                        }
                    }
                }

                /// Revert the login only if we are Not resuming the session
                dispatch_async(dispatch_get_main_queue()) {
                    self.failLogin(.FacebookFailure)
                }

                Log.warning("FBSDKGraphRequest Error: \(error.localizedDescription)")
            } else {
                /// Update user data

                if let userProfile = self.dynamicType.toUserProfile(result) {

                    self.transientUserProfile = userProfile

                    self.completeFBLogin()

                } else {

                    assert(false, "Nil User Profile")
                    self.failLogin(.FacebookFailure)

                    ///GA Tracker: Fetch user data failed
                    self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                        action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), Nil User Profile")
                }

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
        LoadingSpinner.shared.setOpacity(0.8)
        LoadingSpinner.shared.setText("登入中")
        LoadingSpinner.shared.startOnView(theViewController.view)

        self.fbLoginManager.logInWithReadPermissions(["public_profile", "email", "user_friends"], fromViewController: theViewController, handler: { (result: FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in

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

                self.cancelLogin(LoginErrorType.FacebookCancel)

            } else {
                self.requestFBUserData() { (result: AnyObject!, error: NSError!) -> Void in

                    if(error != nil) {

                        Log.warning("FBSDKGraphRequest Error: \(error.localizedDescription)")

                        self.failLogin(.FacebookFailure)

                        ///GA Tracker: Fetch user data failed
                        self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                            action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), \(error.localizedDescription)")

                    } else {

                        if let userProfile = self.dynamicType.toUserProfile(result) {

                            self.transientUserProfile = userProfile

                            self.completeFBLogin()

                        } else {

                            assert(false, "Nil User Profile")
                            self.failLogin(.FacebookFailure)

                            ///GA Tracker: Fetch user data failed
                            self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Facebook), Nil User Profile")
                        }

                    }

                }

                ///GA Tracker: Login successful
                theViewController.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                    action: GAConst.Action.UIActivity.Login, label: GAConst.Label.LoginType.Facebook)
            }
        })
    }

    func requestFBUserData(handler: (result: AnyObject!, error: NSError!) -> Void) {
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
            self.currentProvider = Provider.FB
            self.completeLogin(["graph.facebook.com" : accessToken.tokenString])
        } else {
            assert(false, "AccessToken should not be nil")
        }
    }


    // MARK: Public Google Login

    func isLoggedInWithGoogle() -> Bool {

        if let provider = UserDefaultsUtils.getLoginProvider() where provider == Provider.GOOGLE {
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
        if(self.isLoggedInWithGoogle()) {
            Log.debug("Google Already Sign-in")
            return
        }

        self.googleSignIn.delegate = self
        self.googleSignIn.uiDelegate = self

        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.8)
        LoadingSpinner.shared.setText("登入中")
        LoadingSpinner.shared.startOnView(theViewController.view)

        Log.debug("Login Google")
        self.googleSignIn.signIn()
    }

    func googleLogout() {
        Log.enter()

        UserDefaultsUtils.clearGoogleToken()
        self.googleSignIn.signOut()
        Log.exit()
    }

    private func completeGoogleLogin() {

        Log.debug("Google token: \(self.googleSignIn.currentUser?.authentication?.idToken)")
        Log.debug("Google token: \(self.googleSignIn.currentUser?.authentication?.idTokenExpirationDate)")

        Log.debug("Google access token: \(self.googleSignIn.currentUser?.authentication?.accessToken)")
        Log.debug("Google accesstoken: \(self.googleSignIn.currentUser?.authentication?.accessTokenExpirationDate)")

        if let idToken = self.googleSignIn.currentUser.authentication.idToken,
            expiry = self.googleSignIn.currentUser.authentication.idTokenExpirationDate {

            //Save token for later use
            UserDefaultsUtils.setGoogleToken(idToken, expiry: expiry)

            self.currentProvider = Provider.GOOGLE
            self.completeLogin(["accounts.google.com": idToken])
        } else {
            assert(false, "IdToken should not be nil")
        }

    }

    // MARK: Public Zuzu Login

    func isLoggedInWithZuzu() -> Bool {

        if let provider = UserDefaultsUtils.getLoginProvider() where provider == Provider.ZUZU {
            return ZuzuAccessToken.currentAccessToken.token != nil
        } else {
            return false
        }

    }

    func reloadZuzuSession() {
        Log.debug("Reloading Zuzu Session")
        self.completeZuzuLogin()
    }

    func zuzuLogin(theViewController: UIViewController) {

        ///Check if already signed in
        if self.isLoggedInWithZuzu() {
            Log.debug("Zuzu Already Sign-in")
            return
        }

        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.8)
        LoadingSpinner.shared.setText("登入中")
        LoadingSpinner.shared.startOnView(theViewController.view)

        ///Bring-up sign-in UI
        self.zuzuAuthClient.loginWithZuzu(theViewController, registerHandler: { (result) in

            if(result == .Cancelled) {
                LoadingSpinner.shared.stop()
            }

            }, loginHandler: { (result, userId) in

                switch(result) {
                case .Success:

                    LoadingSpinner.shared.stop(afterDelay: 1.0)

                    ///GA Tracker: Login successful
                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                        action: GAConst.Action.UIActivity.Login, label: GAConst.Label.LoginType.Zuzu)

                    self.completeZuzuLogin()

                case .Failed:

                    Log.warning("Zuzu Login Failed")

                    ///GA Tracker: Login error
                        theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                            action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Zuzu)")

                    self.failLogin(.ZuzuFailure)

                case .Cancelled:

                    Log.warning("Zuzu Login Cancelled")

                    ///GA Tracker: Login cancelled
                    theViewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                        action: GAConst.Action.Blocking.LoginCancel, label: "\(GAConst.Label.LoginType.Zuzu)")

                    self.cancelLogin(.ZuzuCancel)
                }

        })
    }

    func zuzuRegister(theViewController: UIViewController) {

        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setOpacity(0.8)
        LoadingSpinner.shared.setText("處理中")
        LoadingSpinner.shared.startOnView(theViewController.view)

        ///Bring-up register UI
        self.zuzuAuthClient.registerWithZuzu(theViewController, registerHandler: { (result) in

            if(result == .Cancelled) {
                LoadingSpinner.shared.stop()
            }

            }, loginHandler: { (result, userId) in

                switch(result) {
                case .Success:

                    LoadingSpinner.shared.stop(afterDelay: 1.0)

                    self.completeZuzuLogin()

                case .Failed:

                    Log.warning("Zuzu Login Failed")
                    self.failLogin(.ZuzuFailure)

                case .Cancelled:

                    Log.warning("Zuzu Login Cancelled")
                    self.cancelLogin(.ZuzuCancel)
                }

        })

    }

    func zuzuLogout() {
        Log.enter()
        self.zuzuAuthClient.logout()
        Log.exit()
    }

    private func completeZuzuLogin() {

        /// Add new entry to logins
        Log.debug("Zuzu token: \(ZuzuAccessToken.currentAccessToken.token)")

        if let userId = ZuzuAccessToken.currentAccessToken.userId, let _ = ZuzuAccessToken.currentAccessToken.token {

            self.currentProvider = Provider.ZUZU
            self.completeLogin([self.customProviderName: userId])

        } else {
            assert(false, "zuzuToken should not be nil")
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

                ///GA Tracker: Login cancelled
                if let viewController = self.loginViewController {
                    viewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                                              action: GAConst.Action.Blocking.LoginCancel, label: "\(GAConst.Label.LoginType.Google), \(error.description)")
                }

                Log.warning("Google Login Cancelled: \(error.userInfo), \(error.description)")

                self.cancelLogin(LoginErrorType.GoogleCancel)

            } else {

                /// Don't care the login error if the previous token is still valid
                if let _ = self.currentUserToken {
                    if let idToken = UserDefaultsUtils.getGoogleToken(), expiry =  UserDefaultsUtils.getGoogleTokenExpiry() {
                        if(expiry.timeIntervalSinceNow > 0) {
                            Log.debug("Cannot refresh Google token. Use the cached token = \(idToken), expiry = \(expiry)")

                            /// Complete resume action
                            self.completeLogin(["accounts.google.com" : idToken])

                            return
                        }
                    }
                }

                /// Revert the login if Google cannot resume successfully
                /// Google token would be nil after App is closed, so we need to get it again from the Google server
                dispatch_async(dispatch_get_main_queue()) {
                    self.failLogin(.GoogleFailure)
                }

                ///GA Tracker: Login failed
                if let viewController = self.loginViewController {
                    viewController.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                                              action: GAConst.Action.Blocking.LoginError, label: "\(GAConst.Label.LoginType.Google), \(error.localizedDescription), \(error.userInfo)")
                }

                Log.warning("Google Login Error: \(error.userInfo), \(error.localizedDescription)")
            }

        } else {

            // Perform any operations on signed in user here.

            if let _ = user.authentication.idToken { // Safe to send to the server

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
                if let viewController = self.loginViewController {
                    viewController.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                                              action: GAConst.Action.UIActivity.Login, label: GAConst.Label.LoginType.Google)
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
        viewController.modalPresentationStyle = .OverCurrentContext
        self.loginViewController?.presentViewController(viewController, animated: true, completion: nil)
    }

    // Dismiss the "Sign in with Google" view
    func signIn(signIn: GIDSignIn!,
                dismissViewController viewController: UIViewController!) {
        Log.enter()
        self.loginViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

}

// MARK: Google CommonLoginViewDelegate
extension AmazonClientManager: CommonLoginViewDelegate {

    func onPerformSocialLogin(provider: Provider) {

        switch(provider) {
        case .FB:
            if let loginViewController = self.loginViewController {
                self.fbLogin(loginViewController)
            }
        case .GOOGLE:
            if let loginViewController = self.loginViewController {
                self.googleLogin(loginViewController)
            }
        default: break
        }

    }

    func onPerformZuzuLogin(needRegister: Bool) {

        if(needRegister) {
            if let loginViewController = self.loginViewController {
                self.zuzuRegister(loginViewController)
            }
        } else {
            if let loginViewController = self.loginViewController {
                self.zuzuLogin(loginViewController)
            }
        }
    }

    func onCancelUserLogin() {
        ///GA Tracker: Login cancelled
        self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                                             action: GAConst.Action.Blocking.LoginReject)

        AWSTask(result: LoginResult.Cancelled.rawValue).continueWithBlock(self.completionHandler!)
    }

    func onSkipUserLogin() {
        ///GA Tracker: Login cancelled
        self.loginViewController?.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                                                             action: GAConst.Action.Blocking.LoginSkip)

        AWSTask(result: LoginResult.Skip.rawValue).continueWithBlock(self.completionHandler!)
    }
}
