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

class FilterTableViewCell: UITableViewCell {
    
    @IBOutlet weak var simpleFilterLabel: UILabel!
    
    @IBOutlet weak var filterLabel: UILabel!
    
    @IBOutlet weak var filterSelection: UILabel!
    
    weak var parentTableView: UITableView!

    override func prepareForReuse() {
        super.prepareForReuse()

//        // Reset any existing information
//        houseTitle.text = nil
//        houseAddr.text = nil
//        houseTypeAndUsage.text = nil
//        houseSize.text = nil
//        housePrice.text = nil
//        
//        // Cancel image loading operation
//        houseImg.af_cancelImageRequest()
//        houseImg.layer.removeAllAnimations()
//        houseImg.image = nil
//        
//        NSLog("\n")
//        NSLog("- Cell Instance [%p] Reset Data For Current Row[\(indexPath.row)]", self)
//        
    }
    
}
