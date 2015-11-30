//
//  AppDelegate.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let googleMapsApiKey = "AIzaSyCFtYM50yN8atX1xZRvhhTcAfmkEj3IOf8"
    
    var window: UIWindow?
    
    private let filterDataStore = UserDefaultsFilterSettingDataStore.getInstance()
    
    private func commonServiceSetup() {
        GMSServices.provideAPIKey(googleMapsApiKey)
        
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.None  // remove before app release
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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        commonServiceSetup()
        
        customUISetup()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        //Filter data is not cached across App instance
        filterDataStore.clearFilterSetting()
        
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return true
    }


}

