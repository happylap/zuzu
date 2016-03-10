//
//  RadarRetryViewController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2016/2/23.
//  Copyright © 2016年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

private let Log = Logger.defaultLogger

class RadarRetryViewController: UIViewController {
    
    var isBlank = false
    
    @IBOutlet weak var refreshImageView: UIImageView!
    
    @IBOutlet weak var refreshTextLabel: UILabel!
    
    override func viewDidLoad() {
        if isBlank == false{
            let tapGuesture = UITapGestureRecognizer(target: self, action: "imageTapped:")
            self.refreshImageView.addGestureRecognizer(tapGuesture)
            self.refreshImageView.userInteractionEnabled = true
        }
        else{
            self.refreshImageView.hidden = true
            self.refreshTextLabel.hidden = true
        }
    }

    func imageTapped(){
        
    }
}
