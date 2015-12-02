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
    
    static let defaultLogger = Logger.createDefaultlogger()
    
    static let fileLogger = Logger.createFilelogger()
    
    private static let logFileIdentifier = "com.lap.zuzu"
    
    private static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        return formatter
    }()
    
    private static func createDefaultlogger() -> XCGLogger{
        
        let logger = XCGLogger.defaultInstance()
        
        #if DEBUG
            logger.setup(.Debug, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: true)
        #else
            logger.setup(.Severe, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: false)
        #endif
        
        return logger
        
    }
    
    private static func createFilelogger() -> XCGLogger{
        
        let logger = XCGLogger()
        
        #if DEBUG
            logger.setup(.Debug, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: true)
        #else
            logger.setup(.Severe, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: false)
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