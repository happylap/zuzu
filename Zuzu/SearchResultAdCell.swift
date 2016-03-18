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

private let Log = Logger.defaultLogger

class SearchResultAdCell: UITableViewCell {
    
    private let testDevice = ["a78e7dfcf98d255d2c1d107bb5e96449", "11e6a9c7dd478e63f94ba9ab64bed6ff", "a02fc8fda29b27cfd4a45d741fe728a7", "6889c4bd976a58bd447f1e7eab997323"]
    
    var bannerView: GADBannerView = GADBannerView()
    
    func loadAdForController(controller: SearchResultViewController) {
        
        // Do any additional setup after loading the view, typically from a nib.
        Log.debug("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        
        dispatch_async(GlobalQueue.UserInteractive) {
            
            let delay = 0.1
            let delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            Log.enter()
            dispatch_after(delayInNanoSeconds, dispatch_get_main_queue()) {
                Log.enter()
                let request = GADRequest()
                request.testDevices = self.testDevice
                self.bannerView.loadRequest(request)
            }
        }
    }
    
    func setupBanner(controller: SearchResultViewController) {
        
        #if DEBUG
            //Test adUnit
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        #else
            //Real adUnit
            bannerView.adUnitID = "ca-app-pub-7083975197863528/3785388890"
        #endif
        
        bannerView.rootViewController = controller
        bannerView.delegate = self
        bannerView.adSize = kGADAdSizeBanner
        
        self.addSubview(bannerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let parentBound = self.contentView.bounds
        bannerView.frame = CGRectMake(0.0, 0.0, 320, 50.0)
        bannerView.center = CGPoint(x: parentBound.width / 2, y: parentBound.height / 2)
    }
    
    // MARK: - Inherited Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        
        Log.debug("prepareForReuse")
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
    }
    
    
}

// MARK: - GADBannerViewDelegate
extension SearchResultAdCell: GADBannerViewDelegate {
    
    internal func adViewDidReceiveAd(bannerView: GADBannerView!) {
        Log.enter()
        Log.debug("Banner adapter class name: \(bannerView.adNetworkClassName)")
    }
    internal func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        Log.enter()
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
