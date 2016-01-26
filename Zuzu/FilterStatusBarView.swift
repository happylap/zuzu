//
//  FilterStatusView.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

private let Log = Logger.defaultLogger

class FilterStatusBarView: UIView {
    
    var statusText: UILabel = UILabel()
    
    private let bgColor = UIColor.colorWithRGB(0x66FFCC, alpha: 0.9)
    
    private let statusBarHeight: CGFloat = 30
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    
    ///The correct place to layout subviews (with correct frame & bounds info)
    override func layoutSubviews() {
        Log.verbose("layoutSubviews")
    }
    
    
    private func positionSmartFilterViews() {
        
    }
    
    private func setup() {
        self.backgroundColor = bgColor
        
        /// Adjust View Position
        var parentRect = self.frame
        
        parentRect.size.height = statusBarHeight
        
        self.frame = parentRect
        
        /// Setup Text, Position in the center
        statusText.translatesAutoresizingMaskIntoConstraints = false
        statusText.textAlignment = NSTextAlignment.Center
        statusText.numberOfLines = -1
        statusText.font = UIFont.systemFontOfSize(12)
        statusText.autoScaleFontSize = true
        statusText.textColor = UIColor.grayColor()
        
        self.addSubview(statusText)
        
        let xConstraint = NSLayoutConstraint(item: statusText, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        xConstraint.priority = UILayoutPriorityRequired
        
        let yConstraint = NSLayoutConstraint(item: statusText, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        yConstraint.priority = UILayoutPriorityRequired
        
        let leftConstraint = NSLayoutConstraint(item: statusText, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 8)
        leftConstraint.priority = UILayoutPriorityDefaultLow
        
        let rightConstraint = NSLayoutConstraint(item: statusText, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.TrailingMargin, multiplier: 1.0, constant: -8)
        rightConstraint.priority = UILayoutPriorityDefaultLow
        
        self.addConstraints([xConstraint, yConstraint, leftConstraint, rightConstraint])
    }
    
    func showStatusBarOnView(view: UIView) {
        view.addSubview(self)
    }
    
    func hideStatusBar() {
        //Remove Filter Status Bar
        self.removeFromSuperview()
    }
}
