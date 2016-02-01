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
        static let HOST = "127.0.0.1" //"192.168.1.241"
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
        
        let urlString = "\(self.hostUrl)/notifyitem/\(userId)"
        
        Alamofire.request(.GET, urlString, encoding: .JSON)
            .responseJSON { (_, _, result) in
                Log.debug("urlString: \(urlString)")
                
                switch result {
                case .Success(let value):
                    
                    let json = JSON(value)
                    Log.debug("result: \(json)")
                    
                    var notifyItems: [NotifyItem] = [NotifyItem]()
                    
                    for (_, subJson): (String, JSON) in json {
                        if let notifyItem = Mapper<NotifyItem>().map(subJson.description) {
                            notifyItems.append(notifyItem)
                        }
                    }
                    
                    handler(result: notifyItems, error: nil)
                    
                case .Failure(_, let error):
                    Log.debug("error: \(error)")
                    handler(result: nil, error: error)
                }
                
        }
        Log.exit()
    }

}