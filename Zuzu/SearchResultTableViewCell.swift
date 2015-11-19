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
    @IBOutlet weak var houseSourceLabel: UILabel!
    
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
   
    private func prpcessSourceString(label:UILabel, source:Int) {
        switch source {
        case 1:
            label.textColor = UIColor.colorWithRGB(0xFF9500)
            label.text = "591"
        case 2:
            label.textColor = UIColor.colorWithRGB(0x55EFCB)
            label.text = "好房網"
        case 3:
            label.textColor = UIColor.colorWithRGB(0xFFCD02)
            label.text = "樂屋網"
        default:
            label.text = nil
            break
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Reset any existing information
        houseTitle.text = nil
        houseAddr.text = nil
        houseTypeAndUsage.text = nil
        houseSize.text = nil
        housePrice.text = nil
        houseSourceLabel.text = nil
        addToCollectionButton.image = UIImage(named: "heart_n")
        prefixedButton.image = UIImage(named: "heart_n")
        
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
            
            prpcessSourceString(houseSourceLabel, source: houseItem.source)

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
                prefixedButton.image = UIImage(named: "heart_p")
            } else {
                prefixedButton.image = UIImage(named: "heart_n")
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
