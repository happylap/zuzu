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
    
    var host = HostConst.ZuzuBackend
    
    var alamoFireManager = Alamofire.Manager.sharedInstance
    
    class var sharedInstance: ZuzuWebService {
        return instance
    }
    
    // Designated initializer
    private override init() {
        super.init()
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 15 // seconds
        configuration.timeoutIntervalForResource = 15
        self.alamoFireManager = Alamofire.Manager(configuration: configuration)
    }
    
    
    // MARK: - Public APIs - Register
    
    func isExistEmail(email: String, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [email: \(email)]")
        
        let resource = "/register/valid/\(email)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
                return;
            }
            
            if let result = result {
                handler(result: result as! Bool, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func registerUser(user: ZuzuUser, handler: (userId: String?, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [user: \(user)]")
        
        let resource = "/register"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        self.responseJSON(.POST, resource: resource, payload: payload) { (result, error) -> Void in
            
            if let error = error {
                handler(userId: nil, error: error)
            } else {
                handler(userId: result as? String, error: nil)
            }
        }
        
        Log.exit()
    }
    
    // MARK: - Public APIs - User
    
    // @Deprecated
    func isExistUser(userId: String, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/user/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
            } else if let _ = result {
                handler(result: true, error: nil)
            } else {
                handler(result: false, error: nil)
            }
        }
        
        Log.exit()
    }
    
    // @Deprecated
    func createUser(user: ZuzuUser, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [user: \(user)]")
        
        let resource = "/register"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        self.responseJSON(.POST, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    func getUserByEmail(email: String, handler: (result: ZuzuUser?, error: NSError?) -> Void) {
        Log.debug("Input parameters [email: \(email)]")
        
        let resource = "/user/email/\(email)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
            } else if let value = result {
                if let userMapper = Mapper<ZuzuUser>().map(value) {
                    handler(result: userMapper, error: nil)
                } else {
                    Log.debug("Can not transfor to ZuzuUser")
                    handler(result: nil, error: NSError(domain: "Can not transfor to ZuzuUser", code: -1, userInfo: nil))
                }
            } else {
                // Not found any ZuZuUser
                handler(result: nil, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func getUserById(userId: String, handler: (result: ZuzuUser?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/user/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
            } else if let value = result {
                if let userMapper = Mapper<ZuzuUser>().map(value) {
                    handler(result: userMapper, error: nil)
                } else {
                    Log.debug("Can not transfor to ZuzuUser")
                    handler(result: nil, error: NSError(domain: "Can not transfor to ZuzuUser", code: -1, userInfo: nil))
                }
            } else {
                // Not found any ZuZuUser
                handler(result: nil, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func updateUser(user: ZuzuUser, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [user: \(user)]")
        
        let resource = "/user"
        let payload = Mapper<ZuzuUser>().toJSON(user)
        
        self.responseJSON(.POST, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    
    // MARK: - Public APIs - Device
    func createDeviceByUserId(userId: String, deviceId: String, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), deviceId: \(deviceId)]")
        
        let resource = "/device"
        let payload = ["user_id": userId, "device_id": deviceId]
        
        self.responseJSON(.POST, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    func deleteDeviceByUserId(userId: String, deviceId: String, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), deviceId: \(deviceId)]")
        
        let resource = "/device/\(userId)/\(deviceId)"

        self.responseJSON(.DELETE, resource: resource) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    func isExistDeviceByUserId(userId: String, deviceId: String, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), deviceId: \(deviceId)]")
        
        let resource = "/device/\(userId)/\(deviceId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
            } else if let _ = result {
                handler(result: true, error: nil)
            } else {
                handler(result: false, error: nil)
            }
        }
        
        Log.exit()
    }
    
    // MARK: - Public APIs - Criteria
    
    func getCriteriaByUserId(userId: String, handler: (result: ZuzuCriteria?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/criteria/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
            } else if let value = result {
                Log.debug("getCriteriaByUserId JSON: \(value)")
                if let zuzuCriteria = Mapper<ZuzuCriteria>().map(value) {
                    handler(result: zuzuCriteria, error: nil)
                } else {
                    Log.debug("Can not transfor to SearchCriteria")
                    handler(result: nil, error: NSError(domain: "Can not transfor to SearchCriteria", code: -1, userInfo: nil))
                }
            } else {
                // Not found any criteria
                handler(result: nil, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func createCriteriaByUserId(userId: String, criteria: SearchCriteria, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), criteria: \(criteria)]")
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.userId = userId
        zuzuCriteria.enabled = true
        zuzuCriteria.criteria = criteria
        
        let resource = "/criteria"
        let payload = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        
        self.responseJSON(.POST, resource: resource, payload: payload) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
            } else if let _ = result {
                handler(result: true, error: nil)
            } else {
                handler(result: false, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func updateCriteriaFiltersByUserId(userId: String, criteriaId: String, criteria: SearchCriteria, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), criteriaId: \(criteriaId), criteria: \(criteria)]")
        
        let resource = "/criteria/\(userId)/\(criteriaId)"
        
        var payload = [[String: AnyObject]]()
        
        let zuzuCriteria = ZuzuCriteria()
        zuzuCriteria.criteria = criteria
        
        let JSONDict = Mapper<ZuzuCriteria>().toJSON(zuzuCriteria)
        if let filters = JSONDict["filters"] {
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(filters, options: [])
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            payload.append(["op": "replace", "path": "/filters", "value": jsonString])
        }
        
        self.responseJSON(.PATCH, resource: resource, payload: payload) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
            } else if let _ = result {
                handler(result: true, error: nil)
            } else {
                handler(result: false, error: nil)
            }
        }
        
        Log.exit()
    }
    
    func enableCriteriaByUserId(userId: String, criteriaId: String, enabled: Bool, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), criteriaId: \(criteriaId), enabled: \(enabled)]")
        
        let resource = "/criteria/\(userId)/\(criteriaId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/enabled", "value": enabled]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    func hasValidCriteriaByUserId(userId: String, handler: (result: Bool, error: ErrorType?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/criteria/valid/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: false, error: error)
            } else if let _ = result {
                handler(result: true, error: nil)
            } else { // Not found any valid criteria
                handler(result: false, error: nil)
            }
        }
        
        Log.exit()
    }

    
    // MARK: - Public APIs - Notify
    
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
    
    func setReadNotificationByUserId(userId: String, itemId: String, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), itemId: \(itemId)]")
        
        let resource = "/notifyitem/\(userId)/\(itemId)"
        let payload:[[String: AnyObject]] = [["op": "replace", "path": "/_read", "value": true]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        
        Log.exit()
    }
    
    // MARK: - Public APIs - Log
    
    func setReceiveNotifyTimeByUserId(userId: String, deviceId: String, handler: (result: Bool, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId), deviceId: \(deviceId)]")
        
        let resource = "/log/\(userId)/\(deviceId)"
        let payload: [[String: AnyObject]] = [["op": "add", "path": "/receiveNotifyTime", "value": ""]]
        
        self.responseJSON(.PATCH, resource: resource, payload: payload) { (result, error) -> Void in
            handler(result: (error == nil), error: error)
        }
        Log.exit()
    }
    
    
    // MARK: - Public APIs - Purchase
    
    func createPurchase(purchase: ZuzuPurchase, handler: (result: String?, error: NSError?) -> Void) {
        Log.enter()
        
        let url = self.host + "/purchase"
        let headers = self.getHeaders()
        
        Alamofire.upload(.POST, url, headers: headers, multipartFormData: { multipartFormData -> Void in
            multipartFormData.appendBodyPart(data: purchase.transactionId.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "transaction_id")
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
                            
                            
                            if code == 200 {
                                handler(result: json["data"].string, error: nil)
                            }
                            else {
                                let message = json["message"].stringValue
                                Log.debug("HTTP Resopnse Error = \(message)")
                                //assert(false, "Api response error:\n \(message)")
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
        
        Log.exit()
    }
    
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
    
    
    // MARK: - Public APIs - Service
    
    func getServiceByUserId(userId: String, handler: (result: AnyObject?, error: NSError?) -> Void) {
        Log.debug("Input parameters [userId: \(userId)]")
        
        let resource = "/service/\(userId)"
        
        self.responseJSON(.GET, resource: resource) { (result, error) -> Void in
            if let error = error {
                handler(result: nil, error: error)
            } else if let value = result {
                Log.debug("getServiceByUserId JSON: \(value)")
                
                if let serviceMapper = Mapper<ZuzuServiceMapper>().map(value) {
                    handler(result: serviceMapper, error: nil)
                } else {
                    handler(result: nil, error: NSError(domain: "Can not transfor to ZuzuService", code: -1, userInfo: nil))
                }
            } else {
                // Not found any service
                handler(result: nil, error: nil)
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
            
            if let payload = payload {
                Log.debug(closure: { () -> String? in
                    let payload = try! NSJSONSerialization.JSONObjectWithData(payload, options: [])
                    return "HTTP Request Payload: \(payload)"
                })
            }
            
            Log.debug("HTTP Resopnse = \(response)")
            
            if let handler = handler {
                switch result {
                case .Success(let value):
                    let json = JSON(value)
                    
                    Log.debug("HTTP Resopnse Json = \(json)")
                    
                    let code = json["code"].intValue
                    
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
                        //assert(false, "Api response error:\n \(message)")
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
        
        if AmazonClientManager.sharedInstance.isLoggedIn(){
            headers["UserId"] = AmazonClientManager.sharedInstance.currentUserProfile?.id
            headers["UserProvider"] = AmazonClientManager.sharedInstance.currentUserProfile?.provider?.rawValue
            headers["UserToken"] = AmazonClientManager.sharedInstance.currentUserToken
        }
        
        Log.debug("headers: \(headers)")
        
        return headers
    }

}