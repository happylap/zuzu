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

private let Log = Logger.defaultLogger

// MARK: Zuzu Auth Data Storage
private func saveZuzuToken(token: String) {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.setObject(token, forKey: ZuzuAuthenticator.userLoginTokenKey)
    userDefaults.synchronize()
}

private func clearZuzuToken() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.removeObjectForKey(ZuzuAuthenticator.userLoginTokenKey)
    userDefaults.synchronize()
}

private func getZuzuToken() -> String? {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let currentUserId = userDefaults.objectForKey(ZuzuAuthenticator.userLoginTokenKey) as? String
    
    return currentUserId
}

private func saveUserId(token: String) {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.setObject(token, forKey: ZuzuAuthenticator.userLoginIdKey)
    userDefaults.synchronize()
}

private func clearUserId() {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    userDefaults.removeObjectForKey(ZuzuAuthenticator.userLoginIdKey)
    userDefaults.synchronize()
}

private func getUserId() -> String? {
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let currentUserId = userDefaults.objectForKey(ZuzuAuthenticator.userLoginIdKey) as? String
    
    return currentUserId
}

/// ZuzuAccessToken
class ZuzuAccessToken {
    
    class var currentAccessToken: ZuzuAccessToken {
        struct Singleton {
            static let instance = ZuzuAccessToken()
        }
        
        return Singleton.instance
    }
    
    var userId: String? {
        get {
            return getUserId()
        }
    }
    
    var token:String? {
        get {
            return getZuzuToken()
        }
    }
    
    var expirationDate:NSDate?
}

/// ZuzuAuthenticator
class ZuzuAuthenticator {
    
    typealias LoginCompletionHandler = (result: FormResult, zuzuUser: ZuzuUser?) -> ()
    
    typealias RegisterCompletionHandler = (result: FormResult) -> ()
    
    private static let userLoginTokenKey = "zuzuUserLoginToken"
    
    private static let userLoginIdKey = "zuzuUserLoginId"
    
    private var onLoginComplete: LoginCompletionHandler?
    
    private var onRegisterComplete: RegisterCompletionHandler?
    
    /// Bring Up Zuzu login/Register UI
    func loginWithZuzu(fromViewController: UIViewController, handler: LoginCompletionHandler) {
        
        onLoginComplete = handler
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("inputFormView") as? FormViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.formMode = .Login
            
            vc.delegate = self
            fromViewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func registerWithZuzu(fromViewController: UIViewController,
                          registerHandler: RegisterCompletionHandler, loginHandler: LoginCompletionHandler) {
        
        onLoginComplete = loginHandler
        onRegisterComplete = registerHandler
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("inputFormView") as? FormViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.formMode = .Register
            
            vc.delegate = self
            fromViewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    /// Logout Zuzu account
    func logout() {
        clearZuzuToken()
        clearUserId()
    }
    
    func retrieveToken(userIdentifier: String, zuzuToken: String,
                       identityId: String?, logins: [NSObject : AnyObject],
                       handler: (identityId: String?, token: String?, error: ErrorType?) -> Void) {

        /// Retrive tokens from Zuzu backend
        ZuzuWebService.sharedInstance.retrieveCognitoToken(userIdentifier, zuzuToken: zuzuToken, identityId: identityId, logins: logins) { (identityId, token, error) in
            
            handler(identityId: identityId, token: token, error: error)
            
        }
        
    }
    
}

extension ZuzuAuthenticator: FormViewControllerDelegate {
    
    func onLoginDone(result: FormResult, zuzuUser: ZuzuUser?, zuzuToken: String?) {
        
        Log.debug("zuzuToken = \(zuzuToken)")
        
        switch(result) {
        case .Success:
            if let zuzuUser = zuzuUser, let zuzuToken = zuzuToken {
                
                saveZuzuToken(zuzuToken)
                saveUserId(zuzuUser.id)
                
            }
        default: break
        }
        
        self.onLoginComplete?(result: result, zuzuUser: zuzuUser)
    }
    
    func onRegisterDone(result: FormResult) {
        Log.debug("status = \(result)")
        
        self.onRegisterComplete?(result: result)
    }
}
