//
//  RadarPurchaseTableViewCell.swift
//  Zuzu
//
//  Created by eechih on 1/24/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SCLAlertView

private let Log = Logger.defaultLogger

class RadarPurchaseTableViewCell: UITableViewCell {
    
    var product: MySKProduct? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var localizedTitle: UILabel!
    @IBOutlet weak var localizedDescription: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    // MARK: - Private Utils
    func updateUI() {
        Log.debug("\(self) updateUI")
        
        self.localizedTitle.text = self.product?.localizedTitle
        self.localizedDescription.text = self.product?.localizedDescription
        
        self.buyButton.userInteractionEnabled = true
        self.buyButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("onBuyButtonTouched:")))
        
    }
    
    
    // MARK: - Inherited Methods
    
    override func prepareForReuse() {
        Log.debug("\(self) prepareForReuse")
        
        super.prepareForReuse()
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Reset any existing information
        self.localizedTitle.text = nil
        self.localizedDescription.text = nil
        self.buyButton.userInteractionEnabled = false
        
    }
    
    // MARK: - Action Handlers
    func onBuyButtonTouched(sender: UITapGestureRecognizer) {
        Log.debug("\(self) onBuyButtonTouched")
        
        if let product = self.product {
            let loginAlertView = SCLAlertView()
            loginAlertView.addButton("確認購買") {
                
            }
            let subTitle = "您目前選擇\(product.localizedTitle)\n\n\(product.localizedDescription)"
            loginAlertView.showNotice("購買確認", subTitle: subTitle, closeButtonTitle: "取消", colorStyle: 0x1CD4C6, colorTextButton: 0xFFFFFF)
            
        }
    }
    
}

