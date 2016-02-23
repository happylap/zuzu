//
//  RadarService.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


private let Log = Logger.defaultLogger


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
        if let userData = notification.userInfo?["userData"] as? UserData{
            if let userId = userData.id{
                self.retrieveRadarCriteria(userId){(result, error) -> Void in
                    //if error == nil{
                    if result != nil{
                        self.zuzuCriteria = result
                    }else{
                        self.zuzuCriteria = ZuzuCriteria()
                    }
                    
                    //}
                }
            }
        }
        
        Log.exit()
    }
    
    func handleUserLogout(notification: NSNotification){
        self.zuzuCriteria = nil
    }
    
    func retrieveRadarCriteria(userId:String, handler: (result: ZuzuCriteria?, error: ErrorType?) -> Void){
        let zuzuUser = ZuzuUser()
        zuzuUser.userId = userId
        ZuzuWebService.sharedInstance.createUser(zuzuUser){(result, error) -> Void in
            if error != nil{
                Log.error("Cannot get createUser by user id:\(userId)")
                handler(result: nil, error: error)
                return
            }
            
            ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                if error != nil{
                    Log.error("Cannot get criteria by user id:\(userId)")
                    handler(result: nil, error: error)
                    return
                }
                
                handler(result: result, error: error)
            }
        }
    }
    
}