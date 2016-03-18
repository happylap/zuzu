//
//  CommonUtils.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

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
    
    static func getCustomDateFromString(value:String, format: String = CommonUtils.UTCFormat, timezone: NSTimeZone = UTCTimeZone) -> NSDate? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = timezone
        df.locale = NSLocale.currentLocale()
        return df.dateFromString(value)
    }
    
    static func getCustomStringFromDate(date:NSDate, format: String = CommonUtils.UTCFormat, timezone: NSTimeZone = NSTimeZone.localTimeZone()) -> String? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = timezone
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