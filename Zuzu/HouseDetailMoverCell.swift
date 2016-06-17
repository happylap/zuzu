//
//  HouseDetailAddressCell.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class HouseDetailMoverCell: UITableViewCell {
    
    @IBOutlet weak var titleIcon: UIImageView! {
        didSet {
            titleIcon.image = UIImage(named: "delivery_truck")?.imageWithRenderingMode(.AlwaysTemplate)
            titleIcon.tintColor = UIColor.colorWithRGB(0xFF6666, alpha: 1)
        }
    }
    
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
