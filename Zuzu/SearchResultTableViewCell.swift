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
    
    @IBOutlet weak var houseDesc: UILabel!
    
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
    let textBackground = CAGradientLayer()
    
    private func addTitleToImage(title: String) {

        ///Gradient layer
        let gradientColors = [UIColor.blackColor().colorWithAlphaComponent(0.7).CGColor, UIColor.clearColor().CGColor]
        let gradientLocations = [0.0, 0.3]
        textBackground.frame = houseImg.bounds
        textBackground.colors = gradientColors
        textBackground.locations = gradientLocations
        
        houseImg.layer.addSublayer(textBackground)
        
        ///Text Layer
        let textMargin = CGFloat(8.0)
        let newOrigin = CGPoint(x: houseImg.bounds.origin.x + textMargin, y: houseImg.bounds.origin.y + textMargin)
        textLayer.frame = CGRect(origin: newOrigin,
            size: CGSize(width: houseImg.bounds.width - 2 * textMargin, height: houseImg.bounds.height))
        
        textLayer.string = title
        textLayer.fontSize = 24.0
        let fontName: CFStringRef = UIFont.boldSystemFontOfSize(20).fontName//"Noteworthy-Light"
        textLayer.font = CTFontCreateWithName(fontName, 24.0, nil)
        //textLayer.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2).CGColor
        textLayer.foregroundColor = UIColor.whiteColor().CGColor
        textLayer.wrapped = false
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.contentsScale = UIScreen.mainScreen().scale
        
        houseImg.layer.addSublayer(textLayer)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset any existing information
        houseDesc?.text = nil
        houseTitle?.text = nil
        
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
            //houseTitle?.text =  "\(houseItem.title)"
            
            houseDesc?.text = houseItem.desc
            housePrice?.text = String(houseItem.price)
            houseImg?.image = placeholderImg
            
            if let imageURLList = houseItem.imgList {
                if let firstURL = NSURL(string: imageURLList[0]) {
                    
                    let size = houseImg.frame.size
                    
                    NSLog("    <Start> Loading Img for Row[\(indexPath.row)]")
                    
                    houseImg.af_setImageWithURL(firstURL, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2))
                        { (request, response, result) -> Void in
                            NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                    }
                }
            }
            
            self.addTitleToImage("\(houseItem.title)")
        }
    }
    
}
