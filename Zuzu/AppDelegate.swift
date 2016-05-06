//
//  AppDelegate.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import GoogleMaps
import AWSCore
import AWSCognito
import AWSSNS
import FBSDKCoreKit
import FBSDKLoginKit
import Fabric
import SCLAlertView
import BWWalkthrough

private let Log = Logger.defaultLogger

/// Notification Type definiton
let DeviceTokenChangeNotification = "deviceTokenChange"
let RadarItemReceiveNotification = "receiveNotifyItems"


enum AppStateOnNotification : Int {
    case Foreground
    case Background
    case Terminated
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    internal typealias NotificationSetupHandler = (result:Bool) -> ()
    
    internal static var tagContainer: TAGContainer?
    
    var window: UIWindow?
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "RLopez.BORRAME" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    private static let googleMapsApiKey = "AIzaSyCFtYM50yN8atX1xZRvhhTcAfmkEj3IOf8"
    
    //var reachability:Reachability?
    
    private var localNotificationSetupHandler: NotificationSetupHandler?
    
    private var pushNotificationSetupHandler: NotificationSetupHandler?
    
    private var walkthrough:BWWalkthroughViewController!
    
    // MARK: Private Utils
    
    private func commonServiceSetup() {
        
        // Google Map
        GMSServices.provideAPIKey(AppDelegate.googleMapsApiKey)
        
        #if !DEBUG
            //Google Analytics
            // Configure tracker from GoogleService-Info.plist.
            var configureError:NSError?
            GGLContext.sharedInstance().configureWithError(&configureError)
            assert(configureError == nil, "Error configuring Google services: \(configureError)")
            
            // Optional: configure GAI options.
            let gai = GAI.sharedInstance()
            gai.trackUncaughtExceptions = true  // report uncaught exceptions
            gai.logger.logLevel = GAILogLevel.Error  // remove before app release
        #endif
        //Google Tag Manager
        let GTM = TAGManager.instance()
        GTM.logger.setLogLevel(kTAGLoggerLogLevelVerbose)
        
        TAGContainerOpener.openContainerWithId("GTM-PLP77J",
                                               tagManager: GTM, openType: kTAGOpenTypePreferFresh,
                                               timeout: nil,
                                               notifier: self)
        
    }
    
    private func customUISetup() {
        // Configure TabBar
        UITabBar.appearance().tintColor = UIColor.colorWithRGB(0x1CD4C6)
        
        // Configure Navigation Bar
        let bgColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        let font = UIFont.boldSystemFontOfSize(21)
        
        UINavigationBar.appearance().titleTextAttributes =
            [NSForegroundColorAttributeName:UIColor.whiteColor(),
             NSFontAttributeName : font]
        UINavigationBar.appearance().barTintColor = bgColor
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
        UINavigationBar.appearance().autoScaleFontSize = true
        //UIBarButtonItem.appearance().tintColor  = UIColor.whiteColor()
    }
    
    private func presentWalkthrough() {
        let mainStory = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = mainStory.instantiateViewControllerWithIdentifier("walkthroughMaster") as? BWWalkthroughViewController {
            self.walkthrough =  vc
            let pageOne = mainStory.instantiateViewControllerWithIdentifier("walkthroughPage1")
            let pageTwo = mainStory.instantiateViewControllerWithIdentifier("walkthroughPage2")
            let pageThree = mainStory.instantiateViewControllerWithIdentifier("walkthroughPage3")
            
            // Attach the pages to the master
            walkthrough.delegate = self
            walkthrough.addViewController(pageOne)
            walkthrough.addViewController(pageTwo)
            walkthrough.addViewController(pageThree)
            
            self.window?.rootViewController = walkthrough
        }
    }
    
    /// Handle received notification. Log the notification & update Tab badge number
    private func postRadarItemReceivedEventForAppInState(appState: AppStateOnNotification,
                                                         switchTab: Bool,
                                                         newAppBadge: Int? = nil) {
        
        let appBadge = newAppBadge ?? UIApplication.sharedApplication().applicationIconBadgeNumber
        
        Log.debug("appState = \(appState), switchTab = \(switchTab), appBadge = \(appBadge)")
        
        /// Check is logged in
        if(!AmazonClientManager.sharedInstance.isLoggedIn()) {
            
            Log.debug("Cannot handle the notification. The user is not logged in.")
            
            AppDelegate.clearAllBadge()
            
            Log.exit()
            return
        }
        
        if(appBadge <= 0) {
            Log.debug("appBadge <= 0")
            
            Log.exit()
            return
        }
        
        /// GA Tracking: Notification info
        GAUtils.trackEvent(GAConst.Catrgory.ZuzuRadarNotification,
                           action: GAConst.Action.ZuzuRadarNotification.ReceiveNotification, label: UserManager.getCurrentUser()?.userId, value: appBadge)
        
        /// Post receiveNotifyItems Notification
        /// - Log the notification, update badge if needed, switch tab if needed
        Log.debug("post notification: \(RadarItemReceiveNotification)")
        
        let userinfo:[NSObject: AnyObject] = ["appState": appState.rawValue,
                                              "switchTab": switchTab]
        
        NSNotificationCenter.defaultCenter().postNotificationName(RadarItemReceiveNotification, object: self, userInfo: userinfo)
        
    }
    
    /// Alert for no registered device token
    internal static func alertPushNotificationDisabled() {
        Log.enter()
        
        let alertView = SCLAlertView()
        
        
        let subTitle = "無法開啟遠端通知，無法使用「租屋雷達」，請嘗試下面步驟排除：\n\n確認網路狀況正常後，關閉豬豬快租，再重新開啟進入「租屋雷達」。\n\n若本訊息持續出現，請聯繫粉絲團客服協助排除"
        
        alertView.showCloseButton = true
        
        alertView.showInfo("通知功能尚未開啟", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }
    
    /// Clear  App/Tab badge
    internal static func clearAllBadge(){
        Log.enter()
        
        let application = UIApplication.sharedApplication()
        let badgeNumber = application.applicationIconBadgeNumber
        application.applicationIconBadgeNumber = 0
        Log.debug("Clear App Badge Number: \(badgeNumber)")
        
        self.setNotificationTabBarBadge(nil)
        
        Log.exit()
    }
    
    /// Sync Tab badge with App badge
    internal static func updateTabBarBadge(){
        Log.enter()
        
        /// Get the new item count as Tab Badge
        let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
        Log.debug("badgeNumber: \(badgeNumber)")
        
        if badgeNumber <= 0{
            Log.debug("badgeNumber <=0 ")
            return
        }
        
        self.setNotificationTabBarBadge(badgeNumber)
        
        Log.exit()
    }
    
    internal static func setNotificationTabBarBadge(badgeNumber: Int?){
        Log.enter()
        
        let application = UIApplication.sharedApplication()
        Log.debug("badgeNumber: \(badgeNumber)")
        
        if let appDelegate = application.delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController,
            tabItems = tabViewController.viewControllers {
            
            let notificationViewIndex = MainTabConstants.NOTIFICATION_TAB_INDEX
            
            if(tabItems.count > notificationViewIndex) {
                let tabItem = tabItems[notificationViewIndex]
                
                if let badgeNumber = badgeNumber {
                    tabItem.tabBarItem?.badgeValue = "\(badgeNumber)"
                    Log.debug("Set Tab badge = \(badgeNumber)")
                } else {
                    tabItem.tabBarItem?.badgeValue = nil
                    Log.debug("Clear Tab badge")
                }
            }
        }
        
        Log.exit()
    }
    
    
    /// Switch the tab to notification view if needed.
    internal static  func switchToNotificationTab() {
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            tabViewController = appDelegate.window?.rootViewController as? UITabBarController {
            
            let notifyTabIndex = MainTabConstants.NOTIFICATION_TAB_INDEX
            
            /// Switch tab is APNS new item count > 0
            if(UIApplication.sharedApplication().applicationIconBadgeNumber > 0) {
                if(tabViewController.selectedIndex != notifyTabIndex) {
                    
                    Log.debug("postNotificationName: switchToTab")
                    NSNotificationCenter.defaultCenter().postNotificationName("switchToTab", object: self,
                                                                              userInfo: ["targetTab" : notifyTabIndex])
                }
            }
        }
        
    }
    
    // MARK: Public Utils
    /// Setup for remote push notification
    internal func setupPushNotifications(handler: NotificationSetupHandler? = nil){
        Log.warning("setupPushNotifications")
        
        self.pushNotificationSetupHandler = handler
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    internal func isPushNotificationRegistered() -> Bool {
        
        let registered = UIApplication.sharedApplication().isRegisteredForRemoteNotifications()
        
        if(registered) {
            
            if UserDefaultsUtils.getAPNDevicetoken() == nil {
                assert(false, "Device Token should be saved when remote notification is registered")
            }
            
        }
        
        return registered
        
    }
    
    internal func isLocalNotificationEnabled() -> Bool{
        if let grantedSettings = UIApplication.sharedApplication().currentUserNotificationSettings(){
            if grantedSettings.types.rawValue & UIUserNotificationType.Alert.rawValue != 0 {
                
                return true
            }
        }
        
        return false
    }
    
    /// Setup for local App notification permission
    internal func setupLocalNotifications(handler: NotificationSetupHandler? = nil){
        Log.warning("setupLocalNotifications")
        
        self.localNotificationSetupHandler = handler
        
        // Sets up Mobile Push Notification
        let readAction = UIMutableUserNotificationAction()
        readAction.identifier = "READ_IDENTIFIER"
        readAction.title = "Read"
        readAction.activationMode = UIUserNotificationActivationMode.Foreground
        readAction.destructive = false
        readAction.authenticationRequired = true
        
        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = "DELETE_IDENTIFIER"
        deleteAction.title = "Delete"
        deleteAction.activationMode = UIUserNotificationActivationMode.Foreground
        deleteAction.destructive = true
        deleteAction.authenticationRequired = true
        
        let ignoreAction = UIMutableUserNotificationAction()
        ignoreAction.identifier = "IGNORE_IDENTIFIER"
        ignoreAction.title = "Ignore"
        ignoreAction.activationMode = UIUserNotificationActivationMode.Foreground
        ignoreAction.destructive = false
        ignoreAction.authenticationRequired = false
        
        let messageCategory = UIMutableUserNotificationCategory()
        messageCategory.identifier = "MESSAGE_CATEGORY"
        messageCategory.setActions([readAction, deleteAction], forContext: UIUserNotificationActionContext.Minimal)
        messageCategory.setActions([readAction, deleteAction, ignoreAction], forContext: UIUserNotificationActionContext.Default)
        
        let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Badge, UIUserNotificationType.Sound, UIUserNotificationType.Alert], categories: (NSSet(array: [messageCategory])) as? Set<UIUserNotificationCategory>)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        
    }
    
    // MARK: UIApplicationDelegate Methods
    @available(iOS, introduced=8.0, deprecated=9.0)
    func application(app: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return AmazonClientManager.sharedInstance.application(app, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    @available(iOS 9.0, *)
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        return AmazonClientManager.sharedInstance.application(app, openURL: url, options: options)
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return true
    }
    
    // MARK: UIApplicationDelegate Register Notification Response
    // Response for UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        Log.warning("didRegisterUserNotificationSettings Settings = \(notificationSettings.types)")
        
        if let currentNotificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            let isRegisteredForLocalNotifications = (!currentNotificationSettings.types.isSubsetOf(UIUserNotificationType.None))
            
            
            if(isRegisteredForLocalNotifications) {
                
                self.localNotificationSetupHandler?(result: true)
                self.localNotificationSetupHandler = nil
                
            } else {
                
                self.localNotificationSetupHandler?(result: false)
                self.localNotificationSetupHandler = nil
            }
            
            return
        }
        
        self.localNotificationSetupHandler?(result: false)
        self.localNotificationSetupHandler = nil
    }
    
    // Response for  UIApplication.sharedApplication().registerForRemoteNotifications()
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenString = "\(deviceToken)"
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString:"<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "")
        
        Log.warning("didRegisterForRemoteNotificationsWithDeviceToken tokenString: \(deviceTokenString)")
        
        UserDefaultsUtils.setAPNDevicetoken(deviceTokenString)
        NSNotificationCenter.defaultCenter().postNotificationName(DeviceTokenChangeNotification, object: self, userInfo: ["deviceTokenString": deviceTokenString])
        
        self.pushNotificationSetupHandler?(result: true)
        self.pushNotificationSetupHandler = nil
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        Log.error("Error in registering for remote notifications: \(error.localizedDescription)")
        
        self.pushNotificationSetupHandler?(result: false)
        self.pushNotificationSetupHandler = nil
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        Log.enter()
        Log.debug("Current application badge = \(application.applicationIconBadgeNumber)")
        
        /// AppState: Foreground, Launch From: N/A
        if application.applicationState == UIApplicationState.Active {
            
            ///Save APNS new item count
            if let aps = userInfo["aps"] as? NSDictionary, newItemCount = aps["badge"] as? Int {
                /// Need to set App badge manually
                
                Log.debug("aps badge = \(aps["badge"]), newItemCount = \(newItemCount)")
                application.applicationIconBadgeNumber = newItemCount
                
                self.postRadarItemReceivedEventForAppInState(.Foreground, switchTab: false, newAppBadge: newItemCount)
                
            } else {
                
                Log.warning("APNS message recevied without userInfo")
            }
            
            
        } else {
            /// AppState: Background, Launch From: Alert
            
            ///Try switch to notification tab
            AppDelegate.switchToNotificationTab()
            
        }
        
        Log.exit()
        
    }
    
    // MARK: UIApplicationDelegate: App Life Cycle
    // MARK: App Life Cycle - didFinishLaunchingWithOptions
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Log.enter()
        
        if(UserDefaultsUtils.needsDisplayOnboardingPages()) {
            self.presentWalkthrough()
        }
        
        /// Init for MoPub AD Lib
        Fabric.with([MoPub.self])
        
        /// Initialize Amazon Auth Client
        AmazonClientManager.sharedInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        /// Start services
        ZuzuStore.sharedInstance.start()
        
        AmazonSNSService.sharedInstance.start()
        
        CollectionItemService.sharedInstance.start()
        
        RadarService.sharedInstance.start()
        
        //reachability = Reachability.reachabilityForInternetConnection();
        //reachability?.startNotifier();
        
        commonServiceSetup()
        
        customUISetup()
        
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("dev-zuzu01.sqlite")
        Log.debug(url.absoluteString)
        
        /// Register for remote notifications
        self.setupPushNotifications { (result) in
            if(!result) {
                
            }
        }
        
        /// Clear app badge if not logged in when App is launched
        if(!AmazonClientManager.sharedInstance.isLoggedIn()) {
            
            AppDelegate.clearAllBadge()
            
        }
        
        /// Resume Login Session when the app is launched
        AmazonClientManager.sharedInstance.resumeSession { (task) -> AnyObject! in
            dispatch_async(dispatch_get_main_queue()) {
                
                /// AppState: Terminate, Launch From: Alert
                if let launchOptions = launchOptions, _ = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] {
                    
                    Log.debug("Launch from alert")
                    self.postRadarItemReceivedEventForAppInState(.Terminated, switchTab: true)
                    
                } else {
                    /// AppState: Terminate, Launch From: AppIcon
                    
                    Log.debug("Launch from App icon")
                    self.postRadarItemReceivedEventForAppInState(.Terminated, switchTab: false)
                    
                }
                
            }
            return nil
        }
        
        return true
    }
    
    // MARK: App Life Cycle - applicationWillResignActive
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        Log.enter()
    }
    
    // MARK: App Life Cycle - applicationDidEnterBackground
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Log.enter()
    }
    
    // MARK: App Life Cycle - applicationWillEnterForeground
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        Log.enter()
        
        Log.debug("\(application.applicationIconBadgeNumber)")
        
        /// AppState: Background, Launch From: Alert | AppIcon
        self.postRadarItemReceivedEventForAppInState(.Background, switchTab: false)
        
        /// Try to trigger the timer for refreshing token
        AmazonClientManager.sharedInstance.triggerTokenRefreshingTimer()
    }
    
    // MARK: App Life Cycle - applicationDidBecomeActive
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        Log.enter()
        
        #if !DEBUG
            /// Installation tracking for FB ADs
            FBSDKAppEvents.activateApp()
        #endif
        
    }
    
    // MARK: App Life Cycle - Terminate
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        Log.enter()
        
        //Filter data is not cached across App instance
        filterDataStore.clearFilterSetting()
        
        ZuzuStore.sharedInstance.stop()
    }
}

// MARK: TAGContainerOpenerNotifier
extension AppDelegate: TAGContainerOpenerNotifier {
    
    func containerAvailable(container: TAGContainer!) {
        container.refresh()
        
        //Save tag container for later access
        AppDelegate.tagContainer = container
    }
    
}

// MARK: - BWWalkthroughViewControllerDelegate
extension AppDelegate: BWWalkthroughViewControllerDelegate {
    
    func walkthroughCloseButtonPressed() {
        
        let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTab = mainStoryboard.instantiateInitialViewController()
        
        if let window = self.window {
            window.backgroundColor = UIColor.whiteColor()
            UIView.transitionWithView(window, duration: 0.3, options: [.TransitionCrossDissolve], animations: {
                window.rootViewController = mainTab
                }, completion: nil)
        }
        
        // Onboarding pages have been displayed.
        UserDefaultsUtils.setDisplayOnboardingPages()
    }
    
    func walkthroughPageDidChange(pageNumber: Int) {
        
    }
    
}

