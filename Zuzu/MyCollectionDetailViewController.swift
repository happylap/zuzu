
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
    
    let placeholderImg = UIImage(named: "house_img")
    
    var indexPath: NSIndexPath!
    
    var houseId: String?
    
    override func viewDidLoad() {
        NSLog("%@ viewDidLoad", self)
        super.viewDidLoad()
        updateUI()
    }
    
    
    func updateUI() {
        NSLog("%@ updateUI, id: \(self.houseId!)", self)
        
        if let house = HouseDao.sharedInstance.getHouseById(self.houseId!) {
            print("------")
            print(house)
            
            
            print(house.valueForKey("title") as? String)
            
            
            self.houseTitle.text = house.valueForKey("title") as? String
            self.housePrice.text = house.valueForKey("price") as? String
            self.houseAddr.text = house.valueForKey("addr") as? String
            
            self.houseImg.image = placeholderImg
            
            if house.valueForKey("img")?.count > 0 {
                if let imgUrl = house.valueForKey("img")?[0] as? String {
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
