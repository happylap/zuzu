//
//  HouseDetailContactBarView.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import MarqueeLabel

class HouseDetailContactBarView: UIView {

    @IBOutlet weak var contactName: UILabel!
    
    @IBOutlet weak var contactByMailButton: UIButton!
    
    @IBOutlet weak var contactByPhoneButton: UIButton!
    
    var view:UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass:self.dynamicType)
        let nib = UINib(nibName: "HouseDetailContactBarView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    private func setup() {
        
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth.union(UIViewAutoresizing.FlexibleHeight)
        
        view.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        
        addSubview(view)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NSLog("awakeFromNib %@", self)
        
        // Initialization code
        let label:MarqueeLabel =  contactName as! MarqueeLabel
        label.userInteractionEnabled = true
        label.trailingBuffer = 30
        label.rate = 30 //pixels/sec
        label.fadeLength = 5
        label.animationDelay = 1.5 //Sec
        label.marqueeType = .MLContinuous
        
    }
    
}
