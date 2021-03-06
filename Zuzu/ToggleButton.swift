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
    var onColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
    var onBackgroundColor = UIColor.whiteColor()

    var offColor = UIColor.colorWithRGB(0xE0E0E0, alpha: 0.8)
    var offBackgroundColor = UIColor.whiteColor()

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
        self.setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    private func setup() {
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.toggleOff()
    }

    private func toggleOn() {
        self.backgroundColor = onBackgroundColor
        self.layer.borderColor = onColor.CGColor
        self.tintColor = onColor
        self.setTitleColor(onColor, forState: .Normal)
    }

    private func toggleOff() {
        self.backgroundColor = offBackgroundColor
        self.layer.borderColor = offColor.CGColor
        self.tintColor = offColor
        self.setTitleColor(offColor, forState: .Normal)
        self.setTitleColor(offColor, forState: .Selected)
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
