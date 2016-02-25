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

import FBSDKCoreKit
import FBSDKLoginKit

private let Log = Logger.defaultLogger

class ZuzuWebService: NSObject
{
    private static let instance = ZuzuWebService()
    
    var host = "http://ec2-52-77-238-225.ap-southeast-1.compute.amazonaws.com:4567"
    
    var alamoFireManager = Alamofire.Manager.sharedInstance
    
    class var sharedInstance: ZuzuWebService {
        return instance
    }
    
    // Designated initializer
    private override init() {
        super.init()
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30
        self.alamoFireManager = Alamofire.Manager(configuration: configuration)
    }
    
    
    // MARK: - Public APIs - User
    
    // test ok
    func createUser(user: ZuzuUser, handler: (result: AnyObject?, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [user: \(user)]")
        
        let resource = "/user"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        self.responseJSON(.POST, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    // MARK: - Public APIs - Criteria
    
    // test ok
    func updateCriteriaFiltersByUserId(userId: String, criteriaId: String, criteria: SearchCriteria, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), criteriaId: \(criteriaId), criteria: \(criteria)]")
        
        let resource = "/criteria/\(criteriaId)/\(userId)"
        
        var payload = [[String: AnyObject]]()
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.criteria = criteria
        let JSONDict = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        if let filters = JSONDict["filters"] {
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(filters, options: [])
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            payload.append(["op": "replace", "path": "/filters", "value": jsonString])
        }
        
        self.responseJSON(.PATCH, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    
    // test ok
    func createCriteriaByUserId(userId: String, appleProductId: String, criteria: SearchCriteria, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), appleProductId: \(appleProductId), criteria: \(criteria)]")
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.userId = userId
        zuzuCriteria.enabled = true
        zuzuCriteria.appleProductId = appleProductId
        zuzuCriteria.criteria = criteria
        
        let resource = "/criteria"
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        self.responseJSON(.POST, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    
    // test ok
    func enableCriteriaByUserId(userId: String, criteriaId: String, enabled: Bool, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), criteriaId: \(criteriaId), enabled: \(enabled)]")
        
        let resource = "/criteria/\(criteriaId)/\(userId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/enabled", "value": enabled]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }

    
    // MARK: - Public APIs - Notify
    
    // test ok
    func getNotificationItemsByUserId(userId: String, handler: (result: [NotifyItem]?, error: ErrorType?) -> Void) {
        self.getNotificationItemsByUserId(userId) { (totalNum, result, error) -> Void in
            handler(result: result, error: error)
        }
        
        Log.exit()
    }
    
    // test ok
    func getNotificationItemsByUserId(userId: String, handler: (totalNum: Int, result: [NotifyItem]?, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/notifyitem/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(totalNum: 0, result: nil, error: error)
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
                handler(totalNum: notifyItems.count, result: notifyItems, error: nil)
            }
            
        }
        
        Log.exit()
    }
    
    
    // test: ok
    func setReadNotificationByUserId(userId: String, itemId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), itemId: \(itemId)]")
        
        let resource = "/notifyitem/\(itemId)/\(userId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/_read", "value": true]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    // MARK: - Public APIs - Log
    
    func setReceiveNotifyTimeByUserId(userId: String, deviceId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), deviceId: \(deviceId)]")

        let resource = "/log/\(deviceId)/\(userId)"
        let payload: [[String: AnyObject]] = [["op": "add", "path": "/receiveNotifyTime", "value": ""]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload, handler: handler)
        
        Log.exit()
    }
    
    
    // MARK: - Public APIs - Purchase
    
    // test ok
    func purchaseCriteria(criteria: SearchCriteria, purchase: ZuzuPurchase, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = self.host + "/purchase"
        let headers = self.getHeaders()
        
        if let criteriaJSONDict = ZuzuCriteria.criteriaToJSON(criteria) {
            let criteriaData = try! NSJSONSerialization.dataWithJSONObject(criteriaJSONDict, options: [])
            
            Log.debug("criteriaData: \(criteriaData)")
            
            Alamofire.upload(.POST, url, headers: headers, multipartFormData: { multipartFormData -> Void in
                
                multipartFormData.appendBodyPart(data: purchase.userId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "user_id")
                multipartFormData.appendBodyPart(data: purchase.store.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "store")
                multipartFormData.appendBodyPart(data: purchase.productId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_id")
                multipartFormData.appendBodyPart(data: "\(purchase.productPrice)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_price")
                
                if let productTitle = purchase.productTitle {
                    multipartFormData.appendBodyPart(data: productTitle.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_title")
                }
                if let productLocaleId = purchase.productLocaleId {
                    multipartFormData.appendBodyPart(data: productLocaleId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "product_locale_id")
                }
                if let purchaseReceipt = purchase.purchaseReceipt {
                    multipartFormData.appendBodyPart(data: purchaseReceipt, name: "purchase_receipt")
                }
                multipartFormData.appendBodyPart(data: try! NSJSONSerialization.dataWithJSONObject(criteriaJSONDict, options: []), name: "criteria_filters")
                
                }, encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _):
                        
                        upload.responseJSON { (_, response, result) in
                            Log.debug("HTTP Request URL: \(url)")
                            
                            switch result {
                            case .Success(let value):
                                let json = JSON(value)
                                
                                Log.debug("HTTP Resopnse Json = \(json)")
                                
                                let code = json["code"].intValue
                                Log.debug("HTTP Resopnse Json Code = \(code)")
                                
                                
                                if code == 200 {
                                    handler(result: json["data"].object, error: nil)
                                }
                                else {
                                    let message = json["message"].stringValue
                                    Log.debug("HTTP Resopnse Error = \(message)")
                                    assert(false, "Api response error:\n \(message)")
                                    handler(result: nil, error: NSError(domain: message, code: code, userInfo: nil))
                                }
                            case .Failure(_, let error):
                                Log.debug("HTTP Resopnse Error = \(error)")
                                handler(result: nil, error: ((error as Any) as! NSError))
                            }
                            
                        }
                    case .Failure(let encodingError):
                        Log.debug("HTTP Resopnse Error = \(encodingError)")
                        assert(false, "Api response error:\n \(encodingError)")
                        handler(result: nil, error: ((encodingError as Any) as! NSError))
                    }
            })
        }
        
        Log.exit()
    }
    
    // test ok
    func getPurchaseByUserId(userId: String, handler: (totalNum: Int, result: [ZuzuPurchase]?, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/purchase/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(totalNum: 0, result: nil, error: error)
                return
            }
            
            if let value = result {
                let json = JSON(value)
                var purchases: [ZuzuPurchase] = [ZuzuPurchase]()
                for (_, subJson): (String, JSON) in json {
                    if let purchaseMapper = Mapper<ZuzuPurchaseMapper>().map(subJson.description) {
                        if let purchase = purchaseMapper.toPurchase() {
                            purchases.append(purchase)
                        }
                    }
                }
                handler(totalNum: purchases.count, result: purchases, error: nil)
            }
        }
        
        Log.exit()
    }
    
    // MARK: - Private Methods
    
    private func responseJSON(method: Alamofire.Method, resource: String, handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        self.responseJSON(method, resource: resource, payload: nil, handler: handler)
    }
    
    private func responseJSON(method: Alamofire.Method, resource: String, payload: [String: AnyObject], handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        self.responseJSON(method, resource: resource, payload: try! NSJSONSerialization.dataWithJSONObject(payload, options: []), handler: handler)
    }
    
    
    private func responseJSON(method: Alamofire.Method, resource: String, payload: [[String: AnyObject]], handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        self.responseJSON(method, resource: resource, payload: try! NSJSONSerialization.dataWithJSONObject(payload, options: []), handler: handler)
    }
    
    
    
    private func responseJSON(method: Alamofire.Method, resource: String, payload: NSData?, handler: ((result: AnyObject?, error: NSError?) -> Void)?) {
        
        let url = self.host + resource
        let headers = self.getHeaders()
        
        self.alamoFireManager.request(method, url, parameters: [:], encoding: .Custom({
            (convertible, params) in
            let mutableRequest = convertible.URLRequest.copy() as! NSMutableURLRequest
            mutableRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let body = payload {
                mutableRequest.HTTPBody = body
            }
            return (mutableRequest, nil)
        }), headers: headers).responseJSON { (_, response, result) in
            Log.debug("HTTP Request URL: \(url)")
            
            Log.debug("HTTP Resopnse = \(response)")
            
            if let handler = handler {
                switch result {
                case .Success(let value):
                    let json = JSON(value)
                    
                    Log.debug("HTTP Resopnse Json = \(json)")
                    
                    let code = json["code"].intValue
                    Log.debug("HTTP Resopnse Json Code = \(code)")
                    
                    
                    if code == 200 {
                        handler(result: json["data"].object, error: nil)
                    }
                    else if code == 204 {
                        // no data, but not empty array
                        handler(result: nil, error: nil)
                    }
                    else {
                        let message = json["message"].stringValue
                        Log.debug("HTTP Resopnse Error = \(message)")
                        assert(false, "Api response error:\n \(message)")
                        handler(result: nil, error: NSError(domain: message, code: code, userInfo: nil))
                    }
                case .Failure(_, let error):
                    Log.debug("HTTP Resopnse Error = \(error)")
                    handler(result: nil, error: ((error as Any) as! NSError))
                }
            }
        }
    }
    
    private func getHeaders() -> [String: String] {
        var headers = [String: String]()
        
        let plainLoginString = (SecretConst.SolrQuery as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        if let base64LoginString = plainLoginString?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength) {
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            headers["Authorization"] = "Basic \(base64LoginString)"
        } else {
            Log.debug("Unable to do Basic Authorization")
        }
        
        if let userLoginData = AmazonClientManager.sharedInstance.userLoginData {
            headers["UserId"] = userLoginData.id
            headers["UserProvider"] = userLoginData.provider?.rawValue
            if userLoginData.provider == Provider.FB {
                headers["UserToken"] = FBSDKAccessToken.currentAccessToken().tokenString
            }
            if userLoginData.provider == Provider.GOOGLE {
                // TODO
            }
        }
        
        Log.debug("headers: \(headers)")
        
        return headers
    }

}