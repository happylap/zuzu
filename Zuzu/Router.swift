//
//  Router.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//


import UIKit
import Alamofire



enum Router: URLRequestConvertible {
    
    static var token: String?
    
    //Restfull api
    case TopicComment(parameters:[String: AnyObject])
    case TopicCreate(parameters:[String: AnyObject])
    case HouseList()
    case HouseDetail(houseId: String)
 
    var method: Alamofire.Method {
        switch self {
        case .HouseList:
            return .GET
        default:
            return .GET
        }
    }
    
    
    var path: String {
        switch self {
        case .HouseList:
            return ServiceApi.getHouseUrl()
        default:
            return ""
        }
    }
    
    var URLRequest: NSMutableURLRequest {
        let URL = NSURL(string: path)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        if let token = Router.token {
            mutableURLRequest.setValue("\(token)", forHTTPHeaderField: "token")
        }
        
        
        switch self {
        case .TopicComment(let parameters):
            return Alamofire.ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
            
        default:
            return mutableURLRequest
        }
    }
}