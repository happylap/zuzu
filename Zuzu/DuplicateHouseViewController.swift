//
//  DuplicateHouseViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

protocol DuplicateHouseViewControllerDelegate: class {
    func onDismiss()
    func onContinue()
}

class DuplicateHouseViewController: UIViewController {
    
    struct ViewTransConst {
        static let displayHouseDetail:String = "displayHouseDetail"
    }
    
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.addTarget(self, action: "onContinueButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }

    internal var delegate: DuplicateHouseViewControllerDelegate?
    
    internal var houseItem:HouseItem?
    
    internal var childrenText:String?
    
    func onContinueButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.onContinue()
        }
    }
    
    func onCancelButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.onDismiss()
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
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            
            NSLog("prepareForSegue: %@", identifier)
            
            switch identifier{
            case ViewTransConst.displayHouseDetail:
                if let hdvc = segue.destinationViewController as? HouseDetailViewController {
                    
                    if let houseItem = self.houseItem {
                        hdvc.houseItem = houseItem
                        //hdvc.delegate = self
                        
                        ///GA Tracker
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemPrice,
                            label: String(houseItem.price))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemSize,
                            label: String(houseItem.size))
                        
                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
                            action: GAConst.Action.Activity.ViewItemType,
                            label: String(houseItem.purposeType))
                    }
                }
            default: break
            }
        }
    }
}
