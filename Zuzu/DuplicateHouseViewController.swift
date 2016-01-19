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
    
    let enableAutoForward = false
    
    struct TableConst {
        static let sectionNum:Int = 1
        static let houseCellIdentifier = "houseItemCell"
    }
    
    struct ViewTransConst {
        static let displayHouseDetail:String = "displayHouseDetail"
    }
    
    private let countDownInterval = 1.0
    
    @IBOutlet weak var firstSubtitleLabel: UILabel! {
        didSet {
            
            var duplicateCount = 0
            
            if let duplicateList = self.duplicateList {
                duplicateCount = duplicateList.count
            }
            
            firstSubtitleLabel.text = String(format: "您點選的物件存在 %d 筆重複的物件", duplicateCount)
        }
    }
    
    @IBOutlet weak var duplicateTableView: UITableView!
    
    @IBOutlet weak var continueButton: UIButton! {
        didSet {
            continueButton.addTarget(self, action: "onContinueButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
            
            var title = String(format: "繼續")
            
            if(enableAutoForward) {
                title = String(format: "繼續(\(countDown))")
            }
            
            continueButton.setTitle(title,
                forState: [.Normal])
            
            
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!{
        didSet {
            cancelButton.setImage(UIImage(named: "cancel")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
            cancelButton.tintColor = UIColor.whiteColor()
            
            cancelButton.addTarget(self, action: "onCancelButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
        }
    }
    
    internal var delegate: DuplicateHouseViewControllerDelegate?
    
    internal var houseItem:HouseItem?
    
    internal var duplicateList:[String]?
    
    private var duplicateHouses:[HouseItem]?
    
    private var currentTimer:NSTimer?
    
    private var countDown = 10
    
    func onContinueButtonTouched(sender: UIButton) {
        
        self.delegate?.onContinue()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func onCancelButtonTouched(sender: UIButton) {
        self.dismissViewControllerAnimated(true) { () -> Void in
            self.delegate?.onDismiss()
        }
    }
    
    func onCheckForwardTriggered() {
        
        countDown--
        
        if(countDown <= 0) {
            currentTimer?.invalidate()
            
            self.delegate?.onContinue()
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        } else {
            
            let title = String(format: "繼續(%d)", self.countDown)
            continueButton.setTitle(title,
                forState: [.Normal])
        }
        
    }
    
    private func configureTableView() {
        
        duplicateTableView.estimatedRowHeight = BaseLayoutConst.houseImageHeight * getCurrentScale()
        
        duplicateTableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        duplicateTableView.dataSource = self
        duplicateTableView.delegate = self
        duplicateTableView.registerNib(UINib(nibName: "SearchResultTableViewCell", bundle: nil), forCellReuseIdentifier: "houseItemCell")
    }
    
    private func fetchDuplicateHouses(houseIdList:[String]) {
        
        HouseDataRequester.getInstance().searchByIds(houseIdList) { (totalNum, result, error) -> Void in
            self.duplicateHouses = result
            self.duplicateTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTableView()
        
        if let duplicateIdList = self.duplicateList {
            fetchDuplicateHouses(duplicateIdList)
        }
        
        /// Setup Timer for auto forwarding
        
        if(enableAutoForward) {
            currentTimer = NSTimer.scheduledTimerWithTimeInterval(countDownInterval, target: self, selector: "onCheckForwardTriggered", userInfo: nil, repeats: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //        if let identifier = segue.identifier{
        //
        //            NSLog("prepareForSegue: %@", identifier)
        //
        //            switch identifier{
        //            case ViewTransConst.displayHouseDetail:
        //                if let hdvc = segue.destinationViewController as? HouseDetailViewController {
        //
        //                    if let houseItem = self.houseItem {
        //                        hdvc.houseItem = houseItem
        //                        //hdvc.delegate = self
        //
        //                        ///GA Tracker
        //                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
        //                            action: GAConst.Action.Activity.ViewItemPrice,
        //                            label: String(houseItem.price))
        //
        //                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
        //                            action: GAConst.Action.Activity.ViewItemSize,
        //                            label: String(houseItem.size))
        //
        //                        self.trackEventForCurrentScreen(GAConst.Catrgory.Activity,
        //                            action: GAConst.Action.Activity.ViewItemType,
        //                            label: String(houseItem.purposeType))
        //                    }
        //                }
        //            default: break
        //            }
        //        }
    }
}


// MARK: - Table View Data Source / Delegate
extension DuplicateHouseViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableConst.sectionNum
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let duplicateHouses = self.duplicateHouses {
            return duplicateHouses.count
        } else {
            return 0
        }
        
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TableConst.houseCellIdentifier, forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        if let duplicateHouses = self.duplicateHouses {
            
            cell.parentTableView = tableView
            cell.indexPath = indexPath
            
            let houseItem = duplicateHouses[row]
            
            cell.houseItem = houseItem
            
        } else {
            
            assert(false, "This should not happen when there is no duplicate houses")
            
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //        let houseItem = dataSource.getItemForRow(indexPath.row)
        //
        //        print("Duplicates: \(houseItem.children?.joinWithSeparator(","))")
        //
        //        if let duplicates = houseItem.children {
        //            self.runOnMainThreadAfter(0.1, block: { () -> Void in
        //                self.performSegueWithIdentifier(ViewTransConst.displayDuplicateHouse, sender: self)
        //            })
        //        } else {
        //            self.performSegueWithIdentifier(ViewTransConst.displayHouseDetail, sender: self)
        //        }
    }
    
}
