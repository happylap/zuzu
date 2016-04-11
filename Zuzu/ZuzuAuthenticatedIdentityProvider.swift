import Foundation
import AWSCore
import Alamofire

private let Log = Logger.defaultLogger

protocol CognitoAuthenticator {
    func retrieveToken(userIdentifier: String, identityId: String?,
                       success: (identityId: String?, token: String?, userIdentifier: String?) -> Void,
                       failure: (error: NSError) -> Void)
}

class ZuzuAuthenticatedIdentityProvider : AWSAbstractCognitoIdentityProvider {
    private static let errorDomain: String = "com.zuzu"
    private let authenticator: CognitoAuthenticator!
    private let _providerName: String!
    private var _token: String!
    
    init!(providerName: String!, authenticator: CognitoAuthenticator!, regionType: AWSRegionType, identityId: String!, identityPoolId: String!, logins: [NSObject : AnyObject]!) {
        
        self.authenticator = authenticator
        self._providerName = providerName
        super.init(regionType: regionType, identityId: identityId, accountId: nil, identityPoolId: identityPoolId, logins: logins)
    }
    
    override var providerName : String {
        return _providerName
    }
    
//    override var token: String {
//        return _token
//    }
    
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
            return super.getIdentityId()
        }
        
        // Try to get token from Zuzu backend
        let task = AWSTaskCompletionSource()
        self.authenticator.retrieveToken("", identityId: "",
                                         success: { (identityId, token, userIdentifier) in
                                            
                                            if let identityId = identityId, token = token, userIdentifier = userIdentifier {
                                                
                                                self.logins = [self.providerName: userIdentifier]
                                                self.identityId = identityId
                                                self._token = token
                                                task.setResult(self.identityId)
                                                
                                            } else {
                                                
                                                task.setError(self.errorWithCode(5000, failureReason: "CognitoAuthenicator returned no token"))
                                                
                                            }
            }, failure: { error in
                task.setError(error)
        })
        
        return task.task
    }
    
    private func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: ZuzuAuthenticatedIdentityProvider.errorDomain, code: code, userInfo: userInfo)
    }
}