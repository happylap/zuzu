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
    private var dimBackground = false
    
    class var shared: LoadingSpinner {
        struct Static {
            static let instance = LoadingSpinner()
        }
        return Static.instance
    }
    
    public func setDimBackground(status:Bool) {
        dimBackground = status
    }
    
    public func startOnView(view: UIView) {
        
        dialog = MBProgressHUD(view: view)
        
        if let dialog = dialog {
            dialog.removeFromSuperViewOnHide = true
            dialog.dimBackground = dimBackground
            dialog.opacity = 0.3
            dialog.animationType = .Fade
            dialog.taskInProgress = true
            dialog.graceTime = 0.2
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
        dimBackground = false
    }
}