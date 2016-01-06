//
//  FBLoginService.swift
//  Zuzu
//
//  Created by eechih on 12/29/15.
//  Copyright © 2015 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import FBSDKLoginKit

class FBLoginService: NSObject
{
    
    class var sharedInstance: FBLoginService {
        struct Singleton {
            static let instance = FBLoginService()
        }
        
        return Singleton.instance
    }
    
    typealias ServiceResponse = (FBUserData?, NSError?) -> Void
    
    
    func getFBUserData(sender: UIViewController, onCompletion: ServiceResponse) -> Void {
        if hasActiveSession() {
            FBSDKGraphRequest.init(graphPath: "me", parameters: ["fields":"id, email, name, first_name, last_name, picture.type(large)"]).startWithCompletionHandler { (connection, result, error) -> Void in
                if error == nil {
                    let strId: String = (result.objectForKey("id") as? String)!
                    let strEmail: String = (result.objectForKey("email") as? String)!
                    let strName: String = (result.objectForKey("name") as? String)!
                    let strFirstName: String = (result.objectForKey("first_name") as? String)!
                    let strLastName: String = (result.objectForKey("last_name") as? String)!
                    let strPictureURL: String = (result.objectForKey("picture")?.objectForKey("data")?.objectForKey("url") as? String)!
                    
                    let fbUserData = FBUserData()
                    fbUserData.facebookId = strId
                    fbUserData.facebookEmail = strEmail
                    fbUserData.facebookName = strName
                    fbUserData.facebookFirstName = strFirstName
                    fbUserData.facebookLastName = strLastName
                    fbUserData.facebookPictureUrl = strPictureURL
                    
                    onCompletion(fbUserData, nil)
                    
                } else {
                    onCompletion(nil, error)
                }
            }
        } else {
            
            self.confirmAndLogin(sender)
            
        }
    }
    
    func hasActiveSession() -> Bool {
        return FBSDKAccessToken.currentAccessToken() != nil
    }
    
    
    func confirmAndLogin(sender: UIViewController) {
        // create the alert
        let alert = UIAlertController(title: "提醒", message: "請先登入Facebook", preferredStyle: UIAlertControllerStyle.Alert)
        
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "確定", style: UIAlertActionStyle.Default, handler: { action in
            self.login(sender)
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { action in
            
            ///GA Tracker
            sender.trackEventForCurrentScreen(GAConst.Catrgory.Blocking,
                action: GAConst.Action.Blocking.LoginCancel, label: GAConst.Label.LoginType.Facebook)
        }))
        
        // show the alert
        sender.presentViewController(alert, animated: true, completion: nil)
    }
    
    func login(sender: UIViewController) {
        let storyboard = UIStoryboard(name: "MyCollectionStoryboard", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("FBLoginView") as? FBLoginViewController {
            sender.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func logout(){
        let loginManager: FBSDKLoginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
}