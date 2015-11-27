//
//  MainTabViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/3.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class MainTabViewController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchStoryboard:UIStoryboard = UIStoryboard(name: "SearchStoryboard", bundle: nil)
        let searchViewController:UIViewController = searchStoryboard.instantiateInitialViewController()!
        
        let collectionStoryboard:UIStoryboard = UIStoryboard(name: "MyCollectionStoryboard", bundle: nil)
        let collectionViewController:UIViewController = collectionStoryboard.instantiateInitialViewController()!
        
        let radarStoryboard:UIStoryboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        let radarViewController:UIViewController = radarStoryboard.instantiateInitialViewController()!
        
        
        
        self.viewControllers =
            [searchViewController, collectionViewController, radarViewController]
        
        self.delegate = self
        
        self.tabBar.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBar.hidden = true
    }
    
}

extension UITabBarController {
    
    var tabBarHidden: Bool {
        
        set {
            if(FeatureOption.enableCollection || FeatureOption.enableZadar) {
                tabBar.hidden = newValue
            } else {
                tabBar.hidden = true
            }
        }
        
        get {
            return tabBar.hidden
        }
    }
}
