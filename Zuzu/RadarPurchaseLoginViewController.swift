//
//  RadarPurchaseLoginViewController.swift
//  Zuzu
//
//  Created by Harry Yeh on 2/15/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//
import UIKit

private let Log = Logger.defaultLogger

class RadarPurchaseLoginViewController: UIViewController {
    
    var cancelHandler: (() -> Void)?
    var fbLoginHandler: (() -> Void)?
    var googleLoginHandler: (() -> Void)?
    
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            /*cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()*/
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    
    
    @IBOutlet weak var loginText: UILabel!
    
    @IBOutlet weak var fbButton: UIButton!{
        didSet{
            fbButton.addTarget(self, action: "onFBButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var googleButton: UIButton!{
        didSet{
            googleButton.addTarget(self, action: "onGoogleButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }

    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        view.opaque = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Private Util
    
    func onCancelButtonTouched(sender: UIButton) {
        Log.debug("\(self) onCancelButtonTouched")
        dismissViewControllerAnimated(true, completion: self.cancelHandler)
    }
    
    func onFBButtonTouched(sender: UIButton) {
        Log.debug("\(self) onFBButtonTouched")
        dismissViewControllerAnimated(true, completion: self.fbLoginHandler)
    }
  
    func onGoogleButtonTouched(sender: UIButton) {
        Log.debug("\(self) onGoogleButtonTouched")
        dismissViewControllerAnimated(true, completion: self.googleLoginHandler)
    }
}
