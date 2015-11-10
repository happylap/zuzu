
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
    
    var houseItem: House?
    
    override func viewDidLoad() {
        NSLog("%@ viewDidLoad", self)
        super.viewDidLoad()
        
        if houseItem != nil {
            updateUI()
        }
    }
    
    
    func updateUI() {
        NSLog("%@ updateUI", self)
        
        if let house: House = houseItem {
            
//            self.houseTitle.text = house.valueForKey("title") as? String
//            self.housePrice.text = house.valueForKey("price") as? String
//            self.houseAddr.text = house.valueForKey("addr") as? String

            self.houseTitle.text = house.title
            self.housePrice.text = house.price.description
            self.houseAddr.text = house.addr
            
            self.houseImg.image = placeholderImg
            
            
            
            if house.img?.count > 0 {
                if let img = house.img?[0] {
                    let size = self.houseImg.frame.size
                    
                    self.houseImg.af_setImageWithURL(NSURL(string: img)!, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                        
                        //NSLog("    <End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                        
                    }
                }
            }

            
        }
    }

}
