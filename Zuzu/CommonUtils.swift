//
//  CommonUtils.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

// MARK: CommonUtils
class CommonUtils: NSObject{
    
    static let secPerDay = 86400.0
    static let secPerHour = 3600.0
    
    static let UTCTimeZone = NSTimeZone(name: "UTC")!
    static let UTCFormat: String = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    static let shortDateFormat: String = "yyyy-MM-dd"
    
    static func getUTCDateFromString(value:String) -> NSDate? {
        return CommonUtils.getCustomDateFromString(value)
    }
    
    static func getUTCStringFromDate(date:NSDate) -> String? {
        return CommonUtils.getCustomStringFromDate(date)
    }
    
    static func getLocalDateFromString(value:String) -> NSDate? {
        return CommonUtils.getCustomDateFromString(value, timezone: NSTimeZone.localTimeZone())
    }
    
    static func getLocalStringFromDate(date:NSDate) -> String? {
        return CommonUtils.getCustomStringFromDate(date, timezone: NSTimeZone.localTimeZone())
    }
    
    static func getLocalShortDateFromString(value:String) -> NSDate? {
        return CommonUtils.getCustomDateFromString(value, format: CommonUtils.shortDateFormat, timezone: NSTimeZone.localTimeZone())
    }
    
    static func getLocalShortStringFromDate(date:NSDate) -> String? {
        return CommonUtils.getCustomStringFromDate(date, format: CommonUtils.shortDateFormat, timezone: NSTimeZone.localTimeZone())
    }
    
    /// Convert between date and string with custom format
    static func getCustomDateFromString(value:String, format: String = CommonUtils.UTCFormat, timezone: NSTimeZone = UTCTimeZone) -> NSDate? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = timezone
        df.locale = NSLocale.currentLocale()
        return df.dateFromString(value)
    }
    
    static func getCustomStringFromDate(date:NSDate, format: String = CommonUtils.UTCFormat, timezone: NSTimeZone = UTCTimeZone) -> String? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = timezone
        df.locale = NSLocale.currentLocale()
        return df.stringFromDate(date)
        
    }
    
    /// Convert between local date and string with custom format
    static func getLocalCustomDateFromString(value:String, format: String) -> NSDate? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone.localTimeZone()
        df.locale = NSLocale.currentLocale()
        return df.dateFromString(value)
    }
    
    static func getLocalCustomStringFromDate(date:NSDate, format: String) -> String? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone.localTimeZone()
        df.locale = NSLocale.currentLocale()
        return df.stringFromDate(date)
        
    }
    
    static func encodeToBase64(value: String) -> String? {
        if let plainString = (value as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            //return plainString.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
            return plainString.base64EncodedStringWithOptions([])
        }
        return nil
    }
    
    static func getDaysPart(seconds: Int) -> Int {
        
        return Int(ceil(convertSecondsToPreciseDays(seconds)))
        
    }
    
    static func getHoursPart(seconds: Int) -> Int {
        
        let hours = (Double(seconds) % secPerDay)/secPerHour
        
        return Int(floor(hours))
        
    }
    
    static func convertSecondsToPreciseDays(seconds: Int) -> Double {
        
        return Double(seconds)/secPerDay
        
    }
}

struct ExperimentData {
    var isEnabled: Bool
    var title: String?
    var subtitle: String?
    var url: String?
}

class TagUtils: NSObject{

    static func shouldCheckSource() -> Bool {
        
        var isCheckSource = false
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let checkSourceString = tagContainer.stringForKey(TagConst.checkSource)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.checkSource) = \(checkSourceString)")
            
            if(checkSourceString == "y") {
                
                isCheckSource = true
                
            } else if(checkSourceString == "n"){
                
                isCheckSource = false
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.checkSource)")
            }
            
        }
        
        return isCheckSource
        
    }
    
    static func shouldDisplayADs() -> Bool {
        
        var isDisplayADs = true
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let showADString = tagContainer.stringForKey(TagConst.showADs)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.showADs) = \(showADString)")
            
            if(showADString == "y") {
                
                isDisplayADs = true
                
            } else if(showADString == "n"){
                
                isDisplayADs = false
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.showADs)")
            }
            
        }
        
        return isDisplayADs
        
    }
    
    static func shouldDisplayVideoADs() -> Bool {
        
        var isDisplayVideoADs = false
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let showVideoADString = tagContainer.stringForKey(TagConst.showVideoADs)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.showVideoADs) = \(showVideoADString)")
            
            if(showVideoADString == "y") {
                
                isDisplayVideoADs = true
                
            } else if(showVideoADString == "n"){
                
                isDisplayVideoADs = false
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.showVideoADs)")
            }
            
        }
        
        return isDisplayVideoADs
        
    }
    
    static func shouldAllowZuzuLogin() -> Bool {
        
        var isEnableZuzuLogin = true
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let zuzuLoginString = tagContainer.stringForKey(TagConst.zuzuLogin)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.zuzuLogin) = \(zuzuLoginString)")
            
            if(zuzuLoginString == "y") {
                
                isEnableZuzuLogin = true
                
            } else if(zuzuLoginString == "n"){
                
                isEnableZuzuLogin = false
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.zuzuLogin)")
            }
            
        }
        
        return isEnableZuzuLogin
        
    }
    
    static func shouldAllowFreeTrial() -> Bool {
        
        var isAllowFreeTrial = true
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let freeTrialString = tagContainer.stringForKey(TagConst.freeTrial)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.freeTrial) = \(freeTrialString)")
            
            if(freeTrialString == "y") {
                
                isAllowFreeTrial = true
                
            } else if(freeTrialString == "n"){
                
                isAllowFreeTrial = false
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.freeTrial)")
            }
            
        }
        
        return isAllowFreeTrial
        
    }
    
    /// House-moving micro service campaign experiment
    static func getMoverExperiment() -> ExperimentData? {

        var moverTitleString: String?
        var promotionUrl: String?
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let moverDisplayString = tagContainer.stringForKey(TagConst.moverDisplay)
            moverTitleString = tagContainer.stringForKey(TagConst.moverMsg)
            promotionUrl = tagContainer.stringForKey(TagConst.moverUrl)
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.moverDisplay) = \(moverDisplayString), \(TagConst.moverUrl) = \(promotionUrl)")
            
            if(moverDisplayString == "y") {
                
                let data: ExperimentData = ExperimentData(isEnabled: true, title: moverTitleString, subtitle: nil, url: promotionUrl)
                
                return data
                
            } else if(moverDisplayString == "n"){
                
                let data: ExperimentData = ExperimentData(isEnabled: false, title: nil, subtitle: nil, url: nil)
                
                return data
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.moverDisplay)")
                return nil
            }
            
        }
        
        return nil
    }
    
    /// Rent-discount campaign experiment
    static func getRentDiscountExperiment() -> ExperimentData? {
        
        var tenantTitleString: String?
        var tenantSubtitleString: String?
        var promotionUrl: String?
        
        // A/B Testing flags
        if let tagContainer = AppDelegate.tagContainer {
            let tenantDisplayString = tagContainer.stringForKey(TagConst.tenantDisplay)
            tenantTitleString = tagContainer.stringForKey(TagConst.tenantTitle)
            tenantSubtitleString = tagContainer.stringForKey(TagConst.tenantSubtitle)
            promotionUrl = tagContainer.stringForKey(TagConst.tenantUrl)
            
            
            Log.debug("Tag Container = \(tagContainer.containerId), isDefault = \(tagContainer.isDefault()), \(TagConst.tenantDisplay) = \(tenantDisplayString) , \(TagConst.tenantUrl) = \(promotionUrl)")
            
            if(tenantDisplayString == "y") {
                
                let data: ExperimentData = ExperimentData(isEnabled: true, title: tenantTitleString, subtitle: tenantSubtitleString, url: promotionUrl)
                
                return data
                
            } else if(tenantDisplayString == "n"){
                
                let data: ExperimentData = ExperimentData(isEnabled: false, title: nil, subtitle: nil, url: nil)
                
                return data
                
            } else {
                
                Log.debug("Tag Container = \(tagContainer.containerId), No Value for Key: \(TagConst.tenantDisplay)")
                return nil
            }
            
        }
        
        return nil
        
    }
    
}

// MARK: UserServiceUtils
/// Utils for calculating service subscription information
class UserServiceUtils: NSObject{
    
    static let secPerDay = 86400.0
    static let secPerHour = 3600.0
    
    static func getRoundUpDays(seconds: Int) -> Int {
        
        return Int(ceil(convertSecondsToPreciseDays(seconds)))
        
    }
    
    static func getDaysPart(seconds: Int) -> Int {
        
        return Int(floor(convertSecondsToPreciseDays(seconds)))
        
    }
    
    static func getHoursPart(seconds: Int) -> Int {
        
        let hours = (Double(seconds) % secPerDay)/secPerHour
        
        return Int(floor(hours))
        
    }
    
    static func convertSecondsToPreciseDays(seconds: Int) -> Double {
        
        return Double(seconds)/secPerDay
        
    }
}

extension NSDate {
    func yearsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: self, options: []).year
    }
    func monthsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: self, options: []).month
    }
    func weeksFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: self, options: []).weekOfYear
    }
    func daysFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: self, options: []).day
    }
    func hoursFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: self, options: []).hour
    }
    func minutesFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: self, options: []).minute
    }
    func secondsFrom(date:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: self, options: []).second
    }
    func offsetFrom(date:NSDate) -> String {
        if yearsFrom(date)   > 0 { return "\(yearsFrom(date))y"   }
        if monthsFrom(date)  > 0 { return "\(monthsFrom(date))M"  }
        if weeksFrom(date)   > 0 { return "\(weeksFrom(date))w"   }
        if daysFrom(date)    > 0 { return "\(daysFrom(date))d"    }
        if hoursFrom(date)   > 0 { return "\(hoursFrom(date))h"   }
        if minutesFrom(date) > 0 { return "\(minutesFrom(date))m" }
        if secondsFrom(date) > 0 { return "\(secondsFrom(date))s" }
        return ""
    }
}