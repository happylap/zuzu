//
//  RadarService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


private let Log = Logger.defaultLogger


let ResetCriteriaNotification = "ResetCriteriaNotification"

class RadarService : NSObject {
    
    var zuzuCriteria: ZuzuCriteria?
    
    //Share Instance for interacting with the ZuzuStore
    class var sharedInstance: RadarService {
        struct Singleton {
            static let instance = RadarService()
        }
        
        return Singleton.instance
    }
    
    // MARK: start
    func start(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUserLogin:", name: UserLoginNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUserLogout:", name: UserLogoutNotification, object: nil)
        self.setNetworkObserver()
    }
    
    func onNetWorkChanged(notification: NSNotification){
        Log.enter()
        
        let zuzuUserId = UserDefaultsUtils.getZuzuUserId()
        let userLoginId = UserDefaultsUtils.getUserLoginId()

        if !AmazonClientManager.sharedInstance.isLoggedIn()
        || zuzuUserId != nil || userLoginId == nil{
            self.removeNetworkObserver()
            return
        }
        
        if let reachability: Reachability = notification.object as? Reachability{
            if(reachability.currentReachabilityStatus() == NotReachable) {
                return
            }
        }
        
        if userLoginId != nil{
            Log.debug("reget zuzu user id on netWork alive")
            self.loginZuzuUser(userLoginId!)
        }
        
        Log.exit()
    }
    
    func handleUserLogin(notification: NSNotification){
        Log.enter()
        if let loginUserId = UserDefaultsUtils.getUserLoginId(){
            if let zuzuUserId = UserDefaultsUtils.getZuzuUserId(){
                if zuzuUserId != loginUserId{
                    self.loginZuzuUser(loginUserId)
                    return
                }
                self.retrieveRadarCriteria(zuzuUserId)
                
            }else{
                self.loginZuzuUser(loginUserId)
                return
            }
        }
        Log.exit()
    }
    
    func handleUserLogout(notification: NSNotification){
        self.zuzuCriteria = nil
        NSNotificationCenter.defaultCenter().postNotificationName(ResetCriteriaNotification, object: self, userInfo: nil)
    }
    
    func retrieveRadarCriteria(userId:String){
        let zuzuUser = ZuzuUser()
        zuzuUser.userId = userId
        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
            if error != nil{
                Log.error("Cannot get criteria by user id:\(userId)")
                return
            }
            
            if result != nil{
                self.zuzuCriteria = result
            }else{
                self.zuzuCriteria = ZuzuCriteria()
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName(ResetCriteriaNotification, object: self, userInfo: nil)
        }
    }
    
    func loginZuzuUser(userId: String){
        Log.enter()
        self.zuzuCriteria = nil
        let zuzuUser = ZuzuUser()
        zuzuUser.userId = userId
        
        if let userData = AmazonClientManager.sharedInstance.userLoginData{
            zuzuUser.facebookEmail = userData.email
            zuzuUser.facebookFirstName = userData.name
            zuzuUser.facebookGender = userData.birthday
            zuzuUser.facebookGender = userData.gender
        }
        
        ZuzuWebService.sharedInstance.createUser(zuzuUser){(result, error) -> Void in
            if error != nil{
                self.setNetworkObserver()
                return
            }
            
            UserDefaultsUtils.setZuzuUserId(userId)
            self.retrieveRadarCriteria(userId)
            self.removeNetworkObserver()
        }
        Log.exit()
    }
    
    func setNetworkObserver(){
        self.removeNetworkObserver()
        NSNotificationCenter.defaultCenter().addObserver(self,
        selector: "onNetWorkChanged:",
        name: kReachabilityChangedNotification,
        object: nil)
    }
    
    func removeNetworkObserver(){
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object: nil)
    }
    
}