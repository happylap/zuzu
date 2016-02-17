//
//  CommonUtils.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


class CommonUtils: NSObject{
    
    static let standardDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    static let shortDateFormat: String = "yyyy-MM-dd"
    
    static func getStandardDateString(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.stringFromDate(date)
    }
    
    static func getDateString(date: NSDate, format: String = "yyyy-MM-dd") -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        //dateFormatter.timeZone = NSTimeZone(name: "UTC")
        return dateFormatter.stringFromDate(date)
    }
    
    
    static func getStandardDateFromString(value:String) -> NSDate? {
        return CommonUtils.getCustomDateFromString(value)
    }
    
    static func getStandardStringFromDate(date:NSDate) -> String? {
        return CommonUtils.getCustomStringFromDate(date)
    }
    
    static func getShortDateFromString(value:String) -> NSDate? {
        return CommonUtils.getCustomDateFromString(value, format: CommonUtils.shortDateFormat)
    }
    
    static func getShortStringFromDate(date:NSDate) -> String? {
        return CommonUtils.getCustomStringFromDate(date, format: CommonUtils.shortDateFormat)
    }
    
    static func getCustomDateFromString(value:String, format: String = CommonUtils.standardDateFormat) -> NSDate? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone(name: "UTC")
        df.locale = NSLocale.currentLocale()
        return df.dateFromString(value)
    }
    
    static func getCustomStringFromDate(date:NSDate, format: String = CommonUtils.standardDateFormat) -> String? {
        let df = NSDateFormatter()
        df.dateFormat = format
        df.timeZone = NSTimeZone(name: "UTC")
        df.locale = NSLocale.currentLocale()
        return df.stringFromDate(date)

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