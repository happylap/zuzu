//
//  Logger.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/12/1.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import XCGLogger

public struct Logger {
    
    static let defaultLogger = Logger.createLogger()
    
    static let fileLogger = Logger.createFilelogger()
    
    struct Tag {
        static let Default = "default"
    }
    
    private static let logFileIdentifier = "com.lap.zuzu"
    
    private static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter
    }()
    
    internal static func createLogger(identifier:String = Tag.Default) -> XCGLogger{
        
        let logger = XCGLogger(identifier: identifier)
        logger.xcodeColorsEnabled = true
        logger.xcodeColors = [
            .Verbose: .darkGrey,
            .Debug: .darkGreen,
            .Info: .blue,
            .Warning: .orange,
            .Error: .red,
            .Severe: .whiteOnRed
        ]
        
        #if DEBUG
            logger.setup(.Debug, showLogIdentifier: false, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        #else
            logger.setup(.Error, showLogIdentifier: false, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        #endif
        
        return logger
        
    }
    
    private static func createFilelogger() -> XCGLogger{
        
        let logger = XCGLogger()
        
        #if DEBUG
            logger.setup(.Debug, showLogIdentifier: true, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        #else
            logger.setup(.Error, showLogIdentifier: true, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true)
        #endif
        
        if let dirPath = getLogDirPath() {
            
            let logFilePath = "\(dirPath)/\(dateFormatter.stringFromDate(NSDate()))"
            
            logger.addLogDestination(XCGFileLogDestination(owner: logger, writeToFile: logFilePath, identifier: logFileIdentifier))
        }
        
        return logger
        
    }
    
    private static func getLogDirPath() -> String? {
        if let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first {
            let logDir = "\(cacheDir)/Logs"
            if !NSFileManager.defaultManager().fileExistsAtPath(logDir) {
                do {
                    try NSFileManager.defaultManager().createDirectoryAtPath(logDir, withIntermediateDirectories: false, attributes: nil)
                    return logDir
                } catch _ as NSError {
                    return nil
                }
            } else {
                return logDir
            }
        }
        
        return nil
    }
}