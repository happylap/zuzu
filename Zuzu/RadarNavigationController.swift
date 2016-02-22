//
//  RadarNavigationController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/22.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class RadarNavigationController: UINavigationController {

    var user: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.user = "test"
        self.refreshCriteria()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: - criteria
    
    private func refreshCriteria(){
        let storyboard = UIStoryboard(name: "RadarStoryboard", bundle: nil)
        
        if let user = self.user{
            ZuzuWebService.sharedInstance.getCriteriaByUserId(user) { (result, error) -> Void in
                if error != nil{
                    //zuzualert
                    return
                }
                
                if result != nil{
                    if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarDisplayViewController") as? RadarDisplayViewController {
                        vc.zuzuCriteria = result!
                        self.showViewController(vc, sender: self)
                    }
                }else{
                    if let vc = storyboard.instantiateViewControllerWithIdentifier("RadarViewController") as? RadarViewController {
                        self.showViewController(vc, sender: self)
                    }
                }
            }
        }
    }
}
