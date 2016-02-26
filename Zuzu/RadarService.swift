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
let ZuzuUserLoginNotification = "ZuzuUserLoginNotification"
let ZuzuUserLogoutNotification = "ZuzuUserLogoutNotification"

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
        
        if !AmazonClientManager.sharedInstance.isLoggedIn(){
            self.removeNetworkObserver()
            return
        }
        
        let zuzuUserId = UserDefaultsUtils.getZuzuUserId()
        
        if zuzuUserId != nil && self.zuzuCriteria != nil{
            self.removeNetworkObserver()
            return
        }
 
        if let reachability: Reachability = notification.object as? Reachability{
            if(reachability.currentReachabilityStatus() == NotReachable) {
                return
            }
        }
        
        if let userLoginId = UserDefaultsUtils.getUserLoginId(){
            self.loginZuzuUser(userLoginId)
        }
        
        if zuzuUserId != nil && self.zuzuCriteria == nil{
            self.retrieveRadarCriteria(zuzuUserId!)
            return
        }

        Log.exit()
    }
    
    func handleUserLogin(notification: NSNotification){
        Log.enter()
        if let loginUserId = UserDefaultsUtils.getUserLoginId(){
            if let zuzuUserId = UserDefaultsUtils.getZuzuUserId(){
                if zuzuUserId != loginUserId{ // switch user
                    self.loginZuzuUser(loginUserId)
                    return
                }
                
                if self.zuzuCriteria == nil{
                    self.retrieveRadarCriteria(zuzuUserId)
                }
                
            }else{
                self.loginZuzuUser(loginUserId)
                return
            }
        }
        Log.exit()
    }
    
    func handleUserLogout(notification: NSNotification){
        self.reset()
    }
    
    func retrieveRadarCriteria(userId:String){
        let zuzuUser = ZuzuUser()
        zuzuUser.userId = userId
        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
            if error != nil{
                self.setNetworkObserver()
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
        self.reset()
        let zuzuUser = ZuzuUser()
        zuzuUser.userId = userId
        
        if let userData = AmazonClientManager.sharedInstance.userLoginData{
            zuzuUser.facebookEmail = userData.email
            zuzuUser.facebookFirstName = userData.name
            zuzuUser.facebookGender = userData.birthday
            zuzuUser.facebookGender = userData.gender
        }
        
        ZuzuWebService.sharedInstance.isExistUser(userId){(result, error) -> Void in
            if error != nil{
                self.setNetworkObserver()
                return
            }
            
            if result == true{
                UserDefaultsUtils.setZuzuUserId(userId)
                self.retrieveRadarCriteria(userId)
                NSNotificationCenter.defaultCenter().postNotificationName(ZuzuUserLoginNotification, object: self, userInfo: nil)
                if AmazonClientManager.sharedInstance.userLoginData != nil{
                    ZuzuWebService.sharedInstance.updateUser(zuzuUser){
                        (result, error) -> Void in
                    }
                }
                return
            }
            
            ZuzuWebService.sharedInstance.createUser(zuzuUser){(result, error) -> Void in
                if error != nil{
                    self.setNetworkObserver()
                    return
                }
                
                UserDefaultsUtils.setZuzuUserId(userId)
                NSNotificationCenter.defaultCenter().postNotificationName(ZuzuUserLoginNotification, object: self, userInfo: nil)
                self.retrieveRadarCriteria(userId)
            }
        }
        
        Log.exit()
    }
    
    private func reset(){
        UserDefaultsUtils.clearZuzuUserId()
        NSNotificationCenter.defaultCenter().postNotificationName(ZuzuUserLogoutNotification, object: self, userInfo: nil)
        if self.zuzuCriteria  != nil{
            self.zuzuCriteria = nil
            NSNotificationCenter.defaultCenter().postNotificationName(ResetCriteriaNotification, object: self, userInfo: nil)
        }
    }
    
    func setNetworkObserver(){
        /*self.removeNetworkObserver()
        NSNotificationCenter.defaultCenter().addObserver(self,
        selector: "onNetWorkChanged:",
        name: kReachabilityChangedNotification,
        object: nil)*/
    }
    
    func removeNetworkObserver(){
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object: nil)
    }
}