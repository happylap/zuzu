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
    public static let ProductRadar1Month = Prefix + "radar1"
    
    public static let ProductRadar2Month = Prefix + "radar2"
    
    public static let ProductRadar3Month = Prefix + "radar3"
    
    public static let ProductRadarFreeTrial = Prefix + "radarfree1"
    
    // All of the products assembled into a set of product identifiers.
    public static let productIdentifiers: Set<ProductIdentifier> =
    [ZuzuProducts.ProductRadarFreeTrial, ZuzuProducts.ProductRadar1Month, ZuzuProducts.ProductRadar2Month, ZuzuProducts.ProductRadar3Month]
    
    /// Return the resourcename for the product identifier.
    internal static func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
        return productIdentifier.componentsSeparatedByString(".").last
    }
}