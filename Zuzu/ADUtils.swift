//
//  ADConstants.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2016/4/1.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import GoogleMobileAds
import FBAudienceNetwork

private let Log = Logger.defaultLogger

class ADFactory : NSObject {
    
    //Share Instance
    class var sharedInstance: ADFactory {
        struct Singleton {
            static let instance = ADFactory()
        }
        
        return Singleton.instance
    }
    
    private let houseDetailBanner: GADBannerView = GADBannerView()
    
    private let houseDetailVideoAD: VAAdView = VAAdView()
    
    private let searchResultBanner: GADBannerView = GADBannerView()
    
    static let testDevice = ["cca2dd7bf0e491df7d78b7ba80c8d113","a78e7dfcf98d255d2c1d107bb5e96449", "11e6a9c7dd478e63f94ba9ab64bed6ff", "a02fc8fda29b27cfd4a45d741fe728a7", "6889c4bd976a58bd447f1e7eab997323"]
    
    static let fbTestDevice = ["0d5e4441357c49679cace1707412a6b516d3bb36", "9a44f4d536f52e37ba572e672e81ba0b9eb5bdd6", "4c0f7234ac32176ccd83ffb8dbd03a54cce8f9ce"]
    
    override init() {
        
        #if DEBUG
            //Test adUnit
            searchResultBanner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            houseDetailBanner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            
            houseDetailVideoAD.placement = "VMFiveAdNetwork_CardSample"
            houseDetailVideoAD.adType = kVAAdTypeVideoCard
            houseDetailVideoAD.testMode = true
            houseDetailVideoAD.apiKey = "YOUR API KEY HERE"

        #else
            //Real adUnit
            searchResultBanner.adUnitID = "ca-app-pub-7083975197863528/2369456093"
            houseDetailBanner.adUnitID = "ca-app-pub-7083975197863528/3785388890"
        #endif
        
        FBAdSettings.addTestDevices(ADFactory.fbTestDevice)
    }
    
    func getSearchResultBanner() -> GADBannerView {
        
        return searchResultBanner
        
    }
    
    func getHouseDetailBanner() -> GADBannerView {
        
        return houseDetailBanner
        
    }
    
    func getHouseDetailVideoAD() -> VAAdView {
        
        return houseDetailVideoAD
        
    }
}

