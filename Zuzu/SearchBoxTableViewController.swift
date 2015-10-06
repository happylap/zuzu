    //
    //  ZuzuTableViewController.swift
    //  Zuzu
    //
    //  Created by Jung-Shuo Pai on 2015/9/21.
    //  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
    //
    
    import UIKit

    
    class ToggleButtonListenr: ToggleStateListenr {
        
        let target: ToggleButton
        
        init(target: ToggleButton) {
            self.target = target
        }
        
        func onStateChanged(sender: AnyObject, state: Bool) {
            if let sourceButton = sender as? ToggleButton {
                //Toggle off all other buttons when "select all" button is toggled on
                if(sourceButton.getToggleState()) {
                    self.target.setToggleState(false)
                }
            }
        }
    }
    
    struct UIControlTag {
        static let NOT_LIMITED_BUTTON_TAG = 99
    }
    
    class SearchBoxTableViewController: UITableViewController, UISearchBarDelegate {
        
        var selectAllButton:ToggleButton?
        
        @IBOutlet weak var typeButtonContainer: UIView! {
            didSet {
                let views = typeButtonContainer.subviews
                
                selectAllButton = typeButtonContainer.viewWithTag(UIControlTag.NOT_LIMITED_BUTTON_TAG) as? ToggleButton
                
                if(selectAllButton != nil) {
                    selectAllButton!.toggleButtonState()
                    
                    //Other type buttons are controlled by "select all" button
                    for view in views {
                        if let typeButton = view as? ToggleButton {
                            if(typeButton.tag !=
                                UIControlTag.NOT_LIMITED_BUTTON_TAG){
                                selectAllButton!.addStateListener(ToggleButtonListenr(target: typeButton))
                            }
                            
                            typeButton.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
                        }
                    }
                }
            }
        }

        
        func buttonClicked(sender: UIButton) {
            if let toogleButton = sender as? ToggleButton {
                toogleButton.toggleButtonState()
                
                //toggle off the select all button if any type is selected
                if(toogleButton.tag != UIControlTag.NOT_LIMITED_BUTTON_TAG
                    && toogleButton.getToggleState()==true) {
                        selectAllButton?.setToggleState(false)
                }
            }
        }
        
        @IBOutlet weak var sizeMax: UITextField!
        @IBOutlet weak var sizeMin: UITextField!
        @IBOutlet weak var priceMax: UITextField!
        @IBOutlet weak var priceMin: UITextField!
        @IBOutlet weak var searchBar: UISearchBar! {
            didSet {
                searchBar.delegate = self
            }
        }
        @IBOutlet weak var searchButton: UIButton! {
            didSet {
                searchButton.addTarget(self, action: "onSearchButtonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
        
        //The button should not be private
        func onSearchButtonClicked(sender: UIButton) {
            NSLog("onSearchButtonClicked: %@", self)
            
            //present the view modally (hide the tabbar)
            performSegueWithIdentifier("showSearchResult", sender: nil)
        }
        
        // MARK: - UISearchBarDelegate
        
        func searchBarSearchButtonClicked(searchBar: UISearchBar) {
            NSLog("searchBarSearchButtonClicked: %@", self)
            searchBar.endEditing(true)
        }
        
        // MARK: - UI Configuration
        private func configureButton() {
            
            let color = UIColor(red: 0x00/255, green: 0x72/255, blue: 0xE3/255, alpha: 1)
            
            searchButton.layer.borderWidth = 2
            searchButton.layer.borderColor = color.CGColor
            searchButton.tintColor = color
            searchButton.backgroundColor = color
            
            //let edgeInsets:UIEdgeInsets = UIEdgeInsets(top:4,left: 4,bottom: 4,right: 4)
            
            //let buttonImg = UIImage(named: "purple_button")!
            
            //let buttonInsetsImg:UIImage = buttonImg.imageWithAlignmentRectInsets(edgeInsets)
            
            //searchButton.setBackgroundImage(buttonInsetsImg, forState: UIControlState.Normal)
        }
        
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            
            NSLog("prepareForSegue: %@", self)
            
            if let identifier = segue.identifier{
                switch identifier{
                case "showSearchResult":
                    
                    if let srtvc = segue.destinationViewController as? SearchResultTableViewController {
                        
                        var searchCriteria = SearchCriteria()
                            
                        searchCriteria.keyword = searchBar.text
                        
                        let priceMin = Int(self.priceMin.text!) ?? 0
                        let priceMax = Int(self.priceMax.text!) ?? 0
                        
                        searchCriteria.criteriaPrice = (priceMin, priceMax)
                        
                        let sizeMin = Int(self.sizeMin.text!) ?? 0
                        let sizeMax = Int(self.sizeMax.text!) ?? 0
                        
                        searchCriteria.criteriaSize = (sizeMin, sizeMax)
                        
                        
                        var typeList = [Int]()
                        
                        if(selectAllButton!.getToggleState() == false) {
                            let views = typeButtonContainer.subviews
                            
                            //Other type buttons are controlled by "select all" button
                            for view in views {
                                if let typeButton = view as? ToggleButton {
                                    if(typeButton.tag !=
                                        UIControlTag.NOT_LIMITED_BUTTON_TAG){
                                            if(typeButton.getToggleState()) {
                                                switch typeButton.tag {
                                                case 1:
                                                    typeList.append(CriteriaConst.PrimaryType.FULL_FLOOR)
                                                case 2:
                                                    typeList.append(CriteriaConst.PrimaryType.SUITE_INDEPENDENT)
                                                case 3:
                                                    typeList.append(CriteriaConst.PrimaryType.SUITE_COMMON_AREA)
                                                case 4:
                                                    typeList.append(CriteriaConst.PrimaryType.ROOM_NO_TOILET)
                                                case 5:
                                                    typeList.append(CriteriaConst.PrimaryType.HOME_OFFICE)
                                                default: break
                                                }
                                            }
                                    }
                                }
                            }
                            
                            if(typeList.count > 0) {
                                searchCriteria.criteriaTypes = typeList
                            }
                        }
                        
                        srtvc.searchCriteria = searchCriteria
                    }
                default: break
                }
            }
        }
        
        // MARK: - View Life Cycle
        override func viewDidLoad() {
            super.viewDidLoad()
            
            NSLog("viewDidLoad: %@", self)
            self.configureButton()
            
            //tableView.backgroundView = nil
            tableView.backgroundColor = UIColor.whiteColor()
            
            
            //Configure cell height
            tableView.estimatedRowHeight = tableView.rowHeight
            tableView.rowHeight = UITableViewAutomaticDimension
            
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false
            
            // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
            // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        }
        
        override func viewDidAppear(animated: Bool) {
            super.viewDidAppear(animated)
            NSLog("viewDidAppear: %@", self)
        }
        
        override func viewDidDisappear(animated: Bool) {
            super.viewDidDisappear(animated)
            NSLog("viewDidDisappear: %@", self)
        }
        
        // MARK: - Table view data source
        
        //    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //        // #warning Incomplete implementation, return the number of sections
        //        return 0
        //    }
        
        //    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        // #warning Incomplete implementation, return the number of rows
        //        return 0
        //    }
        
        /*
        override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        
        // Configure the cell...
        
        return cell
        }
        */
        
        /*
        // Override to support conditional editing of the table view.
        override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
        }
        */
        
        /*
        // Override to support editing the table view.
        override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
        // Delete the row from the data source
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        }
        */
        
        /*
        // Override to support rearranging the table view.
        override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        
        }
        */
        
        /*
        // Override to support conditional rearranging of the table view.
        override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
        }
        */
        
        /*
        // MARK: - Navigation
        
        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        }
        */
        
    }
