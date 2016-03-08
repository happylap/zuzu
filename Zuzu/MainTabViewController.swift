//
//  MainTabViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/3.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class MainTabViewController: UITabBarController, UITabBarControllerDelegate {
    
    struct MainTabConstants {
        static let SEARCH_TAB_INDEX = 0
        static let COLLECTION_TAB_INDEX = 1
        static let RADAR_TAB_INDEX = 2
        static let NOTIFICATION_TAB_INDEX = 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dismissAllViewControllers:", name: "switchToTab", object: nil)
        
        AmazonClientManager.sharedInstance.resumeSession { (task) -> AnyObject! in
            dispatch_async(dispatch_get_main_queue()) {
            }
            return nil
        }
        
        let searchStoryboard:UIStoryboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
        let searchViewController:UIViewController = searchStoryboard.instantiateInitialViewController()!
        
        let collectionStoryboard:UIStoryboard = UIStoryboard(name: "MyCollectionStoryboard", bundle: nil)
        let collectionViewController:UIViewController = collectionStoryboard.instantiateInitialViewController()!
        
        let radarStoryboard:UIStoryboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        let radarViewController:UIViewController = radarStoryboard.instantiateInitialViewController()!
        
        let notificationStoryboard:UIStoryboard = UIStoryboard(name: "NotificationStoryboard", bundle: nil)
        let notificationViewController:UIViewController = notificationStoryboard.instantiateInitialViewController()!
        
        var tabViewControllers = [UIViewController]()
        
        tabViewControllers.append(searchViewController)
        
        if(FeatureOption.Collection.enableMain) {
            tabViewControllers.append(collectionViewController)
        }
        
        if(FeatureOption.Radar.enableMain) {
            tabViewControllers.append(radarViewController)
            tabViewControllers.append(notificationViewController)
        }
        
        self.viewControllers = tabViewControllers
        
        self.delegate = self
        
        self.initTabBar()
        
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.tabBar.hidden = true
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        if let sb = viewController.storyboard {
            if let name: String = sb.valueForKey("name") as? String {
                switch name {
                case "MyCollectionStoryboard":
                    if !AmazonClientManager.sharedInstance.isLoggedIn() {
                        AmazonClientManager.sharedInstance.loginFromView(self) {
                            (task: AWSTask!) -> AnyObject! in
                            
                            if(task.error == nil) {
                                self.runOnMainThread({ () -> Void in
                                    self.selectedIndex = MainTabConstants.COLLECTION_TAB_INDEX
                                })
                            }
                            
                            return nil
                        }
                        return false
                    }
                    
                case "RadarStoryboard":
                    //If fisrt time, pop up landing page
                    if(UserDefaultsUtils.needsDisplayRadarLandingPage()) {
                        UserDefaultsUtils.setRadarLandindPageDisplayed()
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
    
    func dismissAllViewControllers(notification: NSNotification) {
        
        if let userInfo = notification.userInfo,
            let tabIndex = userInfo["targetTab"] as? Int{
                
                // dismiss all view controllers in the navigation stack
                if let viewControllers = self.viewControllers as? [UINavigationController] {
                    for vc in viewControllers {
                        vc.dismissViewControllerAnimated(true, completion: nil)
                        //vc.popToRootViewControllerAnimated(false)
                    }
                }
                
                self.selectedIndex = tabIndex
        }
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
