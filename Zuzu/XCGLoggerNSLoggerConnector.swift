//
//  ViewControllerExtensions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import XCGLogger
import NSLogger

public class XCGNSLoggerLogDestination: XCGBaseLogDestination {

    // Report levels are different in NSLogger (0 = most important, 4 = least important)
    // XCGLogger level needs to be converted to use the bonjour app filtering in a meaningful way
    private func convertLogLevel(level: XCGLogger.LogLevel) -> Int32 {
        switch(level) {
        case .Severe:
            return 0
        case .Error:
            return 1
        case .Warning:
            return 2
        case .Info:
            return 3
        case .Debug:
            return 4
        case .Verbose:
            return 5
        case .None:
            return 3
        }
    }

    public override func output(logDetails: XCGLogDetails, text: String) {

        switch(logDetails.logLevel) {
        case .None:
            return
        default:
            break
        }

        var arr = logDetails.fileName.componentsSeparatedByString("/")
        var fileName = logDetails.fileName
        if let last = arr.popLast() {
            fileName = last
        }

        ///Escape the special char % in formatted string
        let logMessage = logDetails.logMessage.stringByReplacingOccurrencesOfString("%", withString: "%%")

        LogMessage_va(logDetails.logLevel.description, convertLogLevel(logDetails.logLevel), "[\(fileName):\(logDetails.lineNumber)] -> \(logDetails.functionName) : \(logMessage)", getVaList([]))
    }
}
