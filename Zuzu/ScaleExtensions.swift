//
//  ScaleExtensions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import Device

private let Log = Logger.defaultLogger

/// Definitions of all layout diementions for the base setting (iPhone 6)
struct BaseLayoutConst {
    static let houseImageHeight:CGFloat = 174
}

/// Definitions of the scale ratio for devices with larger or smaller screens
struct ScaleConst {
    static let smallScale:CGFloat = Device.ScreenSize.iPhone5.width / Device.ScreenSize.iPhone6.width
    static let largeScale:CGFloat = Device.ScreenSize.iPhone6P.width / Device.ScreenSize.iPhone6.width
}

internal func getCurrentScale() -> CGFloat{
    
    var scale:CGFloat = 1.0
    
    switch Device.version() {
        
    case .iPhone4, .iPhone4S, .iPhone5, .iPhone5C, .iPhone5S:
        scale = ScaleConst.smallScale
    case .iPhone6, .iPhone6S:
        break
    case .iPhone6Plus, .iPhone6SPlus:
        scale = ScaleConst.largeScale
    case .Simulator:
        Log.debug("It's an simulator")
        
        switch(Device.size()) {
        case .Screen5_5Inch:
            scale = ScaleConst.largeScale
        case .Screen4_7Inch:
            break
        case .Screen4Inch, .Screen3_5Inch:
            scale = ScaleConst.smallScale
        default: break
        }
        
    default:
        Log.debug("It's an unknown device")
    }
    
    return scale
    
}

private func getScaledFontSize(baseFont: UIFont) -> CGFloat{
    
    let baseSize: CGFloat = CGFloat(baseFont.pointSize)
    var scaledSize:CGFloat = baseSize
    
    let scale:CGFloat = getCurrentScale()
    
    scaledSize = round(baseSize * scale)
    
    Log.verbose("base = \(baseSize), scale = \(scale), scaledSize = \(scaledSize)")
    
    return scaledSize
    
}

extension UIView {
    var autoScaleRadious: Bool {
        set {
            let baseSize:CGFloat = self.layer.cornerRadius
            var scale:CGFloat = 1.0
            var scaledSize:CGFloat = baseSize
            
            scale = getCurrentScale()
            
            scaledSize = round(baseSize * scale)
            
            self.layer.cornerRadius = scaledSize
            
        }
        
        get{
            return false
        }
    }
}

extension UIButton {
    var autoScaleFontSize: Bool {
        set {
            if newValue {
                
                if let baseFont = self.titleLabel?.font {
                    let scaledSize = getScaledFontSize(baseFont)
                    if let originalFont = self.titleLabel?.font {
                        self.titleLabel?.font = originalFont.fontWithSize(scaledSize)
                    } else {
                        self.titleLabel?.font = UIFont.systemFontOfSize(scaledSize)
                    }
                }
            }
        }
        
        get {
            return false
        }
    }
}

extension UILabel {
    var autoScaleFontSize: Bool {
        set {
            if newValue {
                
                if let baseFont = self.font {
                    let scaledSize = getScaledFontSize(baseFont)
                    
                    self.font = baseFont.fontWithSize(scaledSize)
                }
            }
        }
        
        get {
            return false
        }
    }
}

extension UINavigationBar {
    
    var autoScaleFontSize: Bool {
        set {
            if newValue {
                
                if let attributes = self.titleTextAttributes {
                    
                    if let baseFont = attributes[NSFontAttributeName] as? UIFont {
                        
                        let scaledSize = getScaledFontSize(baseFont)
                        
                        self.titleTextAttributes![NSFontAttributeName] = UIFont.systemFontOfSize(scaledSize)
                        
                    }
                }
            }
        }
        
        get {
            return false
        }
    }
    
}

extension Device {
    struct ScreenSize {
        static let iPhone5 = CGSize(width: 320, height: 568)
        static let iPhone6 = CGSize(width: 375, height: 667)
        static let iPhone6P = CGSize(width: 414, height: 736)
    }
}