//
//  BrowserViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import Foundation

// Use enum as a simple namespace.  (It has no cases so you can't instantiate it.)
public enum ZuzuProducts {
    
    /// TODO:  Change this to whatever you set on iTunes connect
    private static let Prefix = "com.lap.zuzurentals."
    
    /// MARK: - Supported Product Identifiers
    public static let ProductRadar = Prefix + "radar"
    
    // All of the products assembled into a set of product identifiers.
    private static let productIdentifiers: Set<ProductIdentifier> = [ZuzuProducts.ProductRadar]
    
    /// Static instance of IAPHelper that for rage products.
    public static let store = IAPHelper(productIdentifiers: ZuzuProducts.productIdentifiers)
}

/// Return the resourcename for the product identifier.
func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
    return productIdentifier.componentsSeparatedByString(".").last
}