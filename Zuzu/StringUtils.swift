//
//  StringUtils.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/29.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


struct StringUtils{
    
    //Sequence matters. "\\" has to be escaped first. Any other better solution?
    static let SPECIAL_CHARS:[String] = ["\\", " ","+", "-", "&&", "||", "!", "(", ")", "{", "}", "[", "]", "^", "\"", ",~", "*", "?", ":"]
    
    static func escapeForSolrString(queryStr:String) -> String{
        
        var resultStr = queryStr

        for char in SPECIAL_CHARS {
            
            if(resultStr.containsString(char)) {
                let escapedChar = "\\\(char)"
                print(escapedChar)
                resultStr = resultStr.stringByReplacingOccurrencesOfString(char, withString: escapedChar)
            }
        }
        
        return resultStr
        
        
    }
}
