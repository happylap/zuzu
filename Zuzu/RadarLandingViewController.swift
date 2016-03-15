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
            
            leftSampleImage.layer.borderWidth=1.0
            leftSampleImage.layer.masksToBounds = false
            leftSampleImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            leftSampleImage.layer.cornerRadius = 13
            leftSampleImage.layer.cornerRadius = leftSampleImage.frame.size.height/2
            leftSampleImage.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var rightSampleImage: UIImageView!{
        didSet {
            
            rightSampleImage.layer.borderWidth=1.0
            rightSampleImage.layer.masksToBounds = false
            rightSampleImage.layer.borderColor = UIColor.lightGrayColor().CGColor
            rightSampleImage.layer.cornerRadius = 13
            rightSampleImage.layer.cornerRadius = rightSampleImage.frame.size.height/2
            rightSampleImage.clipsToBounds = true
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
            
            continueButton.addTarget(self, action: "onContinueButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
            
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    func onContinueButtonTouched(sender: UIButton) {
        
        UserDefaultsUtils.setRadarLandindPageDisplayed()
        
        NSNotificationCenter.defaultCenter().postNotificationName("switchToTab", object: self, userInfo: ["targetTab" : MainTabViewController.MainTabConstants.RADAR_TAB_INDEX])
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onCancelButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
