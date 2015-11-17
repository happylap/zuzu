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
    @IBOutlet weak var addToCollectionButton: UIImageView!
    @IBOutlet weak var prefixedButton: UIImageView!
    @IBOutlet weak var contactedView: UIView!
    
    let placeholderImg = UIImage(named: "house_img")
    
    weak var parentTableView: UITableView!
    
    var indexPath: NSIndexPath!
    
    var houseItem: HouseItem? {
        didSet {
            updateUI()
        }
    }
    
    
    var houseItemForCollection: House? {
        didSet {
            updateUIForCollection()
        }
    }
    
    //let textLayer = CATextLayer()
    let titleBackground = CAGradientLayer()
    let infoBackground = CALayer()
    
    private func getTypeString(type: Int) -> String? {
        
        let typeStr:String?
        
        switch type {
        case CriteriaConst.HouseType.BUILDING_WITHOUT_ELEVATOR:
            typeStr = "公寓"
        case CriteriaConst.HouseType.BUILDING_WITH_ELEVATOR:
            typeStr = "電梯大樓"
        case CriteriaConst.HouseType.INDEPENDENT_HOUSE:
            typeStr = "透天厝"
        case CriteriaConst.HouseType.INDEPENDENT_HOUSE_WITH_GARDEN:
            typeStr = "別墅"
        default:
            typeStr = ""
            break
        }
        
        if(typeStr != nil) {
            return typeStr!
        } else {
            return nil
        }
    }
    
    
    private func getUsageString(usage:Int) -> String? {
        
        let usageStr:String?
        
        switch usage {
        case CriteriaConst.PrimaryType.FULL_FLOOR:
            usageStr = "整層住家"
        case CriteriaConst.PrimaryType.HOME_OFFICE:
            usageStr = "住辦"
        case CriteriaConst.PrimaryType.ROOM_NO_TOILET:
            usageStr = "雅房"
        case CriteriaConst.PrimaryType.SUITE_COMMON_AREA:
            usageStr = "分租套房"
        case CriteriaConst.PrimaryType.SUITE_INDEPENDENT:
            usageStr = "獨立套房"
        default:
            usageStr = ""
            break
        }
        
        if(usageStr != nil) {
            return usageStr!
        } else {
            return nil
        }
    }
    
    internal func addImageOverlay() {
        
        ///Gradient layer
        let gradientColors = [UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        //let gradientLocations = [0.0, 0.8, 0.9, 1.0]
        
        let layerRect = CGRect(x: houseImg.bounds.origin.x, y: houseImg.bounds.origin.y, width: houseImg.bounds.width, height: houseImg.bounds.width * 188/1441)
        
        titleBackground.frame = layerRect
        titleBackground.colors = gradientColors
        //titleBackground.locations = gradientLocations
        
        houseImg.layer.addSublayer(titleBackground)
        
        let infoHeight = self.contentView.bounds.width * (200/1441)
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
        houseTypeAndUsage.text = nil
        houseSize.text = nil
        housePrice.text = nil
        addToCollectionButton.image = UIImage(named: "Heart_n")
        prefixedButton.image = UIImage(named: "Heart_n")
        
        // Cancel image loading operation
        houseImg.af_cancelImageRequest()
        houseImg.layer.removeAllAnimations()
        houseImg.image = nil
        
        NSLog("\n")
        NSLog("- Cell Instance [%p] Reset Data For Current Row[\(indexPath.row)]", self)
        
    }
    
    func updateUI() {
        
        // load new information (if any)
        if let houseItem = self.houseItem {
            houseTitle.text = houseItem.title
            houseAddr.text = houseItem.addr
            
            if let houseTypeStr = self.getTypeString(houseItem.houseType) {
                if let purposeTypeStr = self.getUsageString(houseItem.purposeType) {
                    houseTypeAndUsage.text = "\(houseTypeStr)/\(purposeTypeStr)"
                } else {
                    houseTypeAndUsage.text = "\(houseTypeStr)"
                }
            } else {
                if let purposeTypeStr = self.getUsageString(houseItem.purposeType) {
                    houseTypeAndUsage.text = "\(purposeTypeStr)"
                }
            }
            
            houseSize.text = String(format: "%d 坪", houseItem.size)
            housePrice.text = String(houseItem.price)
            houseImg.image = placeholderImg
            
            if let imageURLList = houseItem.imgList {
                if let firstURL = NSURL(string: imageURLList[0]) {
                    
                    let size = houseImg.frame.size
                    
                    NSLog("    <Start> Loading Img for Row[\(indexPath.row)]")
                    
                    houseImg.af_setImageWithURL(firstURL, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2))
                        { (request, response, result) -> Void in
                            NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                            NSLog("    <URL> %@", firstURL)
                    }
                }
            }
            self.addImageOverlay()
        }
    }
    
    
    
    func updateUIForCollection() {
        
        // load new information (if any)
        if let house = self.houseItemForCollection {
            
            for constraintWithItem: NSLayoutConstraint in self.contentView.constraints {
                if constraintWithItem.firstItem.restorationIdentifier == "SearchResultTableViewCell_houseTitle" {
                    if constraintWithItem.firstAttribute == .Leading {
                        self.contentView.removeConstraint(constraintWithItem)
                        self.contentView.addConstraint(NSLayoutConstraint(item: self.houseTitle, attribute: .Leading, relatedBy: .Equal, toItem: self.prefixedButton, attribute: .Trailing , multiplier: 1.0, constant: 4.0))
                    }
                }
            }
            
            if house.contacted == true {
                prefixedButton.image = UIImage(named: "Heart_p")
            } else {
                prefixedButton.image = UIImage(named: "Heart_n")
            }
            self.prefixedButton.hidden = false
            self.prefixedButton.userInteractionEnabled = true
            self.prefixedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onContactTouched:")))
            
            self.contactedView.hidden = !(house.contacted)
            
            self.addToCollectionButton.image = UIImage(named: "bookmark-outline-plus")
            self.addToCollectionButton.hidden = false
            
            self.houseTitle.text = house.title
            self.housePrice.text = house.price.description
            self.houseAddr.text = house.addr
            self.houseSize.text = "\(house.size) 坪"
            
            let houseTypeStr = self.getTypeString(Int(house.type)) ?? ""
            let purposeTypeStr = self.getUsageString(Int(house.usage)) ?? ""
            self.houseTypeAndUsage.text = "\(houseTypeStr)/\(purposeTypeStr)"
            
            self.houseImg.image = placeholderImg
            
            if house.img?.count > 0 {
                if let imgUrl = house.img?[0] {
                    let size = self.houseImg.frame.size
                    
                    self.houseImg.af_setImageWithURL(NSURL(string: imgUrl)!, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                        
                        NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                    }
                }
            }
            
            self.addImageOverlay()
        }
    }
    
    func onContactTouched(sender: UITapGestureRecognizer) {
        NSLog("%@ onCalledTouched", self)
        if let house: House = houseItemForCollection {
            if house.contacted == false {
                HouseDao.sharedInstance.updateByObjectId(house.objectID, dataToUpdate: ["contacted": true])
            } else {
                HouseDao.sharedInstance.updateByObjectId(house.objectID, dataToUpdate: ["contacted": false])
            }
        }
    }
    
}
