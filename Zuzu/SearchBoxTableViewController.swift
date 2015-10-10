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
    
    class SearchBoxTableViewController: UITableViewController, UISearchBarDelegate,
    UIPickerViewDelegate, UIPickerViewDataSource {
        
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
                            
                            typeButton.addTarget(self, action: "onButtonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
                        }
                    }
                }
            }
        }
        
        @IBOutlet weak var sizeLabel: UILabel!
        @IBOutlet weak var priceLabel: UILabel!
        @IBOutlet weak var sizePicker: UIPickerView!
        @IBOutlet weak var pricePicker: UIPickerView!
        
        
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
        
        // MARK: - UI Control Event Handler
        
        //The UI control event handler Should not be private
        func onButtonClicked(sender: UIButton) {
            if let toogleButton = sender as? ToggleButton {
                toogleButton.toggleButtonState()
                
                //toggle off the select all button if any type is selected
                if(toogleButton.tag != UIControlTag.NOT_LIMITED_BUTTON_TAG
                    && toogleButton.getToggleState()==true) {
                        selectAllButton?.setToggleState(false)
                }
            }
        }
        
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
        
        // MARK: - Picker Data Source
        let sizeItems:[[(label:String, value:Int)]] =
        [
            [("不限",CriteriaConst.Bound.LOWER_ANY), ("10",10), ("20",20), ("30",30), ("40",40), ("50",50)]
            ,
            [("不限",CriteriaConst.Bound.UPPER_ANY), ("10",10), ("20",20), ("30",30), ("40",40), ("50",50)]
        ]
        
        let priceItems:[[(label:String, value:Int)]] =
        [
            [("不限",CriteriaConst.Bound.LOWER_ANY), ("5000",5000), ("10000",10000), ("15000",15000), ("20000",20000), ("25000",25000), ("30000",30000), ("35000",35000), ("40000",40000)]
            ,
            [("不限",CriteriaConst.Bound.UPPER_ANY), ("5000",5000), ("10000",10000), ("15000",15000), ("20000",20000), ("25000",25000), ("30000",30000), ("35000",35000), ("40000",40000)]
        ]
        
        private func configurePricePicker() {
            
            sizePicker.dataSource = self
            sizePicker.delegate = self
            
            pricePicker.dataSource = self
            pricePicker.delegate = self
        }
        
        func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
            
            switch(pickerView) {
            case sizePicker:
                return sizeItems.count
            case pricePicker:
                return priceItems.count
            default:
                return 0
            }
        }
        
        func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            
            switch(pickerView) {
            case sizePicker:
                return sizeItems[component][row].label
            case pricePicker:
                return priceItems[component][row].label
            default:
                return ""
            }
        }
        
        func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            
            switch(pickerView) {
            case sizePicker:
                return sizeItems[component].count
            case pricePicker:
                return priceItems[component].count
            default:
                return 0
            }
        }
        
        func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            
            switch(pickerView) {
            case sizePicker:
                var sizeFrom:(component:Int, row:Int)
                var sizeTo:(component:Int, row:Int)
                
                if(component == sizeItems.startIndex) {
                    sizeFrom = (component, row)
                    sizeTo = ((sizeItems.endIndex - 1), sizePicker.selectedRowInComponent(sizeItems.endIndex - 1))
                }else if(component == sizeItems.endIndex-1) {
                    sizeFrom = (component: (sizeItems.startIndex), row: sizePicker.selectedRowInComponent(sizeItems.startIndex))
                    sizeTo = (component: component, row: row)
                }else {
                    return
                }
                
                sizeLabel.text =
                    sizeItems[sizeFrom.component][sizeFrom.row].label +
                    " - " +
                    sizeItems[sizeTo.component][sizeTo.row].label
                
            case pricePicker:
                
                var priceFrom:(component: Int, row: Int)
                var priceTo:(component: Int, row: Int)
                
                if(component == priceItems.startIndex) {
                    priceFrom = (component, row)
                    priceTo = (component: (priceItems.endIndex - 1), row: pricePicker.selectedRowInComponent(priceItems.endIndex - 1))
                }else if(component == priceItems.endIndex-1) {
                    priceFrom = ((priceItems.startIndex), pricePicker.selectedRowInComponent(priceItems.startIndex))
                    priceTo = (component: component, row: row)
                }else {
                    return
                }
                
                priceLabel.text =
                    priceItems[priceFrom.component][priceFrom.row].label +
                    " - " +
                    priceItems[priceTo.component][priceTo.row].label
                
            default: break
            }
        }
        
        // MARK: - Navigation
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            
            NSLog("prepareForSegue: %@", self)
            
            if let identifier = segue.identifier{
                switch identifier{
                case "showSearchResult":
                    
                    if let srtvc = segue.destinationViewController as? SearchResultTableViewController {
                        
                        var searchCriteria = SearchCriteria()
                        
                        searchCriteria.keyword = searchBar.text
                        
                        let priceMinRow =
                        pricePicker.selectedRowInComponent(priceItems.startIndex)
                        let priceMaxRow =
                        pricePicker.selectedRowInComponent(priceItems.endIndex - 1)
                        
                        let priceMin =
                        priceItems[priceItems.startIndex][priceMinRow].value
                        let priceMax =
                        priceItems[priceItems.endIndex - 1][priceMaxRow].value
                        
                        if(priceMin != CriteriaConst.Bound.LOWER_ANY ||  priceMax != CriteriaConst.Bound.UPPER_ANY) {
                            searchCriteria.criteriaPrice = (priceMin, priceMax)
                        }
                        
                        let sizeMinRow =
                        sizePicker.selectedRowInComponent(sizeItems.startIndex)
                        let sizeMaxRow =
                        sizePicker.selectedRowInComponent(sizeItems.endIndex - 1)
                        
                        let sizeMin =
                        sizeItems[sizeItems.startIndex][sizeMinRow].value
                        let sizeMax =
                        sizeItems[sizeItems.endIndex - 1][sizeMaxRow].value
                        
                        if(sizeMin != CriteriaConst.Bound.LOWER_ANY ||  sizeMax != CriteriaConst.Bound.UPPER_ANY) {
                            searchCriteria.criteriaSize = (sizeMin, sizeMax)
                        }
                        
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
            tableView.delegate = self
            
            //Confugure Price Picker
            self.configurePricePicker()
            
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
        
        // MARK: - Table Delegate
        override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
            var picker:UIPickerView?
            
            switch(indexPath.row) {
            case 2:
                picker = pricePicker
                if(hiddenCells.contains(3)) {
                    hiddenCells.remove(3)
                } else {
                    hiddenCells.insert(3)
                }
                
            case 4:
                picker = sizePicker
                if(hiddenCells.contains(5)) {
                    hiddenCells.remove(5)
                } else {
                    hiddenCells.insert(5)
                }
                
            default: break
            }
            
            if(picker != nil) {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            
        }
        
        var hiddenCells:Set = [3, 5]
        
        override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            
            NSLog("heightForRowAtIndexPath\(indexPath)")
            
            if(hiddenCells.contains(indexPath.row)) {
                return 0
            } else {
                if (indexPath.row == 3) {
                    return pricePicker.intrinsicContentSize().height
                }
                if (indexPath.row == 5) {
                    return sizePicker.intrinsicContentSize().height
                }
            }
            
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
            
            /* Use Autolayout decided size
            let cellView = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
            
            return cellView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            */
            
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
