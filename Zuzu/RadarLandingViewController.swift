//
//  RadarLandingViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class RadarLandingViewController: UIViewController {
    
    @IBOutlet weak var leftSampleImage: UIImageView! {
        didSet {
            
            setImageToCircle(leftSampleImage)
            
        }
    }
    
    @IBOutlet weak var rightSampleImage: UIImageView!{
        didSet {
            
            setImageToCircle(rightSampleImage)
            
        }
    }
    
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            continueButton.layer.borderWidth = 2
            continueButton.layer.borderColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1).CGColor
            continueButton.tintColor =
                UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
            
            continueButton.addTarget(self, action: #selector(RadarLandingViewController.onContinueButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
            
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: #selector(RadarLandingViewController.onCancelButtonTouched(_:)), forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    private func setImageToCircle(imageView: UIImageView) {
        //imageView.layer.borderWidth = 0.3
        imageView.layer.masksToBounds = true
        //imageView.layer.borderColor = UIColor.lightGrayColor().CGColor//colorWithRGB(0x66FFCC, alpha: 0.8).CGColor
        imageView.layer.cornerRadius = leftSampleImage.frame.size.height/2
        imageView.clipsToBounds = true
    }
    
    func onContinueButtonTouched(sender: UIButton) {
        
        UserDefaultsUtils.setRadarLandindPageDisplayed()
        
        NSNotificationCenter.defaultCenter().postNotificationName(SwitchToTabNotification, object: self,
                                                                  userInfo: ["targetTab" : MainTabConstants.RADAR_TAB_INDEX])
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onCancelButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setImageToCircle(leftSampleImage)
        setImageToCircle(rightSampleImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //Google Analytics Tracker
        self.trackScreen()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
