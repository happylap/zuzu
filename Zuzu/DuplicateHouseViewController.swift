//
//  DuplicateHouseViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class DuplicateHouseViewController: UIViewController {

    @IBOutlet weak var childrenIdList: UILabel!
    
    internal var childrenText:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        childrenIdList.text = childrenText
        
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
