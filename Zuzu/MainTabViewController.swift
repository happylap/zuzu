//
//  MainTabViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/3.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

/// Notification that is generated when tab is selected.
let TabBarSelectedNotification = "TabBarSelectedNotification"
let TabBarAgainSelectedNotification = "TabBarAgainSelectedNotification"

struct MainTabConstants {
    static let SEARCH_TAB_INDEX = 0
    static let COLLECTION_TAB_INDEX = 1
    static let RADAR_TAB_INDEX = 2
    static let NOTIFICATION_TAB_INDEX = 3
}

class MainTabViewController: UITabBarController {
    
    private var tabViewControllers = [UIViewController]()
    
    private var lastSelectedIndex: Int?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Log.enter()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainTabViewController.dismissAllViewControllers(_:)), name: "switchToTab", object: nil)
        
        /// Init View Controllers for each Tab
        let searchStoryboard:UIStoryboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
        if let searchViewController:UIViewController = searchStoryboard.instantiateInitialViewController() {
            tabViewControllers.append(searchViewController)
        }
        
        if(FeatureOption.Collection.enableMain) {
            let collectionStoryboard:UIStoryboard = UIStoryboard(name: "MyCollectionStoryboard", bundle: nil)
            if let collectionViewController:UIViewController = collectionStoryboard.instantiateInitialViewController() {
                tabViewControllers.append(collectionViewController)
            }
        }
        
        if(FeatureOption.Radar.enableMain) {
            
            let radarStoryboard:UIStoryboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
            let notificationStoryboard:UIStoryboard = UIStoryboard(name: "NotificationStoryboard", bundle: nil)
            
            if let radarViewController = radarStoryboard.instantiateInitialViewController() as? RadarNavigationController,
                let notificationViewController:UIViewController = notificationStoryboard.instantiateInitialViewController() {
                
                tabViewControllers.append(radarViewController)
                radarViewController.showNewTabBadge()
                
                tabViewControllers.append(notificationViewController)
                
            }
        }
        
        #if DEBUG
            let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginDebugViewController:UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("emNaviagationController") {
                tabViewControllers.append(loginDebugViewController)
            }
        #endif
        
        self.viewControllers = tabViewControllers
        
        self.delegate = self
        
        self.initTabBar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func dismissAllViewControllers(notification: NSNotification) {
        
        if let userInfo = notification.userInfo,
            let tabIndex = userInfo["targetTab"] as? Int{
            
            if let viewControllers = self.viewControllers{
                for vc in viewControllers {
                    if vc is UINavigationController{
                        vc.dismissViewControllerAnimated(true, completion: nil)
                        //vc.popToRootViewControllerAnimated(false)
                    }
                }
            }
            
            // dismiss all view controllers in the navigation stack
            self.selectedIndex = tabIndex
        }
    }
}

// MARK: - UITabBarControllerDelegate
extension MainTabViewController:  UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        
        let selectedIndex = tabBarController.selectedIndex
        
        NSNotificationCenter.defaultCenter().postNotificationName(TabBarSelectedNotification, object: self, userInfo: ["tabIndex": selectedIndex])
        
        if let lastSelectedIndex = self.lastSelectedIndex {
            if (lastSelectedIndex == selectedIndex) {
                NSNotificationCenter.defaultCenter().postNotificationName(TabBarAgainSelectedNotification, object: self, userInfo: ["tabIndex": selectedIndex])
            }
        }
        
        self.lastSelectedIndex = selectedIndex
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if let sb = viewController.storyboard {
            if let name: String = sb.valueForKey("name") as? String {
                switch name {
                case "MyCollectionStoryboard":
                    if !AmazonClientManager.sharedInstance.isLoggedIn() {
                        AmazonClientManager.sharedInstance.loginFromView(self) {
                            (task: AWSTask!) -> AnyObject! in
                            
                            /// Login Failed
                            if let error = task.error {
                                Log.warning("Login Failed  or cancelled: \(error)")
                                return nil
                            }
                            
                            /// Login Form is closed
                            if let result = task.result as? Int,
                                loginResult = LoginResult(rawValue: result) where loginResult == LoginResult.Cancelled {
                                Log.warning("Login form is closed")
                                return nil
                            }
                            
                            /// Login is skipped
                            if let result = task.result as? Int,
                                loginResult = LoginResult(rawValue: result) where loginResult == LoginResult.Skip {
                                Log.warning("Login is skipped")
                                return nil
                            }
                            
                            self.runOnMainThread({ () -> Void in
                                self.selectedIndex = MainTabConstants.COLLECTION_TAB_INDEX
                            })
                            
                            
                            return nil
                        }
                        return false
                    }
                    
                case "RadarStoryboard":
                    //If fisrt time, pop up landing page
                    if(UserDefaultsUtils.needsDisplayRadarLandingPage()) {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewControllerWithIdentifier("radarLandingPage")
                        vc.modalPresentationStyle = .OverCurrentContext
                        presentViewController(vc, animated: true, completion: nil)
                        
                        return false
                    } else {
                        
                        return true
                    }
                    
                default: break
                }
            }
        }
        
        return true
    }
}

extension UITabBarController {
    
    var tabBarHidden: Bool {
        
        set {
            if(newValue) {
                tabBar.hidden = newValue
            } else {
                if(FeatureOption.Collection.enableMain || FeatureOption.Radar.enableMain) {
                    tabBar.hidden = newValue
                }
            }
        }
        
        get {
            return tabBar.hidden
        }
    }
    
    func initTabBar() -> Void {
        
        if(FeatureOption.Collection.enableMain || FeatureOption.Radar.enableMain) {
            tabBar.hidden = false
        } else {
            tabBar.hidden = true
        }
        
    }
}

