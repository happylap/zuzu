//
//  NotificationItemTableViewCell.swift
//  Zuzu
//
//  Created by Ted on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit


class NotificationItemTableViewCell: UITableViewCell
{
    var notificationItem:NotificationHouseItem?
        {
        didSet{
            updateUI()
        }
    }

    @IBOutlet weak var houseTitleLabel: UILabel!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    @IBOutlet weak var postTimeLabel: UILabel!
    
    @IBOutlet weak var houseTypeLabel: UILabel!
    
    @IBOutlet weak var houseSizeLabel: UILabel!
    
    @IBOutlet weak var housePriceLabel: UILabel!
    
    @IBOutlet weak var houseImage: UIImageView!{
        didSet{
            //houseImage.layer.borderWidth = 1.0
            //houseImage.layer.masksToBounds = false
            //houseImage.layer.borderColor = UIColor.whiteColor().CGColor
            //houseImage.layer.cornerRadius = houseImage.frame.size.width/2
            houseImage.clipsToBounds = true
            houseImage.contentMode = .Left
        }
    }
    
    func updateUI()
    {
        houseTitleLabel?.text = nil
        
        if let item = self.notificationItem{
            houseTitleLabel?.text = item.title
            addressLabel?.text = item.addr
            postTimeLabel?.text = "2015/12/17"
            var housetypeString = ""
            var purpose = ""
            switch item.houseType {
                case 1: housetypeString = "整層住家"
                case 2: housetypeString = "獨立套房"
                case 3: housetypeString = "分租套房"
                case 4: housetypeString = "雅房"
                case 8: housetypeString = "住辦"
                default: break
            }

            switch item.purposeType{
                case 1: purpose = "公寓"
                case 2: purpose = "電梯大樓"
                case 3: purpose = "透天厝"
                case 4: purpose = "別墅"
                default: break
            }
            
            houseTypeLabel?.text = "\(housetypeString)/\(purpose)"
            houseSizeLabel?.text = "\(item.size)坪"
            housePriceLabel?.text = "\(item.price)元"
            houseImage?.image = UIImage(named:"591")
            
            if item.isRead == false{
                //self.backgroundColor = UIColor(red: 0, green: 200, blue: 50, alpha: 0.2)
                self.backgroundColor = UIColor.colorWithRGB(0xE7F9F8, alpha: 1)
            }
            
            
        }
    }
}
