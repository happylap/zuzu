//
//  LoadingSpinner.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import MBProgressHUD

public class LoadingSpinner{
    
    var dialog : MBProgressHUD?
    private static let defaultGraceTime:Float = 0.6
    private static let defaultOpacity:Float = 0.3
    
    private var opacity = LoadingSpinner.defaultOpacity
    private var minShowTime:Float?
    private var graceTime:Float?
    private var dimBackground = false
    private var immediateAppear = false
    private var text:String?
    private var animationType: MBProgressHUDAnimation = .Fade
    private var mode: MBProgressHUDMode?
    private var customView: UIView?
    
    
    class var shared: LoadingSpinner {
        struct Static {
            static let instance = LoadingSpinner()
        }
        return Static.instance
    }
    
    public func setDimBackground(status:Bool) {
        self.dimBackground = status
    }
    
    public func setImmediateAppear(status:Bool) {
        self.immediateAppear = status
    }
    
    public func setOpacity(opacity:Float) {
        self.opacity = opacity
    }
    
    public func setMinShowTime(second:Float) {
        self.minShowTime = second
    }
    
    public func setGraceTime(second:Float) {
        self.graceTime = second
    }
    
    public func setCustomView(view: UIView) {
        self.mode = .CustomView
        self.customView = view
    }
    
    public func setText(text:String) {
        self.mode = .Text
        self.text = text
    }
    
    public func updateText(text:String) {
        self.dialog?.labelText = text
    }
    
    
    public func startOnView(view: UIView, animated: Bool = true) {
        
        self.dialog = MBProgressHUD(view: view)
        
        if let dialog = dialog {
            dialog.square = true
            dialog.removeFromSuperViewOnHide = true
            dialog.dimBackground = self.dimBackground
            dialog.opacity = self.opacity
            dialog.animationType = self.animationType
            dialog.taskInProgress = true
            
            if let mode = mode {
                dialog.mode = mode
            }
            
            if let minShowTime = self.minShowTime {
                dialog.minShowTime = minShowTime
            }
            
            if let customView = self.customView {
                dialog.customView = customView
            }
            
            if let text = self.text {
                dialog.labelFont = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
                dialog.labelText = text
            }
            
            if(immediateAppear) {
                dialog.graceTime = 0
            } else {
                if let graceTime = self.graceTime {
                    dialog.graceTime = graceTime
                } else {
                    dialog.graceTime = LoadingSpinner.defaultGraceTime
                }
            }
            view.addSubview(dialog)
            
            dialog.show(animated)
        }
    }
    
    public func stop(animated: Bool = true, afterDelay: NSTimeInterval = 0) {
        if let dialog = dialog {
            dialog.taskInProgress = false
            
            if(afterDelay > 0) {
                dialog.hide(animated, afterDelay: afterDelay)
            } else {
                dialog.hide(animated)
            }
            
        }
        
        resetParams()
    }
    
    private func resetParams() {
        self.text = nil
        self.dimBackground = false
        self.immediateAppear = false
        self.opacity = LoadingSpinner.defaultOpacity
        self.minShowTime = nil
        self.graceTime = nil
        self.customView = nil
        self.mode = nil
    }
}