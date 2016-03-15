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
    
    var navigationView: RadarNavigationController?
    
    var isBlank = false
    
    @IBOutlet weak var offlineStateImage: UIImageView! {
        
        didSet {
            offlineStateImage.image = UIImage(named: "cloud-outline-off")?.imageWithRenderingMode(.AlwaysTemplate)
            offlineStateImage.tintColor = UIColor.lightGrayColor()
        }
        
    }
    
    @IBOutlet weak var refreshImageView: UIImageView! {
        
        didSet {
            refreshImageView.image = UIImage(named: "refresh")?.imageWithRenderingMode(.AlwaysTemplate)
            refreshImageView.tintColor = UIColor.grayColor()
        }
        
    }
    
    @IBOutlet weak var refreshTextLabel: UILabel!
    
    private func hideComponents() {
        self.refreshImageView.hidden = true
        self.refreshTextLabel.hidden = true
        self.offlineStateImage.hidden = true
    }
    
    
    private func showComponents() {
        self.refreshImageView.hidden = false
        self.refreshTextLabel.hidden = false
        self.offlineStateImage.hidden = false
    }
    
    override func viewDidLoad() {
        if isBlank == false{
            let tapGuesture = UITapGestureRecognizer(target: self, action: "imageTapped:")
            self.refreshImageView.addGestureRecognizer(tapGuesture)
            self.refreshImageView.userInteractionEnabled = true
            
            let tapGuesture2 = UITapGestureRecognizer(target: self, action: "imageTapped:")
            self.refreshTextLabel.addGestureRecognizer(tapGuesture2)
            self.refreshTextLabel.userInteractionEnabled = true
            
            let tapGuesture3 = UITapGestureRecognizer(target: self, action: "imageTapped:")
            self.offlineStateImage.addGestureRecognizer(tapGuesture3)
            self.offlineStateImage.userInteractionEnabled = true
        }
        else{
            self.hideComponents()
        }
    }

    func imageTapped(sender: UITapGestureRecognizer){
        
        self.hideComponents()
        
        self.navigationView?.showRadar()
    }
}
