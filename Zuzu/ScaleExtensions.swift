//
//  ScaleExtensions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import Device

extension UIButton {
    var autoScaleRadious: Bool {
        set {
            let baseSize:CGFloat = self.layer.cornerRadius
            var scale:CGFloat = 1.0
            var scaledSize:CGFloat = baseSize
            
            switch Device.version() {
                /*** iPhone ***/
            case .iPhone4, .iPhone4S, .iPhone5, .iPhone5C, .iPhone5S:
                print("It's an iPhone 4/5")
                scale =
                    Device.ScreenSize.iPhone5.width / Device.ScreenSize.iPhone6.width
                scaledSize = floor(baseSize * scale)
            case .iPhone6, .iPhone6S:
                print("It's an iPhone 6/6S")
            case .iPhone6Plus, .iPhone6SPlus:
                print("It's an iPhone 6/6S Plus")
                scale =
                    Device.ScreenSize.iPhone6P.width / Device.ScreenSize.iPhone6.width
                scaledSize = ceil(baseSize * scale)
                /*** Simulator ***/
            case .Simulator:
                print("It's an  simulator")
                /*** Unknown ***/
            default:
                print("It's an unknown device")
            }
            
            print("UIButton \(self), scale = \(scale), scaledSize = \(scaledSize)")

            self.layer.cornerRadius = scaledSize
            
        }
        
        get{
            return false
        }
    }
}

extension UILabel {
    var autoScaleFontSize: Bool {
        set {
            if newValue {
                
                let baseSize: CGFloat = CGFloat(self.font.pointSize)
                var scale:CGFloat = 1.0
                var scaledSize:CGFloat = baseSize
                
                switch Device.version() {
                    /*** iPhone ***/
                case .iPhone4, .iPhone4S, .iPhone5, .iPhone5C, .iPhone5S:
                    print("It's an iPhone 4/5")
                    scale =
                        Device.ScreenSize.iPhone5.width / Device.ScreenSize.iPhone6.width
                    scaledSize = floor(baseSize * scale)
                case .iPhone6, .iPhone6S:
                    print("It's an iPhone 6/6S")
                case .iPhone6Plus, .iPhone6SPlus:
                    print("It's an iPhone 6/6S Plus")
                    scale =
                        Device.ScreenSize.iPhone6P.width / Device.ScreenSize.iPhone6.width
                    scaledSize = ceil(baseSize * scale)
                    /*** Simulator ***/
                case .Simulator:
                    print("It's an  simulator")
                    /*** Unknown ***/
                default:
                    print("It's an unknown device")
                }
                
                print("UILabel \(self), base = \(baseSize), scale = \(scale), scaledSize = \(scaledSize)")
                
                self.font = UIFont.systemFontOfSize(scaledSize)
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