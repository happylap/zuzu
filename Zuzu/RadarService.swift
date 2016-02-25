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
        
        /*NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "reachabilityChanged:",
            name: kReachabilityChangedNotification,
            object: nil)*/
    }
    
    /*func reachabilityChanged(notification: NSNotification){
        Log.enter()
    }*/
    
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
                return
            }
            
            UserDefaultsUtils.setZuzuUserId(userId)
            self.retrieveRadarCriteria(userId)
        }
        Log.exit()
    }
}