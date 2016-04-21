//
//  WalkthroughMasterViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import BWWalkthrough

class WalkthroughMasterViewController: BWWalkthroughViewController {

    @IBOutlet weak var closeWalkthroughButton: UIButton! {
        
        didSet {
            
            closeWalkthroughButton.layer.borderWidth = 1
            closeWalkthroughButton.layer.borderColor =
                UIColor.colorWithRGB(0xFFFFFF, alpha: 1).CGColor
            closeWalkthroughButton.tintColor =
                UIColor.colorWithRGB(0xFFFFFF, alpha: 1)
            closeWalkthroughButton
                .setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: UIControlState.Normal)
            closeWalkthroughButton
                .setTitleColor(UIColor.colorWithRGB(0xFFFFFF, alpha: 1), forState: UIControlState.Selected)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
