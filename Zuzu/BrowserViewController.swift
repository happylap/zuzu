//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import WebKit
import SCLAlertView

private let Log = Logger.defaultLogger

class BrowserViewController: UIViewController {

    var enableToolBar: Bool = true

    var viewTitle: String?

    var sourceLink: String?

    /// House Item Data
    var houseItem: HouseItem?

    var agentType: Int?

    var agentName: String?

    var agentPhoneList: [String]?

    var agentMail: String?

    var prevNavBarTitleTextAttributes: [String : AnyObject]?

    struct ViewTransConst {
        static let displayHouseUrl: String = "displayHouseUrl"
    }

    @IBOutlet var pesudoAnchor: UIBarButtonItem!
    var webView: WKWebView?

    private var phoneNumberDic = [String:String]() /// display string : original number

    private let houseTypeLabelMaker: LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)

    // MARK: - Private Utils

    private func alertMailAppNotReady() {

        let alertView = SCLAlertView()

        let subTitle = "找不到預設的郵件應用，請到 [設定] > [郵件、聯絡資訊、行事曆] > 帳號，確認您的郵件帳號已經設置完成"

        alertView.showCloseButton = true

        alertView.showInfo("找不到預設的郵件應用", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }

    private func displayPhoneNumberMenu() {

        var message = "確認聯絡: "
        let maxDisplayChars = 15

        if let contactName = self.agentName {

            let toIndex: String.Index = contactName.startIndex
                .advancedBy(maxDisplayChars, limit: contactName.endIndex)

            if(maxDisplayChars < contactName.characters.count) {
                message += contactName.substringToIndex(toIndex) + "..."
            } else {
                message += contactName.substringToIndex(toIndex)
            }
        }

        if let agentType = self.agentType {
            let agentTypeStr = houseTypeLabelMaker.fromCodeForField("agent_type", code: agentType, defaultValue: "—")
            message += " (\(agentTypeStr))"
        }

        let optionMenu = UIAlertController(title: nil, message: message, preferredStyle: .ActionSheet)


        if let phoneNumbers = self.agentPhoneList {

            ///Add only first 3 numbers
            for phoneNumber in phoneNumbers.prefix(3) {

                var phoneDisplayString = phoneNumber
                let phoneComponents = phoneNumber.componentsSeparatedByString(PhoneExtensionChar)

                /// Convert to human-redable display format for phone number with extension
                if(phoneComponents.count == 2) {
                    phoneDisplayString = phoneComponents.joinWithSeparator(DisplayPhoneExtensionChar)
                } else if (phoneComponents.count > 2) {
                    assert(false, "Incorrect phone number format \(phoneNumber)")
                }

                /// Bind phone number & display string
                self.phoneNumberDic[phoneDisplayString] = phoneNumber

                let numberAction = UIAlertAction(title: phoneDisplayString, style: .Default, handler: {
                    (alert: UIAlertAction!) -> Void in

                    var success = false

                    if let phoneDisplayStr = alert.title {

                        if let phoneStr = self.phoneNumberDic[phoneDisplayStr],
                            let url = NSURL(string: "tel://\(phoneStr)") {

                            success = UIApplication.sharedApplication().openURL(url)

                            if(success) {
                                /// Update contacted status
                                if let houseId = self.houseItem?.id {
                                    CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
                                }
                            }
                        }
                    }

                    ///GA Tracker
                    self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                        action: GAConst.Action.UIActivity.Contact,
                        label: GAConst.Label.Contact.Phone,
                        value:  UInt(success))

                })

                optionMenu.addAction(numberAction)
            }
        }

        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                action: GAConst.Action.UIActivity.Contact,
                label: GAConst.Label.Contact.Phone,
                value:  2)
        })

        optionMenu.addAction(cancelAction)

        self.presentViewController(optionMenu, animated: true, completion: nil)
    }

    private func configureNavigationBarItems() {
        if(enableToolBar) {
            ///Prepare custom UIButton for UIBarButtonItem
            let copyLinkButton: UIButton = UIButton(type: UIButtonType.Custom)
            copyLinkButton.setImage(UIImage(named: "copy_link")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            copyLinkButton.addTarget(self, action: #selector(BrowserViewController.copyLinkButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            copyLinkButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            copyLinkButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

            pesudoAnchor.customView = copyLinkButton
            pesudoAnchor.tintColor = UIColor.whiteColor()

            let phoneCallButton: UIButton = UIButton(type: UIButtonType.Custom)
            phoneCallButton.setImage(UIImage(named: "phone_n")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            phoneCallButton.addTarget(self, action: #selector(BrowserViewController.contactByPhoneButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            phoneCallButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

            let phoneCallBarButton = UIBarButtonItem(customView: phoneCallButton)
            phoneCallBarButton.tintColor = UIColor.whiteColor()
            phoneCallBarButton.enabled = false

            let sendMailButton: UIButton = UIButton(type: UIButtonType.Custom)
            sendMailButton.setImage(UIImage(named: "envelope_n")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            sendMailButton.addTarget(self, action: #selector(BrowserViewController.contactByMailButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            sendMailButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

            let sendMailBarButton = UIBarButtonItem(customView: sendMailButton)
            sendMailBarButton.tintColor = UIColor.whiteColor()
            sendMailBarButton.enabled = false

            if let _ = self.agentPhoneList {
                phoneCallBarButton.enabled = true
            }

            if let _ = self.agentMail {
                sendMailBarButton.enabled = true
            }

            /// From right to left
            self.navigationItem.setRightBarButtonItems(
                [
                    pesudoAnchor,
                    sendMailBarButton,
                    phoneCallBarButton
                ],
                animated: false)
        }
    }

    func copyLinkButtonTouched(sender: UIButton) {
        performSegueWithIdentifier(ViewTransConst.displayHouseUrl, sender: self)
    }

    func contactByPhoneButtonTouched(sender: UIButton) {

        self.displayPhoneNumberMenu()

    }

    func contactByMailButtonTouched(sender: UIButton) {

        /* Another way to allow sending mail by lauching default mail App
         * Our app will be suspended, and the user woulden't have a way to return to our App
         if let url = NSURL(string: "mailto:jon.doe@mail.com") {
         UIApplication.sharedApplication().openURL(url)
         }
         */


        if let houseItem = self.houseItem {

            let title = houseItem.title
            let addr = houseItem.addr

            let emailTitle = "租屋物件詢問: " + (title ?? addr ?? "")

            if let email = self.agentMail {

                var messageBody = "房東您好! 我最近從豬豬快租查詢到您在網路上刊登的租屋物件：\n\n"

                let toRecipents = [email]

                LoadingSpinner.shared.startOnView(self.view)

                if let sourceLink = self.sourceLink {
                    messageBody += "租屋物件網址: \(sourceLink) \n\n"
                }

                messageBody += "我對於這個物件很感興趣，想跟您約時間看屋。\n再麻煩您回覆方便的時間！\n"

                if MFMailComposeViewController.canSendMail() {
                    if let mc: MFMailComposeViewController = MFMailComposeViewController() {
                        ///Change Bar Item Color
                        mc.navigationBar.tintColor = UIColor.whiteColor()

                        mc.mailComposeDelegate = self
                        mc.setSubject(emailTitle)
                        mc.setMessageBody(messageBody, isHTML: false)
                        mc.setToRecipients(toRecipents)
                        self.presentViewController(mc, animated: true, completion: {
                            LoadingSpinner.shared.stop()
                        })
                    }

                } else {
                    alertMailAppNotReady()
                    LoadingSpinner.shared.stop()
                }

            } else {
                Log.debug("No emails available")
            }
        }
    }

    deinit {
        self.webView?.removeObserver(self, forKeyPath: "title", context: nil)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        if let keyPath = keyPath {
            switch keyPath {
            case "title":
                if let title = change?[NSKeyValueChangeNewKey] as? String {
                    self.title = title
                }
            default:
                break
            }
        }
    }

    override func loadView() {
        super.loadView()

        self.webView = WKWebView(frame: CGRect.zero)
        self.title = viewTitle
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            self.navigationController?.navigationBar.titleTextAttributes = self.prevNavBarTitleTextAttributes
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarItems()

        self.prevNavBarTitleTextAttributes = self.navigationController?.navigationBar.titleTextAttributes

        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont.boldSystemFontOfSize(16), NSForegroundColorAttributeName: UIColor.whiteColor()]

        self.webView?.addObserver(self, forKeyPath:"title", options:.New, context:nil)

        view.addSubview(self.webView!)

        /// Stretch the WKWebView to fit the parent
        webView!.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView!, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView!, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])

        if let sourceLink = self.sourceLink {
            if let url = NSURL(string:sourceLink) {
                self.webView?.UIDelegate = self
                self.webView?.navigationDelegate = self
                let req = NSURLRequest(URL:url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)

                if let webView = self.webView {
                    webView.loadRequest(req)
                }
            }
        }
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        ///Google Analytics Tracker
        self.trackScreen()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {

            Log.debug("prepareForSegue: \(identifier)")

            switch identifier {
            case ViewTransConst.displayHouseUrl:

                if let urlVc = segue.destinationViewController as? UrlPopoverViewController {
                    urlVc.urlLabelText = self.sourceLink
                    urlVc.delegate = self

                    if let pVc = urlVc.presentationController {
                        pVc.delegate = self
                    }
                }

            default: break
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension BrowserViewController: UIAdaptivePresentationControllerDelegate {

    //Need to figure out the use of this...
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

}

extension BrowserViewController: UrlPopoverViewControllerDelegate {

    func onUrlCopiedDone(status: Bool) {
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setMinShowTime(1.5)
        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setOpacity(0.5)
        LoadingSpinner.shared.setText("已複製")
        if let image = UIImage(named: "checked_green") {

            LoadingSpinner.shared.setCustomView(UIImageView(image: image))

        }
        LoadingSpinner.shared.startOnView(self.view)

        LoadingSpinner.shared.stop()
    }

}

extension BrowserViewController: WKNavigationDelegate {

    private func makePhoneCallConfirmation(targetUrl: NSURL, phoneNum: String) {

        let alertView = UIAlertController(title: "確認撥打電話\n" + phoneNum, message: nil, preferredStyle: UIAlertControllerStyle.Alert)

        let callAction = UIAlertAction(title: "撥打", style: .Default) { (action) -> Void in

            let success = UIApplication.sharedApplication().openURL(targetUrl)

            if(success) {

                /// Update contacted status
                if let houseId = self.houseItem?.id {
                    CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
                }

            }

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.Contact,
                                            label: GAConst.Label.Contact.Phone,
                                            value:  UInt(success))

        }

        let cancelAction = UIAlertAction(title: "取消", style: .Cancel) { (action) -> Void in

            ///GA Tracker
            self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                            action: GAConst.Action.UIActivity.Contact,
                                            label: GAConst.Label.Contact.Phone,
                                            value:  2)

        }

        alertView.addAction(callAction)
        alertView.addAction(cancelAction)

        // Show Alert View
        self.presentViewController(alertView, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {

        Log.enter()

        switch (navigationAction.navigationType) {
        case .LinkActivated:
            Log.debug("LinkActivated")
        case .FormSubmitted:
            Log.debug("FormSubmitted")
        case .BackForward:
            Log.debug("BackForward")
        case .Reload:
            Log.debug("Reload")
        case .FormResubmitted:
            Log.debug("FormResubmitted")
        case .Other:
            Log.debug("Other")
        }

        if let targetUrl = navigationAction.request.URL {

            Log.debug("targetUrl = \(targetUrl.absoluteString)")

            if(targetUrl.scheme == "tel") {

                if(UIApplication.sharedApplication().canOpenURL(targetUrl)) {

                    if let phoneNum = targetUrl.absoluteString.characters.split(":").last {

                        makePhoneCallConfirmation(targetUrl, phoneNum: String(phoneNum))

                    }

                    decisionHandler(WKNavigationActionPolicy.Cancel)
                }

                return
            }

            if(targetUrl.scheme == "mailto") {

                if(UIApplication.sharedApplication().canOpenURL(targetUrl)) {

                    UIApplication.sharedApplication().openURL(targetUrl)

                    decisionHandler(WKNavigationActionPolicy.Cancel)
                }

                return
            }

            decisionHandler(WKNavigationActionPolicy.Allow)

        } else {

            Log.debug("No targetUrl")
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Log.enter()

        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setMinShowTime(2)
        LoadingSpinner.shared.startOnView(webView)
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        Log.enter()

        LoadingSpinner.shared.stop()
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        Log.enter()
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        Log.enter()
        LoadingSpinner.shared.stop()
    }
}

extension BrowserViewController: WKUIDelegate {

    // this handles target=_blank links by opening them in the same view
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {

            webView.loadRequest(navigationAction.request)

        }
        return nil
    }

    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {

        let alertView = SCLAlertView()

        alertView.showCloseButton = false

        alertView.addButton("知道了") {
            completionHandler()
        }

        alertView.showInfo("網頁訊息", subTitle: message, colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
    }

    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {

        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .ActionSheet)

        alertController.addAction(UIAlertAction(title: "確定", style: .Default, handler: { (action) in
            completionHandler(true)
        }))

        alertController.addAction(UIAlertAction(title: "取消", style: .Default, handler: { (action) in
            completionHandler(false)
        }))

        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {

        let alertController = UIAlertController(title: nil, message: prompt, preferredStyle: .ActionSheet)

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "確定", style: .Default, handler: { (action) in
            if let text = alertController.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }

        }))

        alertController.addAction(UIAlertAction(title: "取消", style: .Default, handler: { (action) in

            completionHandler(nil)

        }))

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}

// MARK: - MFMailComposeViewControllerDelegate
// Handle Mail Sending Results
extension BrowserViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {

        var success = false

        switch result {
        case MFMailComposeResultCancelled:
            Log.debug("Mail cancelled")
        case MFMailComposeResultSaved:
            Log.debug("Mail saved")
        case MFMailComposeResultSent:
            success = true
            Log.debug("Mail sent")
            if let houseId = self.houseItem?.id {
                CollectionItemService.sharedInstance.updateContacted(houseId, contacted: true)
            }
        case MFMailComposeResultFailed:
            Log.debug("Mail sent failure: \(error?.localizedDescription)")
        default:
            break
        }

        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                        action: GAConst.Action.UIActivity.Contact,
                                        label: GAConst.Label.Contact.Email,
                                        value:  UInt(success))

        //self.navigationController?.popViewControllerAnimated(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
