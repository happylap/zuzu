//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import WebKit
import SCLAlertView
import AwesomeCache

private let Log = Logger.defaultLogger

@objc protocol BrowserViewDelegate {

    optional func onSourcePageLoaded(result: Bool)

}


class BrowserViewController: UIViewController {

    var enableToolBar: Bool = true

    /// Params
    var viewTitle: String?

    /// Mode 1: Arbitrary Link
    var sourceLink: String?

    /// Mode 2: House Item Data
    var houseItem: HouseItem?

    var delegate: BrowserViewDelegate?

    ///The full house detail returned from remote server
    private var houseItemDetail: AnyObject?

    struct ViewTransConst {
        static let displayHouseUrl: String = "displayHouseUrl"
    }

    private struct BrowserHouseDetailCache {
        static let cacheName = "browserHouseDetailCache"
        static let cacheTime: Double = 3 * 60 * 60 //3 hours
    }

    @IBOutlet var pesudoAnchor: UIBarButtonItem!
    var phoneCallBarButton: UIBarButtonItem?
    var sendMailBarButton: UIBarButtonItem?

    private var webView: WKWebView?

    private let externalSiteLabel = UILabel() //UILabel for displaying go to external site message

    private let externalSiteImage = UIImageView(image: UIImage(named: "external_site_image")?.imageWithRenderingMode(.AlwaysTemplate))

    private var networkErrorAlertView: SCLAlertView? = SCLAlertView()

    private var phoneNumberDic = [String:String]() /// display string : original number

    private let houseTypeLabelMaker: LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)

    // MARK: - Private Utils

    private func configureAutoScaleNavigationTitle(fontSize: Float) {

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFontOfSize(CGFloat(fontSize))
        titleLabel.text = self.navigationItem.title
        titleLabel.textColor = UIColor.whiteColor()
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.sizeToFit()

        self.navigationItem.titleView = titleLabel

    }

    private func configureExternalSiteMessage() {

        if let contentView = self.view {

            /// UILabel setting
            externalSiteLabel.translatesAutoresizingMaskIntoConstraints = false
            externalSiteLabel.textAlignment = NSTextAlignment.Center
            externalSiteLabel.numberOfLines = -1
            externalSiteLabel.font = UIFont.systemFontOfSize(14)
            externalSiteLabel.autoScaleFontSize = true
            externalSiteLabel.textColor = UIColor.grayColor()
            externalSiteLabel.text = SystemMessage.INFO.EXTERNAL_SITE_RESULT
            contentView.addSubview(externalSiteLabel)

            /// UIImage setting
            externalSiteImage.translatesAutoresizingMaskIntoConstraints = false
            externalSiteImage.tintColor = UIColor.lightGrayColor()
            let size = externalSiteImage.intrinsicContentSize()
            externalSiteImage.frame.size = size

            contentView.addSubview(externalSiteImage)

            /// Setup constraints for Label
            let xConstraint = NSLayoutConstraint(item: externalSiteLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xConstraint.priority = UILayoutPriorityRequired

            let yConstraint = NSLayoutConstraint(item: externalSiteLabel, attribute: NSLayoutAttribute.TopMargin, relatedBy: NSLayoutRelation.Equal, toItem: externalSiteImage, attribute: NSLayoutAttribute.BottomMargin, multiplier: 1.0, constant: 22)
            yConstraint.priority = UILayoutPriorityRequired

            let leftConstraint = NSLayoutConstraint(item: externalSiteLabel, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
            leftConstraint.priority = UILayoutPriorityDefaultLow

            let rightConstraint = NSLayoutConstraint(item: externalSiteLabel, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
            rightConstraint.priority = UILayoutPriorityDefaultLow

            /// Setup constraints for Image

            let xImgConstraint = NSLayoutConstraint(item: externalSiteImage, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
            xImgConstraint.priority = UILayoutPriorityRequired

            let yImgConstraint = NSLayoutConstraint(item: externalSiteImage, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)
            yImgConstraint.priority = UILayoutPriorityRequired


            /// Add constraints to contentView
            contentView.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint,
                xImgConstraint, yImgConstraint])
        }

    }

    private func alertItemNotFound() {

        let alertView = SCLAlertView()

        let subTitle = "請您參考其他物件，謝謝！"

        alertView.showCloseButton = false

        alertView.addButton("知道了") {
            self.navigationController?.popViewControllerAnimated(true)
        }
        alertView.showInfo("此物件已下架", subTitle: subTitle, colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }

    private func fetchHouseDetail(houseItem: HouseItem) {

        var hitCache = false

        do {
            let cache = try Cache<NSData>(name: BrowserHouseDetailCache.cacheName)

            ///Return cached data if there is cached data
            if let cachedData = cache.objectForKey(houseItem.id),
                let result = NSKeyedUnarchiver.unarchiveObjectWithData(cachedData) {

                Log.debug("Hit Cache for item: Id: \(houseItem.id), Title: \(houseItem.title)")

                hitCache = true

                handleHouseDetailResponse(result)
            }

        } catch _ {
            Log.debug("Something went wrong with the cache")
        }


        if(!hitCache) {

            HouseDataRequestService.getInstance().searchById(houseItem.id) { (result, error) -> Void in

                if let error = error {
                    Log.debug("Cannot get remote data \(error.localizedDescription)")

                    self.delegate?.onSourcePageLoaded?(false)

                    if let alertView = self.networkErrorAlertView {
                        let subTitle = "您目前可能處於飛航模式或是無網路狀態，暫時無法檢視詳細資訊。"
                        alertView.showCloseButton = true
                        alertView.showInfo("網路無法連線", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
                    }

                    return
                }

                if let result = result {

                    ///Try to cache the house detail response
                    do {
                        let cache = try Cache<NSData>(name: BrowserHouseDetailCache.cacheName)
                        let cachedData = NSKeyedArchiver.archivedDataWithRootObject(result)
                        cache.setObject(cachedData, forKey: houseItem.id, expires: CacheExpiry.Seconds(BrowserHouseDetailCache.cacheTime))

                    } catch _ {
                        Log.debug("Something went wrong with the cache")
                    }
                }

                self.handleHouseDetailResponse(result)
            }

        }
    }

    private func handleHouseDetailResponse(result: AnyObject?) {

        self.houseItemDetail = result

        self.delegate?.onSourcePageLoaded?(true)

        if let sourceLink =
            (self.houseItemDetail?.valueForKey("mobile_link") as? String) ?? (self.houseItem?.mobileLink) {

            self.toggleNavigationBarItems()

            self.runOnMainThreadAfter(1.5, block: {

                self.displayWebView()
                self.startLoad(sourceLink)

            })

        } else {

            self.alertItemNotFound()

        }
    }

    private func alertMailAppNotReady() {

        let alertView = SCLAlertView()

        let subTitle = "找不到預設的郵件應用，請到 [設定] > [郵件、聯絡資訊、行事曆] > 帳號，確認您的郵件帳號已經設置完成"

        alertView.showCloseButton = true

        alertView.showInfo("找不到預設的郵件應用", subTitle: subTitle, closeButtonTitle: "知道了", colorStyle: 0xFFB6C1, colorTextButton: 0xFFFFFF)
    }

    private func displayPhoneNumberMenu() {

        var message = "確認聯絡: "
        let maxDisplayChars = 15

        if let houseItemDetail = self.houseItemDetail {

            if let contactName = houseItemDetail.valueForKey("agent") as? String {

                let toIndex: String.Index = contactName.startIndex
                    .advancedBy(maxDisplayChars, limit: contactName.endIndex)

                if(maxDisplayChars < contactName.characters.count) {
                    message += contactName.substringToIndex(toIndex) + "..."
                } else {
                    message += contactName.substringToIndex(toIndex)
                }

                if let agentType = houseItemDetail.valueForKey("agent_type") as? Int {
                    let agentTypeStr = houseTypeLabelMaker.fromCodeForField("agent_type", code: agentType, defaultValue: "—")
                    message += " (\(agentTypeStr))"
                }

            }


            let optionMenu = UIAlertController(title: nil, message: message, preferredStyle: .ActionSheet)

            if let phoneNumbers = houseItemDetail.valueForKey("phone") as? [String] {
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

    }

    private func initNavigationBarItems() {
        if(enableToolBar) {
            ///Prepare custom UIButton for UIBarButtonItem
            let copyLinkButton: UIButton = UIButton(type: UIButtonType.Custom)
            copyLinkButton.setImage(UIImage(named: "copy_link")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            copyLinkButton.addTarget(self, action: #selector(BrowserViewController.copyLinkButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            copyLinkButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            copyLinkButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

            pesudoAnchor.customView = copyLinkButton
            pesudoAnchor.tintColor = UIColor.whiteColor()
            pesudoAnchor.enabled = false

            /// Phone
            let phoneCallButton: UIButton = UIButton(type: UIButtonType.Custom)
            phoneCallButton.setImage(UIImage(named: "phone_n")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            phoneCallButton.addTarget(self, action: #selector(BrowserViewController.contactByPhoneButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            phoneCallButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

            self.phoneCallBarButton = UIBarButtonItem(customView: phoneCallButton)
            self.phoneCallBarButton!.tintColor = UIColor.whiteColor()
            self.phoneCallBarButton!.enabled = false

            /// Mail
            let sendMailButton: UIButton = UIButton(type: UIButtonType.Custom)
            sendMailButton.setImage(UIImage(named: "envelope_n")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            sendMailButton.addTarget(self, action: #selector(BrowserViewController.contactByMailButtonTouched(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            sendMailButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

            self.sendMailBarButton = UIBarButtonItem(customView: sendMailButton)
            self.sendMailBarButton!.tintColor = UIColor.whiteColor()
            self.sendMailBarButton!.enabled = false

            var barItems: [UIBarButtonItem] = [UIBarButtonItem]()

            barItems.append(pesudoAnchor)

            if let source = self.houseItem?.source {
                let displayConfig = TagUtils.getItemDisplayConfig(source)

                if(displayConfig.displayContact) {
                    barItems.append(sendMailBarButton!)
                    barItems.append(phoneCallBarButton!)
                }
            }


            /// From right to left
            self.navigationItem.setRightBarButtonItems( barItems, animated: false)
        }
    }

    private func toggleNavigationBarItems() {

        if let _ = self.houseItemDetail?.valueForKey("mobile_link") as? String {
            pesudoAnchor.enabled = true
        }

        if let _ = self.houseItemDetail?.valueForKey("phone") as? [String] {
            phoneCallBarButton?.enabled = true
        }

        if let _ = self.houseItemDetail?.valueForKey("email") as? String {
            sendMailBarButton?.enabled = true
        }
    }

    private func setupWebView() {

        self.webView?.addObserver(self, forKeyPath:"title", options:.New, context:nil)
        self.webView?.UIDelegate = self
        self.webView?.navigationDelegate = self

    }

    private func displayWebView() {

        if let webView = self.webView {
            view.addSubview(webView)

            webView.translatesAutoresizingMaskIntoConstraints = false
            let height = NSLayoutConstraint(item: webView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
            let width = NSLayoutConstraint(item: webView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
            view.addConstraints([height, width])
        }

    }

    private func startLoad(sourceLink: String) {

        if let url = NSURL(string:sourceLink) {

            let request = NSMutableURLRequest(URL:url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)

            if(self.houseItem?.source == CriteriaConst.Source.TYPE_591) {
                request.setValue("https://m.591.com.tw/mobile-list.html?type=rent'", forHTTPHeaderField: "Referer")
            }

            if let webView = self.webView {
                webView.loadRequest(request)
            }
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

            if let houseItemDetail = self.houseItemDetail {

                if let email = houseItemDetail.valueForKey("email") as? String {

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
    }

    deinit {
        self.webView?.removeObserver(self, forKeyPath: "title", context: nil)
        self.webView?.stopLoading()
        self.webView?.UIDelegate = nil
        self.webView?.navigationDelegate = nil
        self.webView?.removeFromSuperview()
        self.webView = nil
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

        self.setupWebView()

        self.title = viewTitle
    }

    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {

            //            self.webView?.stopLoading()
            //            self.webView?.UIDelegate = nil
            //            self.webView?.navigationDelegate = nil
            //            self.webView?.removeFromSuperview()
            //            self.webView = nil

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.initNavigationBarItems()

        self.toggleNavigationBarItems()

        self.configureAutoScaleNavigationTitle(16)

        if let sourceLink = self.sourceLink {

            self.displayWebView()
            self.startLoad(sourceLink)

        } else {

            self.configureExternalSiteMessage()

            ///Get remote data
            if let houseItem = self.houseItem {

                self.fetchHouseDetail(houseItem)

            }
        }
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        ///Google Analytics Tracker
        self.trackScreenWithTitle("View: \(self.viewTitle ?? "BrowserView")")
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

                    urlVc.urlLabelText = self.sourceLink ?? (self.houseItemDetail?.valueForKey("mobile_link") as? String)
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

        ///GA Tracker
        self.trackEventForCurrentScreen(GAConst.Catrgory.UIActivity,
                                        action: GAConst.Action.UIActivity.LoadItemPageAlert,
                                        label: message)
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
