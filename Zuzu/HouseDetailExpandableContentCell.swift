//
//  HouseDetailExpandableContentCell.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import GoogleMobileAds

private let Log = Logger.defaultLogger

/// The class is shared by two cell prototype
/// .ExpandableContentCell, .ExpandableContentAdCell
/// adBannerContainer exists only for .ExpandableContentAdCell type

class HouseDetailExpandableContentCell: UITableViewCell {
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBOutlet weak var adBannerContainer: UIView!
    
    private weak var rootViewController: UIViewController!
    
    private var bannerView: GADBannerView?
    
    private var videoBannerView: VAAdView?
    
    private func loadAdForController() {
        
        Log.error("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        
        let request = GADRequest()
        request.testDevices = ADFactory.testDevice
        
        self.bannerView?.loadRequest(request)
    }
    
    var isAdSupported: Bool {
        get {
            return adBannerContainer != nil
        }
    }
    
    var isAdBannerEnabled: Bool {
        get {
            return bannerView != nil
        }
    }
    
    var isVideoAdBannerEnabled: Bool {
        get {
            return videoBannerView != nil
        }
    }
    
    internal func setAdBanner(rootViewController: UIViewController) {
        
        self.rootViewController = rootViewController
        
        self.bannerView = ADFactory.sharedInstance.getHouseDetailBanner()
        
        if let bannerView = self.bannerView, adBannerContainer = self.adBannerContainer {
            
            bannerView.rootViewController = rootViewController
            bannerView.delegate = self
            bannerView.adSize = kGADAdSizeMediumRectangle
            
            adBannerContainer.addSubview(bannerView)
            
        } else {
            assert(false, "AD Banner is not supported.")
        }
    }
    
    internal func setVideoAdBanner(rootViewController: UIViewController) {
        
        self.rootViewController = rootViewController
        
        self.videoBannerView = ADFactory.sharedInstance.createHouseDetailVideoAD()
        
        if let videoBannerView = self.videoBannerView, adBannerContainer = self.adBannerContainer {
            
            videoBannerView.delegate = self
            
            adBannerContainer.addSubview(videoBannerView)
            
            videoBannerView.translatesAutoresizingMaskIntoConstraints = false
            
            let height = NSLayoutConstraint(item: videoBannerView, attribute: .Height, relatedBy: .Equal, toItem: adBannerContainer, attribute: .Height, multiplier: 1, constant: 0)
            let width = NSLayoutConstraint(item: videoBannerView, attribute: .Width, relatedBy: .Equal, toItem: adBannerContainer, attribute: .Width, multiplier: 1, constant: 0)
            adBannerContainer.addConstraints([height, width])
            
            adBannerContainer.addConstraint(NSLayoutConstraint(item: videoBannerView, attribute: .CenterX, relatedBy: .Equal, toItem: adBannerContainer, attribute: .CenterX, multiplier: 1.0, constant: 0))
            adBannerContainer.addConstraint(NSLayoutConstraint(item: videoBannerView, attribute: .CenterY, relatedBy: .Equal, toItem: adBannerContainer, attribute: .CenterY, multiplier: 1.0, constant: 0))
            
        } else {
            assert(false, "AD Banner is not supported.")
        }
    }
    
    internal func loadBanner() {
        
        Log.enter()
        
        if let _  = self.bannerView?.rootViewController {
            
            self.loadAdForController()
            
        }
    }
    
    internal func loadVideoBanner() {
        
        Log.enter()
        
        if let videoBannerView  = self.videoBannerView {
            
            videoBannerView.loadAd()
            
        }
    }
    
    override func prepareForReuse() {
        self.bannerView = nil
        self.videoBannerView = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}

// MARK: - GADBannerViewDelegate
extension HouseDetailExpandableContentCell: GADBannerViewDelegate {
    
    internal func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Log.enter()
        Log.error("Banner adapter class name: \(bannerView.adNetworkClassName)")
    }
    internal func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Log.error("\(error)")
    }
    internal func adViewWillPresentScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewDidDismissScreen(bannerView: GADBannerView!) {
        Log.enter()
    }
    internal func adViewWillLeaveApplication(bannerView: GADBannerView!) {
        Log.enter()
    }
}

// MARK: - VAAdViewDelegate
extension HouseDetailExpandableContentCell: VAAdViewDelegate {
    
    func adViewDidLoad(adView: VAAdView) {
        Log.enter()
        Log.error("\(adView.placement)")
    }
    
    func adViewBeImpressed(adView: VAAdView) {
        Log.enter()
        
        ///GA Tracker
        GAUtils.trackEvent(GAConst.Catrgory.DisplayAD, action: GAConst.Action.DisplayAD.Impression, label: GAConst.Label.DisplayAD.Vmfive)
        
        Log.error("\(adView.placement)")
    }
    
    func adView(adView: VAAdView, didFailWithError error: NSError) {
        Log.enter()
        
        ///GA Tracker
        GAUtils.trackEvent(GAConst.Catrgory.DisplayAD, action: GAConst.Action.DisplayAD.Error, label: "\(GAConst.Label.DisplayAD.Vmfive) = \(error)")
        
        Log.error("\(error)")
        
        /// Load other ADs when video AD fails
        self.setAdBanner(self.rootViewController)
        self.loadBanner()
    }
    
    func adViewDidClick(adView: VAAdView) {
        Log.enter()
        
        ///GA Tracker
        GAUtils.trackEvent(GAConst.Catrgory.DisplayAD, action: GAConst.Action.DisplayAD.Click, label: GAConst.Label.DisplayAD.Vmfive)
    }
    
    func adViewDidFinishHandlingClick(adView: VAAdView) {
        Log.enter()
    }
    
    func viewControllerForPresentingModalView() -> UIViewController {
        return self.rootViewController
    }
    
    func shouldAdViewBeReload(adView: VAAdView) -> Bool {
        return true
    }
    
}

