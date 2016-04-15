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
            return UserDefaultsUtils.getUserProfile()?.id
        }
    }
    
    var token:String? {
        get {
            return UserDefaultsUtils.getZuzuToken()
        }
    }
    
    var expirationDate:NSDate?
}

/// ZuzuAuthenticator
class ZuzuAuthenticator {
    
    typealias LoginCompletionHandler = (result: LoginResult, zuzuUser: ZuzuUser?) -> ()
    
    private var onComplete: LoginCompletionHandler?
    
    /// Bring Up Zuzu login/Register UI
    func loginWithZuzu(fromViewController: UIViewController, handler: LoginCompletionHandler) {
        
        onComplete = handler
        
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("inputFormView") as? FormViewController {
            vc.modalPresentationStyle = .OverCurrentContext
            vc.formMode = .Login
            
            vc.delegate = self
            fromViewController.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    func registerWithZuzu(fromViewController: UIViewController, handler: LoginCompletionHandler) {
        
        onComplete = handler
        
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
        UserDefaultsUtils.clearZuzuToken()
    }
    
    func retrieveToken(userIdentifier: String, zuzuToken: String,
                       identityId: String?, logins: [String: String],
                       handler: (identityId: String?, token: String?, error: ErrorType?) -> Void) {
        
        
        /// Make sure is autenticated
        
        /// Retrive tokens from Zuzu backend
        ZuzuWebService.sharedInstance.retrieveCognitoToken(userIdentifier, zuzuToken: zuzuToken, identityId: identityId, logins: logins) { (identityId, token, error) in
            
            handler(identityId: identityId, token: token, error: error)
            
        }
        
    }
}

extension ZuzuAuthenticator: FormViewControllerDelegate {
    
    func onLoginDone(result: LoginResult, zuzuUser: ZuzuUser?, zuzuToken: String?) {
        
        Log.debug("zuzuToken = \(zuzuToken)")
        
        switch(result) {
        case .Success:
            if let zuzuUser = zuzuUser, let zuzuToken = zuzuToken {
                UserDefaultsUtils.saveZuzuToken(zuzuToken)
                UserDefaultsUtils.setUserProfile(zuzuUser)
            }
        default: break
        }
        
        self.onComplete?(result: result, zuzuUser: zuzuUser)
    }
    
    func onRegisterDone(success: Bool) {
        Log.debug("status = \(success)")
    }
}
