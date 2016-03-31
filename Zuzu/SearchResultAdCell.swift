//
//  SearchResultAdCell.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//
import Alamofire
import AlamofireImage
import UIKit
import Foundation
import Dollar
import GoogleMobileAds
import FBAudienceNetwork

private let Log = Logger.defaultLogger

class SearchResultAdCell: UITableViewCell {
    
    private var parentBound: CGRect?
    
    private let testDevice = ["cca2dd7bf0e491df7d78b7ba80c8d113","a78e7dfcf98d255d2c1d107bb5e96449", "11e6a9c7dd478e63f94ba9ab64bed6ff", "a02fc8fda29b27cfd4a45d741fe728a7", "6889c4bd976a58bd447f1e7eab997323"]
    
    private let fbTestDevice = ["0d5e4441357c49679cace1707412a6b516d3bb36", "9a44f4d536f52e37ba572e672e81ba0b9eb5bdd6", "4c0f7234ac32176ccd83ffb8dbd03a54cce8f9ce"]
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    private func loadAdForController() {
        
        Log.error("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        
        let request = GADRequest()
        request.testDevices = self.testDevice
        
        self.bannerView.loadRequest(request)
    }
    
    func setupBanner(controller: SearchResultViewController) {
        
        Log.enter()
        
        if(self.bannerView.rootViewController == nil) {
            self.bannerView.rootViewController = controller
            self.bannerView.delegate = self
            
            FBAdSettings.addTestDevices(fbTestDevice)
            
            #if DEBUG
                //Test adUnit
                self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            #else
                //Real adUnit
                self.bannerView.adUnitID = "ca-app-pub-7083975197863528/2369456093"
            #endif
        }
    }
    
    func loadBanner() {
        
        Log.enter()
        
        if let _ = self.bannerView.rootViewController {
            self.loadAdForController()
        }
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if(self.parentBound == nil) {
            
            self.parentBound = self.contentView.bounds
            
            if let parentBound = self.parentBound {
                Log.debug("Cell Size = \(parentBound.size)")
                
                /// Note: We encountered a bug in smart banner
                /// The banner will get shorter and shorter for each time it's loaded,
                /// and we need to round the height to avoid this strange phenomenon
                let width = round(parentBound.size.width)
                let height = round(parentBound.size.height)
                
                self.bannerView.adSize = GADAdSizeFromCGSize(CGSize(width: width, height: height))
            }
        }
    }
    
    // MARK: - Inherited Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        Log.enter()
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    
}

// MARK: - GADBannerViewDelegate
extension SearchResultAdCell: GADBannerViewDelegate {
    
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
