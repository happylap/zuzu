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

    @IBOutlet weak var filterCheckMark: UIImageView!

    weak var parentTableView: UITableView!

    private func setup() {
        self.filterCheckMark?.image = UIImage(named: "uncheck")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.filterCheckMark?.tintColor = UIColor.grayColor()
        self.filterCheckMark?.tintColorDidChange()

        self.simpleFilterLabel?.textColor = UIColor.colorWithRGB(0x2e2e2e)
        self.filterLabel?.textColor = UIColor.colorWithRGB(0x2e2e2e)
        self.filterSelection?.text = nil
    }

    override func awakeFromNib() {
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setup()
    }

}
