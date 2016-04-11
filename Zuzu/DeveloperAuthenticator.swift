//
//  DeveloperAuthenticator.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/4/11.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import Alamofire
import AWSCore
import SwiftyJSON

class DeveloperAuthenticator: CognitoAuthenticator {
    
    private static let endpoint = "HTTP endpoint that retrieves a cognito developer token"
    
    typealias LoginCompletionHandler = (success: Bool, username: String) -> ()
    
    /// Check if authenticated against Zuzu
    func isAuthenticated() -> Bool {
        return false
    }
    
    /// Login with Zuzu
    func login(username: String, password: String, handler: LoginCompletionHandler){
        
        handler(success: true, username: username)
        
    }
    
    /// Logout Zuzu account
    func logout() {
        
    }
    
    func retrieveToken(
        userIdentifier: String,
        identityId: String?,
        success: (identityId: String?, token: String?, userIdentifier: String?) -> Void,
        failure: (error: NSError) -> Void) {
        
        
        /// Make sure is autenticated
        
        /// Retrive tokens from Zuzu backend
        let endpoint = DeveloperAuthenticator.endpoint
        
        var params = Dictionary<String, AnyObject>()
        params["userIdentifier"] = userIdentifier
        params["identityId"] = identityId
        
        Alamofire.request(.POST, endpoint, parameters: params, encoding: .JSON).validate().responseJSON(completionHandler: { (request, response, result) in
            
            switch result {
            case.Success(let data):
                let json = JSON(data)
                success(identityId: json["identityId"].string, token: json["token"].string, userIdentifier: json["userIdentifier"].string)
            case.Failure(_, let error):
                failure(error: ((error as Any) as! NSError))
            }
            
        })
    }
}