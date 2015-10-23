//
//  ServiceApi.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

class ServiceApi: NSObject {
    
    static var host:String = "http://52.76.69.228:8983"
    
    internal class func getHouseUrl() -> String {
        
        //return "\(host)/solr/rhc/select/"
        return "\(host)/solr/rhc/select/?q=*:*%20AND%20purpose_type:(%201%20OR%204%20OR%203%20)&wt=json&indent=true&start=0&rows=10"
    }
    
}