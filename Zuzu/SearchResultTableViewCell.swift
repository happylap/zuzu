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
            houseTitle?.text =  "\(indexPath.row) : \(houseItem.title)"
            
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
        }
    }
    
}
