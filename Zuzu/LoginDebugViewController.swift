//
//  LoginDebugViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import SCLAlertView
import FBSDKLoginKit

private let Log = Logger.defaultLogger

class LoginDebugViewController: UIViewController {
    
    private var responder: SCLAlertViewResponder?
    
    @IBOutlet weak var googleLogin: UIButton! {
        didSet {
            googleLogin.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var facebookLogin: UIButton! {
        didSet {
            facebookLogin.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var generateTransButton: UIButton!{
        didSet {
            generateTransButton.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var finishTransButton: UIButton!{
        didSet {
            finishTransButton.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var currentUser: UIButton! {
        didSet {
            currentUser.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var cognitoIdentity: UIButton! {
        didSet {
            cognitoIdentity.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    
    @IBOutlet weak var webApi: UIButton! {
        didSet {
            webApi.layer.borderColor = UIColor.colorWithRGB(0x0080FF).CGColor
        }
    }
    
    @IBOutlet weak var webApiPickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginDebugViewController.handleTokenRefreshed(_:)), name: UserLoginNotification, object: nil)
        // Do any additional setup after loading the view.
        
        self.webApiPickerView.dataSource = self;
        self.webApiPickerView.delegate = self;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleTokenRefreshed(notification: NSNotification){
        
        self.runOnMainThread { () -> Void in
            
            Log.enter()
            
            if let status = notification.userInfo?["status"] as? Int {
                if(status == LoginStatus.Resume.rawValue) {
                    
                    if let provider = UserDefaultsUtils.getLoginProvider(){
                        switch(provider) {
                        case .FB:
                            self.popupFacebookStatus()
                        case .GOOGLE:
                            self.popupGoogleStatus()
                        case .ZUZU:
                            Log.info("UserDefaultsUtils.getLoginProvider is ZUZU")
                        }
                    }
                    
                }
            }
        }
        
    }
    
    private func popupGoogleStatus() {
        
        Log.enter()
        
        responder?.close()
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Google not logged in"
        
        if let googleToken = GIDSignIn.sharedInstance().currentUser?.authentication?.idToken {
            
            subTitle = "Google Token = \n\(googleToken)" +
                "\n\n Token Expiry = \(GIDSignIn.sharedInstance().currentUser?.authentication?.idTokenExpirationDate ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
        }
        
        if(AmazonClientManager.sharedInstance.isLoggedInWithGoogle()) {
            myAlert.addButton("Refresh") { () -> Void in
                AmazonClientManager.sharedInstance.reloadGSession()
            }
            
            myAlert.addButton("Validate") { () -> Void in
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id {
                    
                    let provider = UserDefaultsUtils.getLoginProvider()
                    
                    if(provider == Provider.GOOGLE) {
                        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                            SCLAlertView().showInfo("Validation Result", subTitle: "Result: \(result), Error: \(error)")
                        }
                    }
                }
                
            }
        }
        
        responder = myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onGoogleLoginButtonTouched(sender: UIButton) {
        
        self.popupGoogleStatus()
        
    }
    
    
    @IBAction func onGenerateTransButtonTouched(sender: UIButton) {
        ZuzuStore.sharedInstance.requestProducts { (success, products) -> () in
            
            if let firstProduct = products.first {
                
                let zuzuProduct = ZuzuProduct(productIdentifier: firstProduct.productIdentifier, localizedTitle: firstProduct.localizedTitle, price: firstProduct.price, priceLocale: firstProduct.priceLocale)
                
                ZuzuStore.sharedInstance.makePurchase(zuzuProduct, handler: nil)
                
            } else {
                
                SCLAlertView().showInfo("Purchase Error", subTitle: "No available product")
                
            }
        }
    }
    
    @IBAction func onFinishTransaction(sender: AnyObject) {
        let unfinishedTranscations = ZuzuStore.sharedInstance.getUnfinishedTransactions()
        if unfinishedTranscations.count > 0{
            for transaction in unfinishedTranscations{
                ZuzuStore.sharedInstance.finishTransaction(transaction)
            }
        }
    }
    
    private func popupFacebookStatus() {
        
        Log.enter()
        
        responder?.close()
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Facebook not logged in"
        
        if let fbToken = FBSDKAccessToken.currentAccessToken()?.tokenString {
            
            subTitle = "FB Token = \n\(fbToken)" +
                "\n\n Token Expiry = \(FBSDKAccessToken.currentAccessToken()?.expirationDate ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
        }
        
        if(AmazonClientManager.sharedInstance.isLoggedInWithFacebook()) {
            myAlert.addButton("Refresh") { () -> Void in
                AmazonClientManager.sharedInstance.reloadFBSession()
            }
            
            myAlert.addButton("Validate") { () -> Void in
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id {
                    
                    let provider = UserDefaultsUtils.getLoginProvider()
                    
                    if(provider == Provider.FB) {
                        ZuzuWebService.sharedInstance.getCriteriaByUserId(userId) { (result, error) -> Void in
                            SCLAlertView().showInfo("Validation Result", subTitle: "Result: \(result), Error: \(error)")
                        }
                    }
                }
                
            }
        }
        
        responder = myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onFacebookLoginButtonTouched(sender: UIButton) {
        self.popupFacebookStatus()
    }
    
    private func popupCognitokStatus() {
        
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "Cognito not logged in"
        
        if let provider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration?.credentialsProvider as?  AWSCognitoCredentialsProvider {
            
            subTitle = "Cognito IdentityID = \n\(provider.identityId ?? "-")" +
                "\n\n IdentityID Expiry = \(provider.expiration ?? "-")" +
            "\n\n Now(UTC) = \(NSDate())"
            
            
        }
        
        myAlert.showTitle("Token Status", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
        
    }
    
    @IBAction func onCognitoButtonTouched(sender: UIButton) {
        self.popupCognitokStatus()
    }
    
    @IBAction func onCurrentUserButtonTouched(sender: UIButton) {
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        
        var subTitle = "No current user"
        
        if let currentUser = AmazonClientManager.sharedInstance.currentUserProfile {
            
            let provider = UserDefaultsUtils.getLoginProvider()
            
            subTitle = "UserId = \n\(currentUser.id ?? "-")" +
                "\n\n Provider = \(provider?.rawValue ?? "-")" +
            "\n\n Email = \(currentUser.email ?? "-")"
        }
        
        myAlert.showTitle("Current User", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }
    
    
    let apiNameArray = [
        "--- Tester ---",
        "checkEmail",
        "registerUser",
        "registerUser2",
        "getUserByEmail",
        "updateUser",
        "removeUser",
        "removeUser2",
        "loginUser2",
        " ",
        " ",
        "--- User ---",
        "retrieveCognitoToken",
        "getUserById",
        "createDeviceByUserId",
        "isExistDeviceByUserId",
        "deleteDeviceByUserId",
        "getCriteriaByUserId",
        "createCriteriaByUserId",
        "updateCriteriaFiltersByUserId",
        "enableCriteriaByUserId",
        "hasValidCriteriaByUserId",
        "deleteCriteriaByUserId",
        "updateCriteriaFiltersByUserId",
        "getNotificationItemsByUserId",
        "getNotificationItemsByUserId2",
        "setReadNotificationByUserId",
        "setReceiveNotifyTimeByUserId",
        "(createPurchase)",
        "getPurchaseByUserId",
        "getServiceByUserId"]
    
    
    var seletedApiName = ""
    let deviceTokenForTest = "123456789_for_test"
    let notifyItemIdForTest = "123456789_for_test"
    
    @IBAction func onWebApiButtonTouched(sender: UIButton) {
        Log.debug("onWebApiButtonTouched")
        
        
        switch self.seletedApiName {
            
        case "checkEmail":
            
            ZuzuWebService.sharedInstance.checkEmail(ApiTestConst.email, handler: { (emailExisted, provider, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                } else {
                    self.showAlert(title, subTitle: "\(subTitle) emailExisted: \(emailExisted), provider: \(provider)")
                }
            })
            
        case "registerUser":
            
            let user = ZuzuUser()
            user.provider = Provider.FB
            user.email = ApiTestConst.email
            user.name = ApiTestConst.email
            user.gender = "男性"
            
            ZuzuWebService.sharedInstance.registerUser(user, handler: { (userId, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(user.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let userId = userId {
                    self.showAlert(title, subTitle: "\(subTitle) userId: \(userId)")
                }
                
            })
            
        case "registerUser2":
            
            let user = ZuzuUser()
            user.provider = Provider.ZUZU
            user.email = ApiTestConst.email2
            user.name = ApiTestConst.email2
            user.gender = "男性"
            
            ZuzuWebService.sharedInstance.registerUser(user, password: ApiTestConst.password2, handler: { (userId, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(user.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let userId = userId {
                    self.showAlert(title, subTitle: "\(subTitle) userId: \(userId)")
                }
                
            })
            
            
        case "getUserByEmail":
            
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let user: ZuzuUser = result {
                    self.showAlert(title, subTitle: "\(subTitle) userId: \(user.id)\n email: \(user.email)\n registerTime: \(user.registerTime)\n name: \(user.name)\n gender: \(user.gender)\n birthday: \(user.birthday)")
                }
            })
            
            
        case "removeUser":
            
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let user: ZuzuUser = result {
                    ZuzuWebService.sharedInstance.removeUserById(user.id, email: user.email!, handler: { (result, error) -> Void in
                        if let error = error {
                            self.showAlert(title, subTitle: "\(subTitle) \(error)")
                        } else {
                            self.showAlert(title, subTitle: "\(subTitle) \(result)")
                        }
                    })
                }
            })
            
        case "removeUser2":
            
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email2, handler: { (result, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email2) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let user: ZuzuUser = result {
                    ZuzuWebService.sharedInstance.removeUserById(user.id, email: user.email!, handler: { (result, error) -> Void in
                        if let error = error {
                            self.showAlert(title, subTitle: "\(subTitle) \(error)")
                        } else {
                            self.showAlert(title, subTitle: "\(subTitle) \(result)")
                        }
                    })
                }
            })
            
        case "updateUser":
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let user: ZuzuUser = result {
                    user.name = "Tester2"
                    user.gender = "女性"
                    user.birthday = NSDate()
                    user.pictureUrl = "456"
                    ZuzuWebService.sharedInstance.updateUser(user, handler: { (result, error) -> Void in
                        if let error = error {
                            self.showAlert(title, subTitle: "\(subTitle) \(error)")
                        } else {
                            self.showAlert(title, subTitle: "\(subTitle) \(result)")
                        }
                    })
                }
            })
            
            
        case "removeUser":
            
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                
                let title = "Tester"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let user: ZuzuUser = result {
                    ZuzuWebService.sharedInstance.removeUserById(user.id, email: user.email!, handler: { (result, error) -> Void in
                        if let error = error {
                            self.showAlert(title, subTitle: "\(subTitle) \(error)")
                        } else {
                            self.showAlert(title, subTitle: "\(subTitle) \(result)")
                        }
                    })
                }
            })
            
        case "loginUser2":
            
            ZuzuWebService.sharedInstance.loginByEmail(ApiTestConst.email2, password: ApiTestConst.password2, handler: { (zuzuToken, error) in
                let title = "User"
                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email2) \n\n password: \(ApiTestConst.password2) \n\n result: \n"
                
                if let error = error {
                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                }
                
                if let zuzuToken = zuzuToken {
                    self.showAlert(title, subTitle: "zuzuToken: \(zuzuToken)")
                }
            })
            
        case "retrieveCognitoToken":
            ZuzuWebService.sharedInstance.loginByEmail(ApiTestConst.email2, password: ApiTestConst.password2, handler: { (zuzuToken, error) in
                
                
                if let zuzuToken = zuzuToken {
                    ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email2, handler: { (result, error) in
                        
                        if let user: ZuzuUser = result {
                            
                            let logins = ["com.lap.zuzu.login": user.id]
                            ZuzuWebService.sharedInstance.retrieveCognitoToken(user.id, zuzuToken: zuzuToken, identityId: nil, logins: logins, handler: { (identityId, token, error) in
                                
                                let title = "User"
                                let subTitle = "API: \(self.seletedApiName) \n\n email: \(ApiTestConst.email2) \n\n userId: \(user.id) \n\n zuzuToken: \(zuzuToken) \n\n logins: \(logins) \n\n result: \n"
                
                                if let error = error {
                                    self.showAlert(title, subTitle: "\(subTitle) \(error)")
                                }
                                
                                if let identityId = identityId, let token = token {
                                    self.showAlert(title, subTitle: "\(subTitle) identityId: \(identityId), token: \(token)")
                                }
                            })
                        }
                    })
                }
            })
            
            
        case "createDeviceByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                let deviceId = self.deviceTokenForTest
                
                ZuzuWebService.sharedInstance.createDeviceByUserId(userId, deviceId: deviceId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n deviceId:\(deviceId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
            })
            
        case "isExistDeviceByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                let deviceId = self.deviceTokenForTest
                
                ZuzuWebService.sharedInstance.isExistDeviceByUserId(userId, deviceId: deviceId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n deviceId:\(deviceId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
            })
            
        case "deleteDeviceByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                let deviceId = self.deviceTokenForTest
                
                ZuzuWebService.sharedInstance.deleteDeviceByUserId(userId, deviceId: deviceId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n deviceId:\(deviceId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
            })
            
        case "getCriteriaByUserId":
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId, handler: { (result, error) -> Void in
                    let title = "User"
                    var subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let c: ZuzuCriteria = result {
                        subTitle = "\(subTitle) criteriaId: \(c.criteriaId)\n enabled: \(c.enabled)\n"
                        
                        if let critaria: SearchCriteria = c.criteria {
                            subTitle = "\(subTitle) criteria: (size: \(critaria.size), price: \(critaria.price), types: \(critaria.types))"
                        }
                        
                        self.showAlert(title, subTitle: subTitle)
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) not find criteria")
                    }
                })
                
            })
            
        case "createCriteriaByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                let criteria = SearchCriteria()
                criteria.size = (0, 100)
                criteria.price = (10000, 20000)
                criteria.types = [1,2,3]
                
                ZuzuWebService.sharedInstance.createCriteriaByUserId(userId, criteria: criteria, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
            })
            
            
        case "updateCriteriaFiltersByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let criteriaId = result?.criteriaId {
                        
                        let criteria = SearchCriteria()
                        criteria.size = (200, 300)
                        criteria.price = (50000, 100000)
                        criteria.types = [4,5,6]
                        
                        ZuzuWebService.sharedInstance.updateCriteriaFiltersByUserId(userId, criteriaId: criteriaId, criteria: criteria, handler: { (result, error) -> Void in
                            if let error = error {
                                self.showAlert(title, subTitle: "\(subTitle) \(error)")
                            } else {
                                self.showAlert(title, subTitle: "\(subTitle) \(result)")
                            }
                        })
                        
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) not find criteria")
                    }
                })
            })
            
        case "enableCriteriaByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.getCriteriaByUserId(userId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let criteriaId = result?.criteriaId {
                        
                        let enabled = false
                        let subTitle2 = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n criteriaId: \(criteriaId) \n\n enabled: \(enabled) \n\n result: \n"
                        
                        ZuzuWebService.sharedInstance.enableCriteriaByUserId(userId, criteriaId: criteriaId, enabled: enabled, handler: { (result, error) -> Void in
                            if let error = error {
                                self.showAlert(title, subTitle: "\(subTitle2) \(error)")
                            } else {
                                self.showAlert(title, subTitle: "\(subTitle2) \(result)")
                            }
                        })
                        
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) not find criteria")
                    }
                })
            })
            
        case "hasValidCriteriaByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.hasValidCriteriaByUserId(userId, handler: { (result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
                
            })
            
        case "deleteCriteriaByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.deleteCriteriaByUserId(userId, handler: { (result, error) -> Void in
                    
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
            })
            
        case "getNotificationItemsByUserId":
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, postTime: nil, handler: { (totalNum, result, error) -> Void in
                    
                })
                
                ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, handler: { (totalNum, result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let _ = result {
                        self.showAlert(title, subTitle: "\(subTitle) totalNum: \(totalNum)")
                    }
                })
                
            })
            
        case "getNotificationItemsByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                
                ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, handler: { (totalNum, result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
                
            })
            
        case "getNotificationItemsByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                
                ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, handler: { (totalNum, result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
                
            })
            
        case "getNotificationItemsByUserId2":
            
            self.checkLogin({ (userId, email) -> Void in
                
                let postTime = NSDate()
                
                ZuzuWebService.sharedInstance.getNotificationItemsByUserId(userId, postTime: postTime, handler: { (totalNum, result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n postTime: \(postTime) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
                
            })
            
        case "setReceiveNotifyTimeByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                let deviceId = self.deviceTokenForTest
                
                ZuzuWebService.sharedInstance.setReceiveNotifyTimeByUserId(userId, deviceId: deviceId, handler: { (result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n deviceId: \(deviceId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    } else {
                        self.showAlert(title, subTitle: "\(subTitle) \(result)")
                    }
                })
                
            })
            
            
        case "getPurchaseByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                ZuzuWebService.sharedInstance.getPurchaseByUserId(userId, handler: { (totalNum, result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let _ = result {
                        self.showAlert(title, subTitle: "\(subTitle) totalNum: \(totalNum)")
                    }
                })
                
            })
            
        case "getServiceByUserId":
            
            self.checkLogin({ (userId, email) -> Void in
                
                ZuzuWebService.sharedInstance.getServiceByUserId(userId, handler: { (result, error) -> Void in
                    let title = "User"
                    let subTitle = "API: \(self.seletedApiName) \n\n userId: \(userId) \n\n result: \n"
                    
                    if let error = error {
                        self.showAlert(title, subTitle: "\(subTitle) \(error)")
                    }
                    
                    if let mapper: ZuzuServiceMapper = result {
                        let userId = mapper.userId
                        let status = mapper.status
                        let totalSecond = mapper.totalSecond
                        let remainingSecond = mapper.remainingSecond
                        let startTime = mapper.startTime
                        let expireTime = mapper.expireTime
                        let validPurchaseCount = mapper.validPurchaseCount
                        let invalidPurchaseCount = mapper.invalidPurchaseCount
                        
                        self.showAlert(title, subTitle: "\(subTitle) userId: \(userId)\n status: \(status)\n totalSecond: \(totalSecond)\n remainingSecond: \(remainingSecond)\n startTime: \(startTime)\n expireTime: \(expireTime)\n validPurchaseCount: \(validPurchaseCount)\n invalidPurchaseCount: \(invalidPurchaseCount)")
                    }
                })
            })
            
            
        default:
            self.showAlert("\(seletedApiName) Api", subTitle: "Testing code not implement")
        }
        
    }
    
    private func checkLogin(handler: (userId: String, email: String) -> Void) {
        if AmazonClientManager.sharedInstance.isLoggedIn() {
            if let userProfile = AmazonClientManager.sharedInstance.currentUserProfile {
                if let userId = userProfile.id, email = userProfile.email {
                    handler(userId: userId, email: email)
                    return
                }
            }
        }
        self.showAlert("提醒", subTitle: "請先登入")
    }
    
    private func showAlert(title: String, subTitle: String) {
        let myAlert = SCLAlertView()
        myAlert.showCloseButton = true
        myAlert.showTitle(title, subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}

extension LoginDebugViewController: UIPickerViewDataSource{
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    //回傳資料筆數
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return apiNameArray.count
    }
    
}

extension LoginDebugViewController: UIPickerViewDelegate{
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return apiNameArray[row]
    }
    
    //當選取時，將目標選取進行呼叫
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let v = apiNameArray[row]
        Log.debug("select \(v)")
        self.seletedApiName = v
    }
    
}
