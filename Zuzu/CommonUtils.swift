//
//  CommonUtils.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


class CommonUtils: NSObject{
    
    
    static func getStandardDateString(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.stringFromDate(date)
    }
    
}