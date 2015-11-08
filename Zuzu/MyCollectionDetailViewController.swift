
//
//  MyCollectionDetail.swift
//  Zuzu
//
//  Created by eechih on 2015/11/9.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class MyCollectionDetailViewController: UIViewController {
    
    @IBOutlet weak var houseImg: UIImageView!
    @IBOutlet weak var houseTitle: UILabel!
    @IBOutlet weak var houseAddr: UILabel!
    @IBOutlet weak var housePrice: UILabel!
    
    var houseItem: AnyObject?
    
    var houseList: [House]?
    
    let placeholderImg = UIImage(named: "house_img")
    
    weak var parentTableView: UITableView!
    
    var indexPath: NSIndexPath!
    
    var houseId: String? {
        didSet {
            if let result = HouseDao.sharedInstance.getHouseById2(self.houseId!) {
                print(result)
//                self.houseItem = result
                houseList = result
                updateUI()
            }
        }
    }
    
    
    func updateUI() {
        NSLog("%@ updateUI", self)
        // load new information (if any)
        if let item = self.houseList?[0] {
            print(item)
            self.houseTitle.text = item.valueForKey("title") as? String
            self.housePrice.text = item.valueForKey("price") as? String
            self.houseAddr.text = item.valueForKey("addr") as? String
            
            self.houseImg.image = placeholderImg
            
            if item.valueForKey("img")?.count > 0 {
                if let imgUrl = item.valueForKey("img")?[0] as? String {
                    let size = self.houseImg.frame.size
                    
                    self.houseImg.af_setImageWithURL(NSURL(string: imgUrl)!, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                        
                        NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                        
                        //self.contentView.updateConstraintsIfNeeded()
                        //self.contentView.setNeedsLayout()
                        //self.setNeedsLayout()
                    }
                }
            }
            
            
        }
    }

}
