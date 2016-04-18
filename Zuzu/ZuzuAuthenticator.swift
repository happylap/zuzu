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
/// Zuzu Token
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

/// Zuzu Id
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
    
    //Not in use yet
    var expirationDate:NSDate?
}

/// ZuzuAuthenticator
class ZuzuAuthenticator {
    
    typealias LoginCompletionHandler = (result: FormResult, userId: String?) -> ()
    
    typealias RegisterCompletionHandler = (result: FormResult) -> ()
    
    private static let userLoginTokenKey = "zuzuUserLoginToken"
    
    private static let userLoginIdKey = "zuzuUserLoginId"
    
    private var onLoginComplete: LoginCompletionHandler?
    
    private var onRegisterComplete: RegisterCompletionHandler?
    
    /// Bring Up Zuzu login/Register UI
    func loginWithZuzu(fromViewController: UIViewController, handler: LoginCompletionHandler) {
        Log.enter()
        
        onLoginComplete = handler
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("inputFormView") as? FormViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.formMode = .Login
            
            vc.delegate = self
            fromViewController.presentViewController(vc, animated: true, completion: nil)
        }
        
        Log.exit()
    }
    
    func registerWithZuzu(fromViewController: UIViewController,
                          registerHandler: RegisterCompletionHandler, loginHandler: LoginCompletionHandler) {
        Log.enter()
        
        onLoginComplete = loginHandler
        onRegisterComplete = registerHandler
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("inputFormView") as? FormViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.formMode = .Register
            
            vc.delegate = self
            fromViewController.presentViewController(vc, animated: true, completion: nil)
        }
        
        Log.exit()
    }
    
    /// Logout Zuzu account
    func logout() {
        Log.enter()
        
        clearZuzuToken()
        clearUserId()
        
        Log.exit()

    }
    
    /// Retrive tokens from Zuzu backend
    func retrieveToken(userIdentifier: String, zuzuToken: String,
                       identityId: String?, logins: [NSObject : AnyObject],
                       handler: (identityId: String?, token: String?, error: ErrorType?) -> Void) {
        Log.enter()
        
        ZuzuWebService.sharedInstance.retrieveCognitoToken(userIdentifier, zuzuToken: zuzuToken, identityId: identityId, logins: logins) { (identityId, token, error) in
            
            handler(identityId: identityId, token: token, error: error)
            
        }
        
        Log.exit()

    }
    
}

// MARK: FormViewControllerDelegate
extension ZuzuAuthenticator: FormViewControllerDelegate {
    
    func onLoginDone(result: FormResult, userId: String?, zuzuToken: String?) {
        
        Log.debug("userId = \(userId), zuzuToken = \(zuzuToken)")
        
        switch(result) {
        case .Success:
            if let userId = userId, let zuzuToken = zuzuToken {
                
                saveZuzuToken(zuzuToken)
                saveUserId(userId)
                
            }
        default: break
        }
        
        self.onLoginComplete?(result: result, userId: userId)
    }
    
    func onRegisterDone(result: FormResult) {
        Log.debug("result = \(result)")
        
        self.onRegisterComplete?(result: result)
    }
}
