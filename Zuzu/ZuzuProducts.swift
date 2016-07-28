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

    public static let ProductRadar60 = Prefix + "radar5"

    public static let ProductRadarFreeTrial1 = Prefix + "radarfree1"

    public static let ProductRadarFreeTrial2 = Prefix + "radarfree2"

    // Free Trial Product
    public static let TrialProduct15 = ZuzuProduct(productIdentifier: ProductRadarFreeTrial1,
                                                 localizedTitle: "15天租屋雷達服務禮包",
                                                 localizedDescription: "免費，兌換期限：2016-06-30",
                                                 price: 0.0,
                                                 priceLocale: NSLocale.currentLocale())

    public static let TrialProduct5 = ZuzuProduct(productIdentifier: ProductRadarFreeTrial2,
                                                  localizedTitle: "7天租屋雷達服務試用包",
                                                  localizedDescription: "免費",
                                                  price: 0.0,
                                                  priceLocale: NSLocale.currentLocale())


    public static let FreeTrialExpiry = CommonUtils.getCustomDateFromString("2016-06-30T16:00:00Z")

    // Free Trial Product
    public static var TrialProduct: ZuzuProduct {

        if let expiryDate = ZuzuProducts.FreeTrialExpiry {

            /// Before 2016/06/30
            if(expiryDate.timeIntervalSinceNow >= 0) {

                return TrialProduct15

            } else {

                return TrialProduct5
            }

        } else {

            return TrialProduct5

        }

    }

    // Free trial products
    //public static let freeTrialProducts: [ProductIdentifier: ZuzuProduct] = [ProductRadarFreeTrial:TrialProduct]

    // All of the products assembled into a set of product identifiers.
    public static let productIdentifiers: Set<ProductIdentifier> =
        [ZuzuProducts.ProductRadar10, ZuzuProducts.ProductRadar30,
         ZuzuProducts.ProductRadar45, ZuzuProducts.ProductRadar60]

    /// Return the resourcename for the product identifier.
    internal static func resourceNameForProductIdentifier(productIdentifier: String) -> String? {
        return productIdentifier.componentsSeparatedByString(".").last
    }
}
