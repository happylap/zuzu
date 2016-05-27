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
    
    private var bannerView: GADBannerView?

    private func loadAdForController() {
        
        Log.error("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        
        let request = GADRequest()
        request.testDevices = ADFactory.testDevice
        
        self.bannerView?.loadRequest(request)
    }
    
    var isAdBannerSupported: Bool {
        get {
            return adBannerContainer != nil
        }
    }
    
    var isAdBannerEnabled: Bool {
        get {
            return bannerView != nil
        }
    }
    
    internal func setAdBanner(rootViewController: UIViewController) {

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
    
    internal func loadBanner() {
        
        Log.enter()
        
        if let _  = self.bannerView?.rootViewController {
            self.loadAdForController()
        }
    }
    
    override func prepareForReuse() {
        bannerView = nil
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

