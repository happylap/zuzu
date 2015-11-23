//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import WebKit
import MBProgressHUD

class BrowserViewController: UIViewController {
    
    var sourceLink: String?
    
    struct ViewTransConst {
        static let displayHouseUrl:String = "displayHouseUrl"
    }
    
    @IBOutlet var pesudoAnchor: UIBarButtonItem!
    var webView: WKWebView?
    
    private func configureNavigationBarItems() {
        
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
    
    func copyLinkButtonTouched(sender:UIButton) {
        performSegueWithIdentifier(ViewTransConst.displayHouseUrl, sender: self)
    }
    
    override func loadView() {
        super.loadView()
        
        self.webView = WKWebView(frame: CGRectZero)
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@", identifier)
            
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
        
        let dialog = MBProgressHUD.showHUDAddedTo(view, animated: true)
        
        if let image = UIImage(named: "checked_green"){
            dialog.mode = .CustomView
            dialog.customView = UIImageView(image: image)
        }
        dialog.animationType = .ZoomIn
        dialog.dimBackground = true
        dialog.labelText = "已複製"
        
        self.runOnMainThreadAfter(1) { () -> Void in
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        }
    }
    
}

extension BrowserViewController: WKNavigationDelegate {
    
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