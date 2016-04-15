import Foundation
import AWSCore
import Alamofire

private let Log = Logger.defaultLogger

class ZuzuAuthenticatedIdentityProvider : AWSAbstractCognitoIdentityProvider {
    private static let errorDomain: String = "com.zuzu"
    private let authenticator: ZuzuAuthenticator!
    private let _providerName: String!
    private var _token: String!
    
    init!(providerName: String!, authenticator: ZuzuAuthenticator!, regionType: AWSRegionType, identityId: String!, identityPoolId: String!, logins: [NSObject : AnyObject]!) {
        
        self.authenticator = authenticator
        self._providerName = providerName
        super.init(regionType: regionType, identityId: identityId, accountId: nil, identityPoolId: identityPoolId, logins: logins)
    }
    
    override var providerName : String {
        return _providerName
    }
    
    override var token: String {
        if (!authenticatedWithProvider) {
            return super.token
        } else {
            return _token
        }
    }
    
    /// Check if current logins contain custom authentication
    private var authenticatedWithProvider: Bool {
        get {
            return self.logins[self.providerName] != nil
        }
    }
    
    override func getIdentityId() -> AWSTask! {
        
        if (self.identityId != nil) {
            // already has identityId, just return it
            
            return AWSTask(result: self.identityId)
            
        } else if (!authenticatedWithProvider) {
            // not authenticated with our developer provider
            
            return super.getIdentityId()
            
        }
        
        return AWSTask(result: nil).continueWithBlock({ (task) -> AnyObject! in
            return self.refresh()
        })
    }
    
    override func refresh() -> AWSTask! {
        
        // not authenticated with our developer provider
        if (!authenticatedWithProvider) {
            return super.refresh()
        }
        
        // Try to get token from Zuzu backend
        let task = AWSTaskCompletionSource()
        
        if let userId = ZuzuAccessToken.currentAccessToken.userId,
            token = ZuzuAccessToken.currentAccessToken.token,
            logins = self.logins {
            
            self.authenticator.retrieveToken(userId, zuzuToken: token,
                                             identityId: self.identityId, logins: logins) { (identityId, token, error) in
                                                
                                                if let identityId = identityId, token = token {
                                                    
                                                    self.identityId = identityId
                                                    self._token = token
                                                    
                                                } else {
                                                    
                                                    task.setError(self.errorWithCode(5000, failureReason: "No Cognito token"))
                                                }
                                                
            }
            
        }  else {
            task.setError(self.errorWithCode(5000, failureReason: "Not authorized to retrieve token"))
        }
        
        return task.task
    }
    
    private func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: ZuzuAuthenticatedIdentityProvider.errorDomain, code: code, userInfo: userInfo)
    }
}