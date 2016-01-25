//
//  UIOverlayImageView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

private let Log = Logger.defaultLogger

class UIOverlayImageView: UIImageView {
    
    let titleBackground = CAGradientLayer()
    let infoBackground = CALayer()
    
    internal func addImageOverlay() {
        
        if let sublayers = layer.sublayers {
            if (sublayers.contains(infoBackground) && sublayers.contains(infoBackground)) {
                Log.verbose("addImageOverlay: overlays already exist")
                return
            }
        }
        
        ///Title Gradient Layer
        let gradientColors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        let gradientLocations = [0.0, 1.0] //Evenly distributed
        
        let titleRect = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y, width: self.bounds.width, height: self.bounds.width * 220/1441)
        
        Log.verbose("addImageOverlay: titleRect = \(titleRect)")
        
        titleBackground.frame = titleRect
        titleBackground.colors = gradientColors
        titleBackground.locations = gradientLocations
        titleBackground.opacity = 0.7
        
        self.layer.addSublayer(titleBackground)
        
        
        ///Bottom Info Layer
        let infoHeight = self.bounds.width * (220/1441)
        let newOrigin = CGPoint(x: self.bounds.origin.x,
            y: self.bounds.origin.y + self.bounds.height - infoHeight)
        
        let infoRect = CGRect(origin: newOrigin,
            size: CGSize(width: self.bounds.width, height: infoHeight))

        Log.verbose("addImageOverlay: infoRect = \(infoRect)")
        
        infoBackground.frame = infoRect
        infoBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor
        
        self.layer.addSublayer(infoBackground)
        
    }
    
    /// We can get the correct dimension after "auto layout" calculation in the layoutSubviews() method of UIView
    override func layoutSubviews() {
        super.layoutSubviews()
        
        addImageOverlay()
        
    }
    
}
