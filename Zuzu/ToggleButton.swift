//
//  ToggleButton.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/24.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

protocol ToggleStateListenr {

    func onStateChanged(sender: AnyObject, state: Bool)
    
}

class ToggleButton: UIButton {
    private var listeners: [ToggleStateListenr] = [ToggleStateListenr]()
    private var toggleState: Bool = false {
        didSet {
            switch toggleState {
            case true:
                toggleOn()
            case false:
                toggleOff()
            }
            
            for listener in self.listeners {
                listener.onStateChanged(self, state: toggleState)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.toggleOff()
    }
    
    private func toggleOn() {
        let color = UIColor(red: 0x00/255, green: 0x72/255, blue: 0xE3/255, alpha: 1)
        
        self.layer.borderWidth = 2
        self.layer.borderColor = color.CGColor
        self.tintColor = color
    }
    
    private func toggleOff() {
        let color = UIColor(red: 0xE0/255, green: 0xE0/255, blue: 0xE0/255, alpha: 0.8)
        
        self.layer.borderWidth = 2
        self.layer.borderColor = color.CGColor
        self.tintColor = color
    }
    
    func getToggleState() -> Bool {
        return self.toggleState
    }
    
    func setToggleState(state: Bool) {
        self.toggleState = state
    }
    
    func toggleButtonState() {
        self.toggleState = !self.toggleState
        
    }
    
    func addStateListener(listener: ToggleStateListenr) {
        self.listeners.append(listener)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
