//
//  ViewControllerExtensions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    private func getTrackerInstance() -> GAITracker?{
        
        var tracker:GAITracker?
        
        #if !DEBUG
            tracker = GAI.sharedInstance().defaultTracker
        #endif
        
        
        if let tracker = tracker {
            tracker.allowIDFACollection = true
        }
        
        return tracker
    }
    
    func trackScreenWithTitle(title: String) {
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: title)
            
            let builder = GAIDictionaryBuilder.createScreenView()
            tracker.send(builder.build() as [NSObject : AnyObject])
        }
    }
    
    func trackScreen() {
        let title = "View: \(self.title ?? self.description)"
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: title)
            
            let builder = GAIDictionaryBuilder.createScreenView()
            tracker.send(builder.build() as [NSObject : AnyObject])
        }
    }
    
    /// Track event not associated to a screen
    func trackEvent(category:String, action: String, label: String? = nil, value: NSNumber) {
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: nil)
            
            let eventBuilder = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value)
            
            tracker.send(eventBuilder.build() as [NSObject : AnyObject])
        }
    }
    
    /// Track event associated to the specified screen name
    func trackEventForScreen(screenName: String, category:String, action: String, label: String? = nil, value: NSNumber) {
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            
            tracker.set(kGAIScreenName, value: screenName)
            
            let eventBuilder = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value)
            
            tracker.send(eventBuilder.build() as [NSObject : AnyObject])
        }
    }
    
    /// Track event associated to the current view controller
    func trackEventForCurrentScreen(category:String, action: String, label: String? = nil, value: NSNumber? = nil) {
        let title = "View: \(self.title ?? self.description)"
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: title)
            
            let eventBuilder = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value)
            
            tracker.send(eventBuilder.build() as [NSObject : AnyObject])
        }
    }
    
    /// Track event associated to the current view controller
    func trackTimeForCurrentScreen(category:String, interval: NSNumber, name: String? = nil, label: String? = nil) {
        let title = "View: \(self.title ?? self.description)"
        let tracker = getTrackerInstance()
        
        if let tracker = tracker {
            tracker.set(kGAIScreenName, value: title)
            
            let eventBuilder = GAIDictionaryBuilder.createTimingWithCategory(category, interval: interval, name: name, label: label)
            
            tracker.send(eventBuilder.build() as [NSObject : AnyObject])
        }
    }
}