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
 
    
    private static func createDefaultlogger() -> XCGLogger{
    
        let logger = XCGLogger.defaultInstance()
        
        #if DEBUG
            logger.setup(.Debug, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: true)
        #else
            logger.setup(.Severe, showThreadName: true, showLogLevel: false, showFileNames: true, showLineNumbers: false)
        #endif
        
        return logger
    
    }
}