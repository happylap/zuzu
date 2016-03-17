//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import WebKit

private let Log = Logger.defaultLogger

class BrowserViewController: UIViewController {
    
    var enableToolBar:Bool = true
    
    var viewTitle:String?
    
    var sourceLink: String?
    
    struct ViewTransConst {
        static let displayHouseUrl:String = "displayHouseUrl"
    }
    
    @IBOutlet var pesudoAnchor: UIBarButtonItem!
    var webView: WKWebView?
    
    private func configureNavigationBarItems() {
        if(enableToolBar) {
            ///Prepare custom UIButton for UIBarButtonItem
            let copyLinkButton: UIButton = UIButton(type: UIButtonType.Custom)
            copyLinkButton.setImage(UIImage(named: "copy_link")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            copyLinkButton.addTarget(self, action: "copyLinkButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
            copyLinkButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            copyLinkButton.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            
            pesudoAnchor.customView = copyLinkButton
            pesudoAnchor.tintColor = UIColor.whiteColor()
            
            /// From right to left
            self.navigationItem.setRightBarButtonItems(
                [
                    pesudoAnchor
                ],
                animated: false)
        }
    }
    
    func copyLinkButtonTouched(sender:UIButton) {
        performSegueWithIdentifier(ViewTransConst.displayHouseUrl, sender: self)
    }
    
    override func loadView() {
        super.loadView()
        
        self.webView = WKWebView(frame: CGRectZero)
        self.title = viewTitle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBarItems()
        
        view.addSubview(self.webView!)
        
        webView!.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView!, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView!, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        if let sourceLink = self.sourceLink {
            if let url = NSURL(string:sourceLink) {
                
                LoadingSpinner.shared.startOnView(view)
                
                self.webView?.UIDelegate = self
                self.webView?.navigationDelegate = self
                let req = NSURLRequest(URL:url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 45)
                self.webView!.loadRequest(req)
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
        if let identifier = segue.identifier{
            
            Log.debug("prepareForSegue: \(identifier)")
            
            switch identifier{
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
    
    func onUrlCopiedDone(status:Bool) {
        LoadingSpinner.shared.setImmediateAppear(true)
        LoadingSpinner.shared.setMinShowTime(1.5)
        LoadingSpinner.shared.setDimBackground(true)
        LoadingSpinner.shared.setOpacity(0.5)
        LoadingSpinner.shared.setText("已複製")
        if let image = UIImage(named: "checked_green"){
            
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
            
            UIApplication.sharedApplication().openURL(targetUrl)
            
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel) { (action) -> Void in
            
        }
        
        alertView.addAction(callAction)
        alertView.addAction(cancelAction)
        
        // Show Alert View
        self.presentViewController(alertView, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if let targetUrl = navigationAction.request.URL {
            
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
            decisionHandler(WKNavigationActionPolicy.Cancel)
        }
    }
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        LoadingSpinner.shared.stop()
    }
    
    //    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    //        LoadingSpinner.shared.stop()
    //    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        LoadingSpinner.shared.stop()
    }
}

extension BrowserViewController: WKUIDelegate {
    
    
}