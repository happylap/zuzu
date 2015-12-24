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
    private var dimBackground = false
    private var immediateAppear = false
    private var text:String?
    
    class var shared: LoadingSpinner {
        struct Static {
            static let instance = LoadingSpinner()
        }
        return Static.instance
    }
    
    public func setDimBackground(status:Bool) {
        dimBackground = status
    }
    
    public func setImmediateAppear(status:Bool) {
        immediateAppear = status
    }
    
    public func setOpacity(opacity:Float) {
        self.opacity = opacity
    }
    
    public func setText(text:String) {
        self.text = text
    }
    
    public func startOnView(view: UIView) {
        
        dialog = MBProgressHUD(view: view)
        
        if let dialog = dialog {
            dialog.removeFromSuperViewOnHide = true
            dialog.dimBackground = dimBackground
            dialog.opacity = opacity
            dialog.animationType = .Fade
            dialog.taskInProgress = true
            
            if let text = self.text {
                dialog.labelText = text
            }
            
            if(immediateAppear) {
                dialog.graceTime = 0
            } else {
                dialog.graceTime = LoadingSpinner.defaultGraceTime
            }
            view.addSubview(dialog)
            dialog.show(true)
        }
    }
    
    public func stop() {
        if let dialog = dialog {
            dialog.taskInProgress = false
            dialog.hide(true)
        }
        
        resetParams()
    }
    
    private func resetParams() {
        text = nil
        dimBackground = false
        immediateAppear = false
        opacity = LoadingSpinner.defaultOpacity
    }
}