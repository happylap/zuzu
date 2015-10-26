//
//  SearchResultTableViewCell.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//
import Alamofire
import AlamofireImage
import UIKit
import Foundation

class SearchResultTableViewCell: UITableViewCell {
    
    @IBOutlet weak var houseImg: UIImageView!
    @IBOutlet weak var houseTitle: UILabel!
    @IBOutlet weak var houseTypeAndUsage: UILabel!
    @IBOutlet weak var houseSize: UILabel!
    @IBOutlet weak var houseAddr: UILabel!
    @IBOutlet weak var housePrice: UILabel!
    
    let placeholderImg = UIImage(named: "house_img")
    
    weak var parentTableView: UITableView!
    
    var indexPath: NSIndexPath!
    
    var houseItem: HouseItem? {
        didSet {
            updateUI()
        }
    }
    
    let textLayer = CATextLayer()
    let titleBackground = CAGradientLayer()
    let infoBackground = CALayer()
    
    private func addImageOverlay() {

        ///Gradient layer
        let gradientColors = [UIColor.grayColor().colorWithAlphaComponent(0.6).CGColor, UIColor.clearColor().CGColor]
        let gradientLocations = [0.0, 0.2]
        titleBackground.frame = houseImg.bounds
        titleBackground.colors = gradientColors
        titleBackground.locations = gradientLocations
        
        houseImg.layer.addSublayer(titleBackground)
        
        let infoHeight = self.contentView.bounds.height / 3.5
        let newOrigin = CGPoint(x: houseImg.bounds.origin.x,
            y: houseImg.bounds.origin.y + houseImg.bounds.height - infoHeight)
        
        infoBackground.frame = CGRect(origin: newOrigin,
                        size: CGSize(width: houseImg.bounds.width, height: infoHeight))
            
        infoBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3).CGColor
        
        houseImg.layer.addSublayer(infoBackground)
        
        ///Text Layer
//        let textMargin = CGFloat(8.0)
//        let newOrigin = CGPoint(x: houseImg.bounds.origin.x + textMargin, y: houseImg.bounds.origin.y + textMargin)
//        textLayer.frame = CGRect(origin: newOrigin,
//            size: CGSize(width: houseImg.bounds.width - 2 * textMargin, height: houseImg.bounds.height))
//        
//        textLayer.string = title
//        textLayer.fontSize = 24.0
//        let fontName: CFStringRef = UIFont.boldSystemFontOfSize(20).fontName//"Noteworthy-Light"
//        textLayer.font = CTFontCreateWithName(fontName, 24.0, nil)
//        //textLayer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2).CGColor
//        textLayer.foregroundColor = UIColor.whiteColor().CGColor
//        textLayer.wrapped = false
//        textLayer.alignmentMode = kCAAlignmentLeft
//        textLayer.contentsScale = UIScreen.mainScreen().scale
//        
//        houseImg.layer.addSublayer(textLayer)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset any existing information
        houseTitle.text = nil
        houseAddr.text = nil
        houseSize.text = nil
        housePrice.text = nil
        
        // Cancel image loading operation
        houseImg.af_cancelImageRequest()
        houseImg.layer.removeAllAnimations()
        houseImg.image = nil
        
        NSLog("\n")
        NSLog("- Cell Instance [%p] Reset Data For Current Row[\(indexPath.row)]", self)
        
    }
    
    func updateUI() {
        
        // load new information (if any)
        if let houseItem = self.houseItem
        {
            houseTitle.text = houseItem.title
            houseAddr.text = houseItem.addr
            houseSize.text = String(houseItem.size) + "坪"
            housePrice.text = String(houseItem.price)
            houseImg.image = placeholderImg
            
            if let imageURLList = houseItem.imgList {
                if let firstURL = NSURL(string: imageURLList[0]) {
                    
                    let size = houseImg.frame.size
                    
                    NSLog("    <Start> Loading Img for Row[\(indexPath.row)]")
                    
                    houseImg.af_setImageWithURL(firstURL, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2))
                        { (request, response, result) -> Void in
                            NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                            
                            //self.contentView.updateConstraintsIfNeeded()
                            //self.contentView.setNeedsLayout()
                            //self.setNeedsLayout()
                            self.addImageOverlay()
                    }
                }
            }
            
            
        }
    }
    
}
