//
//  NotificationItemTableViewCell.swift
//  Zuzu
//
//  Created by Ted on 2015/12/17.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

class NotificationItemTableViewCell: UITableViewCell {
    var notificationItem: NotificationHouseItem? {
        didSet {
            updateUI()
        }
    }

    @IBOutlet weak var houseTitleLabel: UILabel!

    @IBOutlet weak var addressLabel: UILabel!

    @IBOutlet weak var postTimeLabel: UILabel!

    @IBOutlet weak var houseTypeLabel: UILabel!

    @IBOutlet weak var houseSizeLabel: UILabel!

    @IBOutlet weak var housePriceLabel: UILabel!

    @IBOutlet weak var houseImage: UIImageView! {
        didSet {
            //houseImage.layer.borderWidth = 1.0
            //houseImage.layer.masksToBounds = false
            //houseImage.layer.borderColor = UIColor.whiteColor().CGColor
            //houseImage.layer.cornerRadius = houseImage.frame.size.width/2
            houseImage.clipsToBounds = true
            houseImage.contentMode = .ScaleAspectFill
        }
    }

    @IBOutlet weak var divider1: UIView!
    @IBOutlet weak var divider2: UIView!
    @IBOutlet weak var divider3: UIView!

    // MARK: - Inherited Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        Log.debug("awakeFromNib")

        self.houseTitleLabel.textColor = UIColor.colorWithRGB(0x2E2E2E, alpha: 1)
        self.addressLabel.textColor = UIColor.colorWithRGB(0x666666, alpha: 1)
        self.postTimeLabel.textColor = UIColor.colorWithRGB(0x666666, alpha: 1)
        self.houseTypeLabel.textColor = UIColor.colorWithRGB(0x666666, alpha: 1)
        self.houseSizeLabel.textColor = UIColor.colorWithRGB(0x666666, alpha: 1)
        self.housePriceLabel.textColor = UIColor.colorWithRGB(0xF38752, alpha: 1)

        self.divider1.backgroundColor = UIColor.colorWithRGB(0xDCDCDE, alpha: 1)
        self.divider2.backgroundColor = UIColor.colorWithRGB(0xDCDCDE, alpha: 1)
        self.divider3.backgroundColor = UIColor.colorWithRGB(0xDCDCDE, alpha: 1)

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("prepareForReuse")


    }

    func updateUI() {
        Log.debug("updateUI")

        houseTitleLabel?.text = nil
        let houseTypeLabelMaker: LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)

        if let item = self.notificationItem {
            let housetypeString = houseTypeLabelMaker.fromCodeForField(SolrConst.Field.HOUSE_TYPE, code: Int(item.houseType), defaultValue: "")
            let purpose = houseTypeLabelMaker.fromCodeForField(SolrConst.Field.PURPOSE_TYPE, code: Int(item.purposeType), defaultValue: "")

            houseTitleLabel?.text = item.title
            addressLabel?.text = item.addr
            houseTypeLabel?.text = "\(housetypeString)/\(purpose)"
            houseSizeLabel?.text = "\(item.size)坪"
            housePriceLabel?.text = "\(item.price)元"
            postTimeLabel?.text = CommonUtils.getLocalCustomStringFromDate(item.postTime!, format:"yyyy-MM-dd HH:mm")

            if item.isRead == false {
                self.contentView.backgroundColor = UIColor.colorWithRGB(0xE7F9F8, alpha: 1)
            } else {
                self.contentView.backgroundColor = UIColor.whiteColor()
            }

            let placeholderImg = UIImage(named: "house_no_img_small")

            self.houseImage.image = placeholderImg
            if let imgString = item.img?.first,
                let imgUrl = NSURL(string: imgString) {

                    self.houseImage.af_setImageWithURL(imgUrl, placeholderImage: placeholderImg, filter: nil, imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                        //self.houseImage.contentMode = .Left
                        Log.debug("Img loading done, status = \(response?.statusCode)")
                    }

            }
        }
    }
}
