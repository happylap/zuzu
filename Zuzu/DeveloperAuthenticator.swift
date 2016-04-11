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
    
    func retrieveToken(
        success: (identityId: String?, token: String?, userIdentifier: String?) -> Void,
        failure: (error: NSError) -> Void) {
        
        let endpoint = DeveloperAuthenticator.endpoint
        
        Alamofire.request(.POST, endpoint, parameters: tokenParams(), encoding: .JSON).validate().responseJSON(completionHandler: { (request, response, result) in
            
            switch result {
            case.Success(let data):
                let json = JSON(data)
                success(identityId: json["identityId"].string, token: json["token"].string, userIdentifier: json["userIdentifier"].string)
            case.Failure(_, let error):
                failure(error: ((error as Any) as! NSError))
            }
            
        })
    }
    
    private func tokenParams() -> Dictionary<String, AnyObject> {
        // these values should come from keychain or some type of internal app storage
        var params = Dictionary<String, AnyObject>()
        params["userIdentifier"] = "KEY THAT IDENTIFIES THE USER THAT WILL LOOKUP AND GENERATE TOKEN FROM SERVER"
        params["identityId"] = "COGNITO IDENTITYID | USED IF GOING FROM UNAUTHED TO AUTHED OTHERWISE CAN BE REMOVED"
        return params
    }
}