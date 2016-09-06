//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

private let Log = Logger.defaultLogger

struct StringUtils {

    //Sequence matters. "\\" has to be escaped first. Any other better solution?
    static let SPECIAL_CHARS: [String] = ["\\", " ", "+", "-", "&&", "||", "!", "(", ")", "{", "}", "[", "]", "^", "\"", ",~", "*", "?", ":"]

    static func escapeForSolrString(queryStr: String) -> String {

        var resultStr = queryStr

        for char in SPECIAL_CHARS {

            if(resultStr.containsString(char)) {
                let escapedChar = "\\\(char)"
                Log.debug(escapedChar)
                resultStr = resultStr.stringByReplacingOccurrencesOfString(char, withString: escapedChar)
            }
        }

        return resultStr


    }

    // Get the part of String that matches a pattern
    // http://stackoverflow.com/questions/27067508/how-to-group-search-regular-expressions-using-swift
    static func matchesForRegexInText(regex: String!, text: String!) -> [String] {

        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let nsString = text as NSString
            let matches = regex.matchesInString(text,
                                                options: [], range: NSMakeRange(0, nsString.length))
            // range at index 0: full match
            // range at index 1: first capture group
            return matches.map { nsString.substringWithRange($0.rangeAtIndex(1))}
        } catch let error as NSError {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }

    }
}
