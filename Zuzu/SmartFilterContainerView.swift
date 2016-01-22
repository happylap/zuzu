//
//  SmartFilterView.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

private let Log = Logger.defaultLogger

class SmartFilterContainerView: UIView {
    
    enum PanelState:Int {
        case Expanded
        case Folded
    }
    
    var panelState:PanelState = .Folded
    let numOfPage = 2
    let controlTopBorderHeight:CGFloat = 30
    let heightToWidthRatio:CGFloat = 384/1500
    let controlButtonView = UIView()
    let upImage = UIImage(named: "arrow_up_n")
    let downImage = UIImage(named: "arrow_down_n")
    
    var controlButtonImage = UIImageView()
    
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
        Log.debug("layoutSubviews")
        
        if let superView = self.superview {
            
            /// Adjust View Position
            let parentRect = superView.bounds
            let width = parentRect.size.width
            let height = parentRect.size.width * heightToWidthRatio
            let yOffset = height / 2 + controlTopBorderHeight
            let y = parentRect.size.height - yOffset //+ controlTopBorderHeight
            
            self.frame = CGRect(x: 0, y: y, width: width, height: height + controlTopBorderHeight)
            
            Log.debug("SmartFilterContainerView Frame = \(self.frame)")
            
            /// Add SmartFilterViews
            positionSmartFilterViews()
            
            /// Load Control Button
            loadControlButton()
        }
    }
    
    private func handleExpanding() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.TransitionCurlUp, animations: {
            
            var smartFilterContainerFrame = self.frame
            
            let moveUp = (smartFilterContainerFrame.size.height - self.controlTopBorderHeight) / 2
            
            smartFilterContainerFrame.origin.y -= moveUp
            
            self.frame = smartFilterContainerFrame
            
            }, completion: { finished in
                
            }
        )
    }
    
    private func handleFolding() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.TransitionCurlDown, animations: {
            
            var smartFilterContainerFrame = self.frame
            
            let moveDown = (smartFilterContainerFrame.size.height - self.controlTopBorderHeight) / 2
            
            smartFilterContainerFrame.origin.y += moveDown
            
            self.frame = smartFilterContainerFrame
            
            }, completion: { finished in
                
            }
        )
    }
    
    func onSmartFilterControlButtonTouched(sender: UITapGestureRecognizer) {

        switch(self.panelState) {
        case .Expanded:
            handleFolding()
            controlButtonImage.image = upImage
            self.panelState = .Folded
        case .Folded:
            handleExpanding()
            controlButtonImage.image = downImage
            self.panelState = .Expanded
        }
        
    }
    
    private func loadControlButton() {
        
        let controlWidth:CGFloat = 60
        let visibleRect = self.bounds
        let contentWidth = visibleRect.size.width
        let x = (contentWidth - controlWidth) / 2
        
        controlButtonView.frame = CGRect(x: x, y: 13, width: controlWidth, height: 20)
        //controlButtonView.clipsToBounds = true
        controlButtonView.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 0.8)
        controlButtonView.layer.cornerRadius = 5
        
        self.addSubview(controlButtonView)
        
        
        switch(self.panelState) {
        case .Expanded:
            controlButtonImage.image = downImage
        case .Folded:
            controlButtonImage.image = upImage
        }
        
        controlButtonImage.frame = CGRect(x: 0, y: 0, width: 20, height: 10)
        controlButtonImage.center = self.convertPoint(controlButtonView.center, toView: controlButtonView)
        //controlButtonImage.center.y -= 2
        self.controlButtonView.addSubview(controlButtonImage)
    }
    
    private func positionSmartFilterViews() {
        
        let visibleRect = self.bounds
        let contentWidth = visibleRect.size.width
        let contentHeight = (visibleRect.size.height - controlTopBorderHeight) / CGFloat(numOfPage)
        let x = visibleRect.origin.x
        let y = visibleRect.origin.y
        
        
        let smartFilterViews = self.subviews.filter { (view) -> Bool in
            return (view as? SmartFilterView) != nil
        }
        
        for subView in smartFilterViews {
            if let smartFilterView = subView as? SmartFilterView {
                
                let page = smartFilterView.filterPage
                let smartFilterFrame = CGRect(x: x, y: y + CGFloat(page - 1) * contentHeight + controlTopBorderHeight, width: contentWidth, height: contentHeight)
                smartFilterView.frame = smartFilterFrame
            }
        }
        
    }
    
    private func setup() {
        self.backgroundColor = UIColor.clearColor()
        
        self.controlButtonView.clipsToBounds = false
        self.controlButtonView.userInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(target: self, action: "onSmartFilterControlButtonTouched:")
        self.controlButtonView.addGestureRecognizer(tapGuesture)
        self.addGestureRecognizer(tapGuesture)
        
        /// Setup SmartFilterViews
        for page in (1...numOfPage) {
            let smartFilterFrame = self.bounds
            
            let smartFilterView = SmartFilterView(frame: smartFilterFrame, page: page)
            self.addSubview(smartFilterView)
        }
    }
}
