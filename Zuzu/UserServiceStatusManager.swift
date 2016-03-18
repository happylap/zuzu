//
//  CacheStore.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/3/18.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import AwesomeCache

private let Log = Logger.defaultLogger

enum RadarStatus: String {
    case Valid = "valid"
    case Invalid = "invalid"
}

class UserServiceStatusManager {
    
    class var shared: UserServiceStatusManager {
        struct Static {
            static let instance = UserServiceStatusManager()
        }
        return Static.instance
    }
    
    // MARK: Private Utils
    
    //Cache Configs
    private let cacheName = "serviceStatusCache"
    private let cacheKey = "serviceStatus"
    private let cacheOneDay:Double = 24 * 60 * 60 //24 hours
    private let cacheTenMinute:Double = 10 * 60 //10 minutes
    
    ///Caching Utils
    private func saveCachedServiceStatus(serviceStatus: ZuzuServiceMapper, cacheTime: Double) {
        
        do {
            let cache = try Cache<NSData>(name: self.cacheName)
            let cachedData = NSKeyedArchiver.archivedDataWithRootObject(serviceStatus)
            cache.setObject(cachedData, forKey: self.cacheKey, expires: CacheExpiry.Seconds(cacheTime))
            
        } catch _ {
            Log.debug("Something went wrong with the cache")
        }
        
    }
    
    private func getCachedServiceStatus() -> ZuzuServiceMapper? {
        
        do {
            let cache = try Cache<NSData>(name: self.cacheName)
            
            ///Return cached data if there is cached data
            if let cachedData = cache.objectForKey(self.cacheKey),
                let result = NSKeyedUnarchiver.unarchiveObjectWithData(cachedData) as? ZuzuServiceMapper {
                    return result
            }
            
        } catch _ {
            Log.debug("Something went wrong with the cache")
        }
        
        return nil
    }
    
    private func clearCachedServiceStatus() {
        
        do {
            let cache = try Cache<NSData>(name: cacheName)
            
            cache.removeAllObjects()
            
        } catch _ {
            Log.debug("Something went wrong with the cache")
        }
    }
    
    private func calculateCachedSecond(remainingSec: Int) -> Double? {
        
        /// Get precise remianings days / used days
        /// e.g. 15.5 Days
        let remainingDays = UserServiceUtils.convertSecondsToPreciseDays(remainingSec)
        
        if(remainingDays >= 1) {
            /// More than 1 day
            
            return cacheOneDay
            
        } else {
            /// Within 1 day
            
            return cacheTenMinute
            
        }
    }
    
    // MARK: Public APIs
    // Cache service status only when there is valid service for the user
    // That is, we don't cache data when the user has no service or expired service
    func getRadarServiceStatusByUserId(userId: String, onCompleteHandler: (result: ZuzuServiceMapper?, success: Bool) -> Void) {
        Log.enter()
        
        if let serviceStatus = self.getCachedServiceStatus() {
            ///Hit Cache
            Log.debug("Hit service status cache")
            
            onCompleteHandler(result: serviceStatus, success: true)
            
        } else {
            /// Fetch from remote again
            Log.debug("Fetch service status from remote")
            
            ZuzuWebService.sharedInstance.getServiceByUserId(userId){
                (serviceStatus, error) -> Void in
                
                if error != nil{
                    Log.debug("getServiceByUserId error")
                    onCompleteHandler(result: nil, success: false)
                    return
                }
                
                /// Data retrieval succeeded
                if let result = serviceStatus {
                    /// The user has service
                    
                    /// Try cache service status if the service is valid
                    if let status = result.status  where (status == RadarStatus.Valid.rawValue),
                        let remainingSec = result.remainingSecond {
                            
                            if let cacheTime = self.calculateCachedSecond(remainingSec) {
                                
                                self.saveCachedServiceStatus(result, cacheTime: cacheTime)
                                
                            }
                    }
                    
                    onCompleteHandler(result: serviceStatus, success: true)
                    
                } else {
                    /// The user has no service
                    
                    onCompleteHandler(result: nil, success: true)
                }
            }
            
        }
        
        Log.exit()
    }
    
    func resetServiceStatusCache() {
        Log.enter()
        
        self.clearCachedServiceStatus()
        
        Log.exit()
    }
    
    
}