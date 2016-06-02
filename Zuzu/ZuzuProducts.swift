//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import Foundation

// Define the product for Zuzu In-App Purchase
public struct ZuzuProducts {
    
    private static let Prefix = "com.lap.zuzurentals."
    
    /// MARK: - Supported Product Identifiers
    public static let ProductRadar10 = Prefix + "radar1"
    
    public static let ProductRadar30 = Prefix + "radar2"
    
    public static let ProductRadar45 = Prefix + "radar3"
    
    public static let ProductRadar60 = Prefix + "radar4"
    
    public static let ProductRadarFreeTrial = Prefix + "radarfree1"
    
    // Free Trial Product
    public static let TrialProduct = ZuzuProduct(productIdentifier: ProductRadarFreeTrial,
        localizedTitle: "15天租屋雷達服務禮包",
        localizedDescription: "免費，兌換期限：2016-06-30",
        price: 0.0,
        priceLocale: NSLocale.currentLocale())
    
    public static let FreeTrialExpiry = CommonUtils.getCustomDateFromString("2016-06-30T16:00:00Z")
    
    // Free trial products
    //public static let freeTrialProducts: [ProductIdentifier: ZuzuProduct] = [ProductRadarFreeTrial:TrialProduct]
    
    // All of the products assembled into a set of product identifiers.
    public static let productIdentifiers: Set<ProductIdentifier> =
    [ZuzuProducts.ProductRadarFreeTrial,
     ZuzuProducts.ProductRadar10, ZuzuProducts.ProductRadar30, ZuzuProducts.ProductRadar45, ZuzuProducts.ProductRadar60]
    
    /// Return the resourcename for the product identifier.
    internal static func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
        return productIdentifier.componentsSeparatedByString(".").last
    }
}