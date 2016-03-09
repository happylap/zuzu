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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTokenRefreshed:", name: UserLoginNotification, object: nil)
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
                    
                    if let provider = AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                        switch(provider) {
                        case .FB:
                            self.popupFacebookStatus()
                        case .GOOGLE:
                            self.popupGoogleStatus()
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
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, provider =  AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                    
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
                
                if let userId = AmazonClientManager.sharedInstance.currentUserProfile?.id, provider =  AmazonClientManager.sharedInstance.currentUserProfile?.provider {
                    
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
            
            subTitle = "UserId = \n\(currentUser.id ?? "-")" +
                "\n\n Provider = \(currentUser.provider?.rawValue ?? "-")" +
            "\n\n Email = \(currentUser.email ?? "-")"
        }
        
        myAlert.showTitle("Current User", subTitle: subTitle, style: SCLAlertViewStyle.Notice, colorStyle: 0x1CD4C6)
    }
    
    
    let apiNameArray = [
        "isExistEmail",
        "registerUser",
        "---",
        "getUserByEmail",
        "getUserById",
        "updateUser",
        "---",
        "createDeviceByUserId",
        "deleteDeviceByUserId",
        "isExistDeviceByUserId",
        "---",
        "getCriteriaByUserId",
        "createCriteriaByUserId",
        "updateCriteriaFiltersByUserId",
        "enableCriteriaByUserId",
        "hasValidCriteriaByUserId",
        "---",
        "getNotificationItemsByUserId",
        "setReadNotificationByUserId",
        "setReceiveNotifyTimeByUserId",
        "---",
        "createPurchase",
        "getPurchaseByUserId",
        "---",
        "getServiceByUserId"]
    

    var seletedApiName = ""
    
    @IBAction func onWebApiButtonTouched(sender: UIButton) {
        Log.debug("onWebApiButtonTouched")
        
        if (self.seletedApiName == "isExistEmail") {
            ZuzuWebService.sharedInstance.isExistEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                if let error = error {
                    self.showAlert("\(self.seletedApiName) Api", subTitle: "error: \(error)")
                } else {
                    self.showAlert("\(self.seletedApiName) Api", subTitle: "result: \(result)")
                }
            })
        }
        
        else if (self.seletedApiName == "registerUser") {
            let zuzuUser = ZuzuUser()
            zuzuUser.email = ApiTestConst.email
            
            ZuzuWebService.sharedInstance.registerUser(zuzuUser, handler: { (userId, error) -> Void in
                if let error = error {
                    self.showAlert("\(self.seletedApiName) Api", subTitle: "error: \(error)")
                }
                
                if let userId = userId {
                    let subTitle = "return userId: \(userId)"
                    self.showAlert("\(self.seletedApiName) Api", subTitle: subTitle)
                }
            })
        }
        
        else if (self.seletedApiName == "getUserByEmail") {
            ZuzuWebService.sharedInstance.getUserByEmail(ApiTestConst.email, handler: { (result, error) -> Void in
                if let error = error {
                    self.showAlert("\(self.seletedApiName) Api", subTitle: "error: \(error)")
                }
                
                if let user: ZuzuUser = result {
                    let subTitle = "userId: \(user.id)\n email: \(user.email)\n name: \(user.name)"
                    self.showAlert("\(self.seletedApiName) Api", subTitle: subTitle)
                }
            })
        }
            
        else if (self.seletedApiName == "getUserById") {
            ZuzuWebService.sharedInstance.getUserById(ApiTestConst.userId, handler: { (result, error) -> Void in
                if let error = error {
                    self.showAlert("\(self.seletedApiName) Api", subTitle: "error: \(error)")
                }
                
                if let user: ZuzuUser = result {
                    let subTitle = "userId: \(user.id)\n email: \(user.email)\n name: \(user.name)"
                    self.showAlert("\(self.seletedApiName) Api", subTitle: subTitle)
                }
            })
        }
        
        else {
            self.showAlert("\(seletedApiName) Api", subTitle: "Testing code not implement")
        }
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
