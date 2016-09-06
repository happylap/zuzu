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

    private var parentBound: CGRect?

    private var bannerView: GADBannerView?

    private func loadAdForController() {

        Log.error("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")

        let request = GADRequest()
        request.testDevices = ADFactory.testDevice

        self.bannerView?.loadRequest(request)
    }

    func setupBanner(controller: SearchResultViewController) {

        Log.enter()

        /// Add bannerView only when it's nil
        if(self.bannerView == nil) {
            Log.debug("Add banner view")

            self.bannerView = ADFactory.sharedInstance.getSearchResultBanner()

            if let bannerView = self.bannerView {
                bannerView.rootViewController = controller
                bannerView.delegate = self
                self.contentView.addSubview(bannerView)
            }
        }
    }

    func loadBanner() {

        Log.enter()

        if let _  = self.bannerView?.rootViewController {
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

                self.bannerView?.adSize = GADAdSizeFromCGSize(CGSize(width: width, height: height))
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
