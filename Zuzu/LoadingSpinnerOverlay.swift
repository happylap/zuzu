//
//  LoadingSpinnerOverlay.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/12.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation


public class LoadingSpinnerOverlay{
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: LoadingSpinnerOverlay {
        struct Static {
            static let instance = LoadingSpinnerOverlay()
        }
        return Static.instance
    }
    
    public func showOverlayOnView(view: UIView) {
        
        overlayView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        overlayView.center = view.center
        overlayView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5)
        overlayView.clipsToBounds = true
        overlayView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator.center = CGPointMake(overlayView.bounds.width / 2, overlayView.bounds.height / 2)
        
        overlayView.addSubview(activityIndicator)
        view.addSubview(overlayView)
        
        activityIndicator.startAnimating()
    }
    
    public func hideOverlayView() {
        activityIndicator.stopAnimating()
        overlayView.removeFromSuperview()
    }
}