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
        self.accessoryType = UITableViewCellAccessoryType.None
        self.simpleFilterLabel?.text = nil
        self.filterLabel?.text = nil
        self.filterSelection?.text = nil
    }
    
}
