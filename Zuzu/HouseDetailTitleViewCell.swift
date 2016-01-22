//
//  HouseDetailTitleViewCell.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import MarqueeLabel

private let Log = Logger.defaultLogger

class HouseDetailTitleViewCell: UITableViewCell {

    @IBOutlet weak var titleImage: UIImageView!
    
    @IBOutlet weak var houseTitleLabel: UILabel!
    
    let titleBackground = CAGradientLayer()
    
    private func addImageOverlay(image: UIImageView) {
        
        ///Gradient layer
        let gradientColors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        let gradientLocations = [0.0, 1.0]
        let layerRect = CGRect(x: image.bounds.origin.x, y: image.bounds.origin.y, width: image.bounds.width, height: image.bounds.width * 188/1441)
        titleBackground.frame = layerRect
        titleBackground.colors = gradientColors
        titleBackground.locations = gradientLocations
        titleBackground.opacity = 0.7
        
        image.layer.addSublayer(titleBackground)
    }
    
    override func prepareForReuse() {
        Log.debug("prepareForReuse \(self)")
        houseTitleLabel.text = nil
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Log.debug("awakeFromNib \(self)")
        
        // Initialization code
        let label:MarqueeLabel =  houseTitleLabel as! MarqueeLabel
        label.userInteractionEnabled = true
        label.trailingBuffer = 30
        label.rate = 30 //pixels/sec
        label.fadeLength = 10
        label.animationDelay = 1.5 //Sec
        label.marqueeType = .MLContinuous
        
        self.addImageOverlay(titleImage)
        
    }
}
