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
        static let HOST = "127.0.0.1" //"ec2-52-77-238-225.ap-southeast-1.compute.amazonaws.com"
        static let PORT = 4567
        static var HEADERS: [String: String]? {
            get {
                var headers = ["Content-Type": "application/x-www-form-urlencoded"]
                
                let plainLoginString = (SecretConst.SolrQuery as NSString).dataUsingEncoding(NSUTF8StringEncoding)
                if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {
                    headers["Authorization"] = "Basic \(base64LoginString)"
                } else {
                    Log.debug("Unable to do Basic Authorization")
                }
                
                return headers
            }
        }
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
        
        self._get(url) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
                return
            }
            
            if let value = result {
                let json = JSON(value)
                Log.debug("Result: \(json)")
                
                var notifyItems: [NotifyItem] = [NotifyItem]()
                for (_, subJson): (String, JSON) in json {
                    if let notifyItem = Mapper<NotifyItem>().map(subJson.description) {
                        notifyItems.append(notifyItem)
                    }
                }
                handler(result: notifyItems, error: nil)
            }
        }
        
        Log.exit()
    }
    
    
    func setReadNotificationByItemId(itemId: String, userId: String) {
        Log.enter()
        
        let url = "\(self.hostUrl)/notifyitem/\(itemId)/\(userId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/_read", "value": true]]
        
        self._patch(url, payload: payload, handler: nil)
        
        Log.exit()
    }
    
    func createUser(user: ZuzuUser, handler: (result: AnyObject?, error: ErrorType?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/user"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        self._post(url, payload: payload, handler: handler)
        
        Log.exit()
    }

    func createCriteriaByUserId(userId: String, appleProductId: String, criteria: SearchCriteria, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria"
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.userId = userId
        zuzuCriteria.enabled = true
        zuzuCriteria.appleProductId = appleProductId
        zuzuCriteria.criteria = criteria
        
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        self._post(url, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    func getCriteriaByUserId(userId: String, handler: (result: ZuzuCriteria?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/\(userId)"
        
        self._get(url) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
                return
            }
            
            if let value = result {
                Log.debug("getCriteriaByUserId JSON: \(value)")
                if let zuzuCriteria = Mapper<ZuzuCriteria>().map(value) {
                    handler(result: zuzuCriteria, error: nil)
                } else {
                    Log.debug("Transfor to SearchCriteria has error.")
                    handler(result: nil, error: NSError(domain: "Transfor to SearchCriteria has error", code: -1, userInfo: nil))
                }
            }
        }
        
        Log.exit()
    }
    
    func updateCriteriaByUserId(userId: String, criteriaId: String, appleProductId: String, criteria: SearchCriteria, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/update/\(criteriaId)/\(userId)"
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.enabled = true
        zuzuCriteria.appleProductId = appleProductId
        zuzuCriteria.criteria = criteria
        
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        self._put(url, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    func updateCriteriaFiltersByUserId(userId: String, criteriaId: String, criteria: SearchCriteria, handler: (result: AnyObject?, error: NSError?) -> Void) {

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
        
        self._patch(url, payload: payload, handler: handler)
        
        Log.exit()
    }

    
    
    func enableCriteriaByUserId(userId: String, criteriaId: String, enabled: Bool, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/criteria/\(criteriaId)/\(userId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/enabled", "value": enabled]]
        
        self._patch(url, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    
    func setReceiveNotifyTimeByUserId(userId: String, deviceId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/log/\(deviceId)/\(userId)"
        let payload: [[String: AnyObject]] = [["op": "add", "path": "/receiveNotifyTime", "value": ""]]
        
        self._patch(url, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    func setRegisterTimeByUserId(userId: String, deviceId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/log/\(deviceId)/\(userId)"
        let payload:[[String: AnyObject]] = [["op": "add", "path": "/registerTime", "value": ""]]
        
        self._patch(url, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    
    private func _get(url: String, handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        Log.enter()
        
        Alamofire.request(.GET, url, encoding: .JSON, headers: WebApiConst.Server.HEADERS).responseJSON { (_, response, result) in
            Log.debug("URL: \(url)")
            Log.debug("response: \(response)")
            
            if let response = response {
                if response.statusCode == 403 {
                    if let handler = handler {
                        handler(result: nil, error: NSError(domain: "Access to ZuzuApi is forbidden", code: 403, userInfo: nil))
                    }
                    return
                }
            }
            
            switch result {
            case .Success(let value):
                if let handler = handler {
                    handler(result: value, error: nil)
                }
            case .Failure(_, let error):
                Log.debug("error: \(error)")
                if let handler = handler {
                    handler(result: nil, error: ((error as Any) as! NSError))
                }
            }
        }
        
        Log.exit()
    }
    
    private func _patch(url: String, payload: [[String: AnyObject]], handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        Log.enter()
        
        Alamofire.request(.PATCH, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        }), headers: WebApiConst.Server.HEADERS).responseString { (_, response, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            Log.debug("response: \(response)")
            
            if let response = response {
                if response.statusCode == 403 {
                    if let handler = handler {
                        handler(result: nil, error: NSError(domain: "Access to ZuzuApi is forbidden", code: 403, userInfo: nil))
                    }
                    return
                }
            }
            
            switch result {
            case .Success(let value):
                if let handler = handler {
                    handler(result: value, error: nil)
                }
            case .Failure(_, let error):
                Log.debug("error: \(error)")
                if let handler = handler {
                    handler(result: nil, error: ((error as Any) as! NSError))
                }
            }
            
        }
        
        Log.exit()
    }

    private func _put(url: String, payload: [String: AnyObject], handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        Log.enter()
        
        Alamofire.request(.PUT, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        }), headers: WebApiConst.Server.HEADERS).responseString { (_, response, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            Log.debug("response: \(response)")
            
            if let response = response {
                if response.statusCode == 403 {
                    if let handler = handler {
                        handler(result: nil, error: NSError(domain: "Access to ZuzuApi is forbidden", code: 403, userInfo: nil))
                    }
                    return
                }
            }
            
            switch result {
            case .Success(let value):
                if let handler = handler {
                    handler(result: value, error: nil)
                }
            case .Failure(_, let error):
                Log.debug("error: \(error)")
                if let handler = handler {
                    handler(result: nil, error: ((error as Any) as! NSError))
                }
            }
        }
        
        Log.exit()
    }
    
    private func _post(url: String, payload: [String: AnyObject], handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        Log.enter()
        
        Alamofire.request(.POST, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            mutableRequest.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
            return (mutableRequest, nil)
        }), headers: WebApiConst.Server.HEADERS).responseString { (_, response, result) in
            Log.debug("URL: \(url)")
            Log.debug("payload: \(payload)")
            Log.debug("response: \(response)")
            
            if let response = response {
                if response.statusCode == 403 {
                    if let handler = handler {
                        handler(result: nil, error: NSError(domain: "Access to ZuzuApi is forbidden", code: 403, userInfo: nil))
                    }
                    return
                }
            }
            
            switch result {
            case .Success(let value):
                if let handler = handler {
                    handler(result: value, error: nil)
                }
            case .Failure(_, let error):
                Log.debug("error: \(error)")
                if let handler = handler {
                    handler(result: nil, error: ((error as Any) as! NSError))
                }
            }
        }
        
        Log.exit()
    }
    
    func purchaseCriteria(criteria: SearchCriteria, purchase: ZuzuPurchase, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = "\(self.hostUrl)/purchase"
        
        if let criteriaJSONDict = ZuzuCriteria.criteriaToJSON(criteria) {
            let criteriaData = try! NSJSONSerialization.dataWithJSONObject(criteriaJSONDict, options: [])
            
            Log.debug("criteriaData: \(criteriaData)")
            
            Alamofire.upload(.POST, url, headers: WebApiConst.Server.HEADERS, multipartFormData: { multipartFormData -> Void in
                
                multipartFormData.appendBodyPart(data: purchase.userId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "user_id")
                multipartFormData.appendBodyPart(data: purchase.store.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "store")
                multipartFormData.appendBodyPart(data: purchase.productId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_id")
                multipartFormData.appendBodyPart(data: "\(purchase.productPrice)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_price")
                multipartFormData.appendBodyPart(data: purchase.purchaseReceipt, name: "purchase_receipt")
                if let productTitle = purchase.productTitle {
                    multipartFormData.appendBodyPart(data: productTitle.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_title")
                }
                if let productLocaleId = purchase.productLocaleId {
                    multipartFormData.appendBodyPart(data: productLocaleId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_locale_id")
                }
                multipartFormData.appendBodyPart(data: try! NSJSONSerialization.dataWithJSONObject(criteriaJSONDict, options: []), name: "criteria_filters")
                
            }, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { (_, response, result) in
                        switch result {
                        case .Success(let value):
                            let json = JSON(value)
                            if json["code"].intValue == 0 {
                                let successResult = json["result"].stringValue  // Return CriterisID
                                handler(result: successResult, error: nil)
                            } else {
                                let errorCode = json["code"].intValue
                                let errorMsg = json["errorMessage"].stringValue
                                handler(result: nil, error: NSError(domain: errorMsg, code: errorCode, userInfo: nil))
                            }
                            
                        case .Failure(_, let error):
                            Log.debug("HTTP request error = \(error)")
                            handler(result: nil, error: ((error as Any) as! NSError))
                        }
                    }
                case .Failure(let encodingError):
                    Log.debug("HTTP request error = \(encodingError)")
                    handler(result: nil, error: ((encodingError as Any) as! NSError))
                }
            })
        }
        
        Log.exit()
    }
    
    
}