//
//  ViewControllerExtensions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit
import XCGLogger
import NSLogger

public extension XCGLogger {

    // declared here again for performance reasons
    private func convertLogLevel(level: LogLevel) -> Int32 {
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

    private func outputLog(label: String, level: LogLevel, functionName: String, fileName: String, lineNumber: Int, @noescape closure: () -> String?) {

        var lastFileName = fileName

        var nameComponents = fileName.componentsSeparatedByString("/")
        if let last = nameComponents.popLast() {
            lastFileName = last
        }

        if let message = closure() {

            ///Escape the special char % in formatted string
            let logMessage = message.stringByReplacingOccurrencesOfString("%", withString: "%%")

            LogMessage_va(label, convertLogLevel(level), "[\(lastFileName):\(lineNumber)] -> \(functionName) : \(logMessage)", getVaList([]))
            self.logln(level, functionName: functionName, fileName: lastFileName, lineNumber: lineNumber, closure: {return "[\(label)] \(logMessage)"})
        } else {
            LogMessage_va(label, convertLogLevel(level), "[\(lastFileName):\(lineNumber)] -> \(functionName) : nil", getVaList([]))
            self.logln(level, functionName: functionName, fileName: lastFileName, lineNumber: lineNumber, closure: {return "[\(label)] nil"})
        }
    }

    // MARK: - Convenience logging methods

    // MARK: * Verbose: convenience functions for logging function enter & exit
    public class func enter(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let closure:() -> String? = {return "Enter"}
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func enter(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let closure:() -> String? = {return "Enter"}
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public class func exit(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let closure:() -> String? = {return "Exit"}
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    public func exit(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let closure:() -> String? = {return "Exit"}
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Verbose

    public func verbose(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Verbose

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func verbose(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Verbose

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    // MARK: * Debug

    public func debug(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Debug

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func debug(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Debug

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    // MARK: * Info

    public func info(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Info

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func info(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Info

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    // MARK: * Warning

    public func warning(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Warning

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func warning(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Warning

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    // MARK: * Error

    public func error(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Error

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func error(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Error

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    // MARK: * Severe

    public func severe(@autoclosure closure: () -> String?, label: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        let level = LogLevel.Severe

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }

    public func severe(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, label: String, @noescape closure: () -> String?) {
        let level = LogLevel.Severe

        outputLog(label, level: level, functionName: functionName, fileName:fileName, lineNumber:lineNumber, closure: closure)
    }


}
