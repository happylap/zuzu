//
//  ZuzuWebService.swift
//  Zuzu
//
//  Created by eechih on 2/1/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

struct WebApiConst {
    
    struct Server {
        static let SCHEME = "http"
        static let HOST = "ec2-52-77-238-225.ap-southeast-1.compute.amazonaws.com"
        static let PORT = 4567
    }
    
}

private let Log = Logger.defaultLogger

class ZuzuWebService: NSObject
{
    private static let instance = ZuzuWebService()
    
    var hostUrl = ""
    
    class var sharedInstance: ZuzuWebService {
        return instance
    }
    
    // Designated initializer
    private override init() {
        super.init()
        
        self.hostUrl = "\(WebApiConst.Server.SCHEME)://\(WebApiConst.Server.HOST):\(WebApiConst.Server.PORT)"
    }
    
    // MARK: - Public APIs
    
    func getNotificationItemsByUserId(userId: String, handler: (result: [NotifyItem]?, error: ErrorType?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/notifyitem/\(userId)"
        
        Alamofire.request(.GET, url, encoding: .JSON)
            .responseJSON { (_, _, result) in
                Log.debug("URL: \(url)")
                
                switch result {
                case .Success(let value):
                    let json = JSON(value)
                    Log.debug("Result: \(json)")
                    
                    var notifyItems: [NotifyItem] = [NotifyItem]()
                    for (_, subJson): (String, JSON) in json {
                        if let notifyItem = Mapper<NotifyItem>().map(subJson.description) {
                            notifyItems.append(notifyItem)
                        }
                    }
                    handler(result: notifyItems, error: nil)
                    
                case .Failure(_, let error):
                    Log.debug("Error: \(error)")
                    handler(result: nil, error: error)
                }
                
        }
        Log.exit()
    }
    
    
    func setReadNotificationByItemId(itemId: String, userId: String) {
        Log.enter()
        
        let url = "\(self.hostUrl)/notifyitem/\(itemId)/\(userId)"
        let payload = [["op": "replace", "path": "/_read", "value": true]]
        
        Alamofire.request(.PATCH, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success: break
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
            }
        }

        Log.exit()
    }
    
    func createUser(user: ZuzuUser, handler: (result: String?, error: ErrorType?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/user"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        Alamofire.request(.POST, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success(let value):
                Log.debug("Success.")
                handler(result: value, error: nil)
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
                handler(result: nil, error: error)
            }
        }
        
        Log.exit()
    }

    func createCriteriaByUserId(userId: String, appleProductId: String, criteria: SearchCriteria, handler: (result: String?, error: ErrorType?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria"
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.userId = userId
        zuzuCriteria.enabled = true
        zuzuCriteria.appleProductId = appleProductId
        zuzuCriteria.criteria = criteria
        
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        Alamofire.request(.POST, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success(let value):
                Log.debug("Success. \(value)")
                handler(result: value, error: nil)
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
                handler(result: nil, error: error)
            }
        }
        
        Log.exit()
    }
    
    func getCriteriaByUserId(userId: String, handler: (result: ZuzuCriteria?, error: ErrorType?) -> Void) {
        Log.enter()
        let url = "\(self.hostUrl)/criteria/\(userId)"
        
        Alamofire.request(.GET, url, encoding: .JSON)
            .responseJSON { (_, _, result) in
                Log.debug("URL: \(url)")
                
                switch result {
                case .Success(let value):
                    if let zuzuCriteria = Mapper<ZuzuCriteria>().map(value) {
                        Log.debug("Success.")
                        handler(result: zuzuCriteria, error: nil)
                    } else {
                        Log.debug("Transfor to SearchCriteria Error.")
                        handler(result: nil, error: nil)
                    }
                    
                case .Failure(_, let error):
                    Log.debug("Error: \(error)")
                    handler(result: nil, error: error)
                }
                
        }
        Log.exit()
    }
    
    func updateCriteriaByUserId(userId: String, criteriaId: String, appleProductId: String, criteria: SearchCriteria, handler: (result: String?, error: ErrorType?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/update/\(criteriaId)/\(userId)"
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.enabled = true
        zuzuCriteria.appleProductId = appleProductId
        zuzuCriteria.criteria = criteria
        
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        Alamofire.request(.PUT, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success(let value):
                Log.debug("Success. \(value)")
                handler(result: value, error: nil)
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
                handler(result: nil, error: error)
            }
        }
        
        Log.exit()
    }
    
    func updateCriteriaFiltersByUserId(userId: String, criteriaId: String, criteria: SearchCriteria, handler: (result: String?, error: ErrorType?) -> Void) {

        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/\(criteriaId)/\(userId)"
        
        var payload = [[String: AnyObject]]()
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.criteria = criteria
        let JSONDict = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        if let filters = JSONDict["filters"] {
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(filters, options: [])
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            payload.append(["op": "replace", "path": "/filters", "value": jsonString])
        }
        
        Alamofire.request(.PATCH, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success(let value):
                Log.debug("Success. \(value)")
                handler(result: value, error: nil)
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
                handler(result: nil, error: error)
            }
        }
        
        Log.exit()
    }

    
    func enableCriteriaByUserId(userId: String, criteriaId: String, enabled: Bool) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/\(criteriaId)/\(userId)"
        
        var payload = [[String: AnyObject]]()
        payload.append(["op": "replace", "path": "/enabled", "value": enabled])
        
        Alamofire.request(.PATCH, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        })).responseString { (_, _, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            
            switch result {
            case .Success: break
            case .Failure(_, let error):
                Log.debug("Error: \(error)")
            }
        }
        
        Log.exit()
    }

}