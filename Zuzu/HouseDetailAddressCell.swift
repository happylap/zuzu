//
//  HouseDetailAddressCell.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class HouseDetailAddressCell: UITableViewCell {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapIcon: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ///Pass the touch event to parent table cell
        mapIcon.userInteractionEnabled = false
    }
}
