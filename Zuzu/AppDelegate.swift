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

private let Log = Logger.defaultLogger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    static var tagContainer: TAGContainer?
    
    //var reachability:Reachability?
    
    let googleMapsApiKey = "AIzaSyCFtYM50yN8atX1xZRvhhTcAfmkEj3IOf8"
    
    var window: UIWindow?
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "RLopez.BORRAME" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    internal typealias NotificationSetupHandler = (result:Bool) -> ()
    
    private var localNotificationSetupHandler: NotificationSetupHandler?
    
    private var pushNotificationSetupHandler: NotificationSetupHandler?
    
    // MARK: Private Utils
    private func commonServiceSetup() {
        
        //Google Map
        GMSServices.provideAPIKey(googleMapsApiKey)
        
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
    
    private func updateTabBarBadge(application: UIApplication){
        Log.enter()
        let badgeNumber = application.applicationIconBadgeNumber
        Log.debug("badgeNumber: \(badgeNumber)")
        
        if badgeNumber > 0{
            let rootViewController = self.window?.rootViewController as! UITabBarController!
            let tabArray = rootViewController?.tabBar.items as NSArray!
            let notifyTabIndex = MainTabViewController.MainTabConstants.NOTIFICATION_TAB_INDEX
            let tabItem = tabArray.objectAtIndex(notifyTabIndex) as! UITabBarItem
            Log.debug("set tab bar badge number as \(badgeNumber)")
            tabItem.badgeValue = "\(badgeNumber)"
            Log.debug("post notification: receiveNotifyItems")
            NSNotificationCenter.defaultCenter().postNotificationName("receiveNotifyItems", object: self, userInfo: nil)
        }else{
            Log.debug("badgeNumber <=0 ")
        }
        
        Log.exit()
    }
    
    // MARK: Public Utils
    /// Setup for remote push notification
    internal func setupPushNotifications(handler: NotificationSetupHandler? = nil){
        Log.warning("setupPushNotifications")
        
        self.pushNotificationSetupHandler = handler
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    internal func isEnabledLocalNotification() -> Bool{
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
        NSNotificationCenter.defaultCenter().postNotificationName("deviceTokenChange", object: self, userInfo: ["deviceTokenString": deviceTokenString])
        
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
        Log.debug("application badge = \(application.applicationIconBadgeNumber)")
        
        let rootViewController = self.window?.rootViewController as! UITabBarController!
        let notifyTabIndex = MainTabViewController.MainTabConstants.NOTIFICATION_TAB_INDEX
        
        if let aps = userInfo["aps"] as? NSDictionary, badge = aps["badge"] as? Int {
            GAUtils.trackEvent(GAConst.Catrgory.ZuzuRadarNotification,
                               action: GAConst.Action.ZuzuRadarNotification.ReceiveNotification, label: AmazonClientManager.sharedInstance.currentUserProfile?.id, value:badge)
        }
        
        if application.applicationState == UIApplicationState.Active {
            Log.debug("user receive notification while app is in the foreground")
            
            if rootViewController.selectedIndex == notifyTabIndex{
                Log.debug("post notification: receiveNotifyItems in didReceiveRemoteNotification")
                
                NSNotificationCenter.defaultCenter().postNotificationName("receiveNotifyItemsOnForeground", object: self, userInfo: userInfo)
                
            }else{
                if let aps = userInfo["aps"] as? NSDictionary {
                    if let badge = aps["badge"] as? Int {
                        Log.debug("aps[badge] = \(badge)")
                        application.applicationIconBadgeNumber = badge
                        updateTabBarBadge(application)
                    }
                }
            }
            
        }else{
            let rootViewController = self.window?.rootViewController as! UITabBarController!
            let notifyTabIndex = MainTabViewController.MainTabConstants.NOTIFICATION_TAB_INDEX
            let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
            
            if badgeNumber > 0 {
                if rootViewController.selectedIndex != notifyTabIndex{
                    updateTabBarBadge(application)
                    Log.debug("postNotificationName: switchToTab")
                    NSNotificationCenter.defaultCenter().postNotificationName("switchToTab", object: self, userInfo: ["targetTab" : notifyTabIndex])
                    //Log.debug("set notification tab as selected")
                    //rootViewController.selectedIndex = notifyTabIndex
                }
            }
            
        }
        
        Log.exit()
        
    }
    
    // MARK: UIApplicationDelegate App Life Cycle
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Log.enter()
        
        /// Initial Setup
        ZuzuStore.sharedInstance.start()
        
        // Initialize sign-in
        AmazonClientManager.sharedInstance.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        AmazonSNSService.sharedInstance.start()
        
        CollectionItemService.sharedInstance.start()
        
        RadarService.sharedInstance.start()
        
        //reachability = Reachability.reachabilityForInternetConnection();
        //reachability?.startNotifier();
        
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        commonServiceSetup()
        
        customUISetup()
        
        Fabric.with([MoPub.self])
        
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("dev-zuzu01.sqlite")
        Log.debug(url.absoluteString)
        
        /// Resume Login Session when the app is launched
        AmazonClientManager.sharedInstance.resumeSession { (task) -> AnyObject! in
            dispatch_async(dispatch_get_main_queue()) {
            }
            return nil
        }
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        Log.enter()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Log.enter()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        Log.enter()
        
        let rootViewController = self.window?.rootViewController as! UITabBarController!
        let notifyTabIndex = MainTabViewController.MainTabConstants.NOTIFICATION_TAB_INDEX
        let badgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber
        
        if badgeNumber > 0 {
            if rootViewController.selectedIndex == notifyTabIndex{
                UIApplication.sharedApplication().applicationIconBadgeNumber = 0
            }else{
                self.updateTabBarBadge(application)
            }
        }
        
        /// Try to trigger the timer for refreshing token
        AmazonClientManager.sharedInstance.triggerTokenRefreshingTimer()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        Log.enter()
        
        #if !DEBUG
            /// Installation tracking for FB ADs
            FBSDKAppEvents.activateApp()
        #endif
        
    }
    
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
