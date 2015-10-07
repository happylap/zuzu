//
//  SearchResultTableViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

struct Const {
    static let SECTION_NUM:Int = 1
}

struct SearchCriteria {
    var keyword:String?
    var criteriaPrice:(Int, Int)?
    var criteriaSize:(Int, Int)?
    var criteriaTypes: [Int]?
}

enum ScrollDirection {
    case ScrollDirectionNone
    case ScrollDirectionRight
    case ScrollDirectionLeft
    case ScrollDirectionUp
    case ScrollDirectionDown
    case ScrollDirectionCrazy
}

class SearchResultTableViewController: UITableViewController, UIAdaptivePresentationControllerDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView! {
        didSet{
            stopSpinner()
        }
    }
    
    private func startSpinner() {
        loadingSpinner.startAnimating()
    }
    
    private func stopSpinner() {
        loadingSpinner.stopAnimating()
    }
    
    @IBOutlet weak var debugText: UITextField!
    
    var debugTextStr: String = ""
    
    //private static let houseDataReq: HouseDataRequester = HouseDataRequester.getInstance()
    
    private let dataSource: PersistentTableDataSource = PersistentTableDataSource(cachablePageSize: 3)
    
    //    private func getHouseDataReq() ->  HouseDataRequester{
    //        return SearchResultTableViewController.houseDataReq
    //    }
    
    //var currentPage = 1
    
    var searchCriteria: SearchCriteria?
    
    var lastContentOffset:CGFloat = 0
    var lastDirection: ScrollDirection = ScrollDirection.ScrollDirectionNone
    var ignoreScroll = false
    
    
    private func onDataLoaded(dataSource: PersistentTableDataSource, pageNo: Int, error: NSError?) -> Void {
        
        if(error != nil) {
            // Initialize Alert View
            
            let alertView = UIAlertView(
                title: NSLocalizedString("unable_to_get_data.alert.title", comment: ""),
                message: NSLocalizedString("unable_to_get_data.alert.msg", comment: ""),
                delegate: self,
                cancelButtonTitle: NSLocalizedString("unable_to_get_data.alert.button.ok", comment: ""))
            
            // Configure Alert View
            alertView.tag = 1
            
            
            // Show Alert View
            alertView.show()
        }
        
        self.stopSpinner()
        self.tableView.reloadData()
        
        NSLog("%@ onDataLoaded: Total #Item in Table: \(self.dataSource.getItemSize())", self)
        
        self.debugTextStr = self.dataSource.debugStr
        
        //        var row = 0
        //
        //        if pageNo <= 1 {
        //            row = 0
        //        } else {
        //            if (pageNo <= dataSource.cachablePageSize) {
        //                row = getLastRowForPage(pageNo-1)-1
        //            }  else {
        //                let diff = pageNo - dataSource.cachablePageSize
        //                row = getLastRowForPage(pageNo-1)-1 - diff * LazyTableDataSource.Const.PAGE_SIZE
        //            }
        //        }
        // let indexPath = NSIndexPath(forRow: row, inSection: 0)
        
        //self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
    }
    
    //    private func getLastRowForPage(pageNo:Int) -> Int {
    //
    //        return pageNo * LazyTableDataSource.Const.PAGE_SIZE
    //
    //    }
    
    //** MARK: - Controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("%@ [[viewDidLoad]]", self)
        
        //Configure cell height
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        
        self.dataSource.setDataLoadedHandler(onDataLoaded)
        self.dataSource.criteria = searchCriteria
        self.dataSource.initData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("%@ [[viewWillDisappear]]", self)
        //clear saved data
        self.dataSource.clearSavedData()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //** MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(dataSource.getItemSize())", self)
        
        return dataSource.getItemSize()
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("houseItemCell", forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)

        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        cell.houseItem = dataSource.getItemForRow(indexPath.row)
        return cell
    }
    
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
    
    
    //** MARK: - Scroll View Delegate
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //NSLog("==scrollViewDidEndDecelerating==")
        //NSLog("Content Height: \(scrollView.contentSize.height)")
        //NSLog("Content Y-offset: \(scrollView.contentOffset.y)")
        //NSLog("ScrollView Height: \(scrollView.frame.size.height)")
        //
        //        if(scrollView.contentSize.height < scrollView.frame.size.height){
        //            if(self.lastDirection == .ScrollDirectionDown) {//next
        //
        //            }else if(self.lastDirection == .ScrollDirectionUp) {//previous
        //                let previousPage = self.dataSource.getCachedPageBound().0 - 1
        //                if(previousPage >= 1) {
        //                    loadHouseListPage(previousPage)
        //                }
        //            }
        //            return
        //        }
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = scrollView.contentSize.height - scrollView.frame.size.height
        
        if (scrollView.contentOffset.y >= yOffsetForBottom){
            NSLog("%@ Bounced, Scrolled To Bottom", self)
            
            let nextPage = self.dataSource.getCachedPageBound().max + 1
            
            if(dataSource.checkWithinCacheForPage(nextPage)){
                self.stopSpinner()
            } else{
                
                if(!dataSource.isDataLoadingInProgress()){
                    loadHouseListPage(nextPage)
                } else {
                    NSLog("%@ Ignore Duplicate Page Request", self)
                }
            }
            
            //if let estimatedTotalPage = dataSource.getEstimatedPageSize(){
            //    NSLog("estimatedTotalPage: \(estimatedTotalPage)")
            //
            //    if(nextPage <= Int(estimatedTotalPage)) {
            //        loadHouseListPage(nextPage)
            //    } else {
            //        self.stopSpinner()
            //    }
            //}
        }else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
            NSLog("%@ Bounced, Scrolled To Top", self)
            
            let previousPage = self.dataSource.getCachedPageBound().min - 1
            
            if(previousPage < 1 || dataSource.checkWithinCacheForPage(previousPage)){
                self.stopSpinner()
            } else{
                if(!dataSource.isDataLoadingInProgress()){
                    loadHouseListPage(previousPage)
                } else {
                    NSLog("%@ Ignore Duplicate Page Request", self)
                }
            }
            
            //if(previousPage >= 1) {
            //  loadHouseListPage(previousPage)
            //} else {
            //  self.stopSpinner()
            //}
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //NSLog("==scrollViewDidScroll==")
        //NSLog("Content Height: \(scrollView.contentSize.height)")
        //NSLog("Content Y-offset: \(scrollView.contentOffset.y)")
        //NSLog("ScrollView Height: \(scrollView.frame.size.height)")
        
        //Check for scroll direction
        if (self.lastContentOffset > scrollView.contentOffset.y){
            self.lastDirection = .ScrollDirectionDown
        } else if (self.lastContentOffset < scrollView.contentOffset.y){
            self.lastDirection = .ScrollDirectionUp
        }
        
        // Try to preload the next page to be seen.
        // This code is not reliable since the visible indexPaths will be skipped when the table is scrilled at a very fast speed 
        tryPreloadPersistentPage(self.lastDirection)
        
        self.lastContentOffset = scrollView.contentOffset.y;
        
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = (scrollView.contentSize.height - self.tableView.rowHeight) - scrollView.frame.size.height
        
        if(yOffsetForBottom >= 0) {
            if (scrollView.contentOffset.y >= yOffsetForBottom){
                NSLog("%@ Scrolled To Bottom", self)
                startSpinner()
            } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
                //NSLog("Scrolled To Top")
            }
        }
        
        //Check if need to load persistent data
        //        if let paths = tableView.indexPathsForVisibleRows {
        //            NSLog("Visible Cell\n")
        //            for path in paths {
        //                NSLog("Cell: \(path.row)")
        //            }
        //        }
    }
    
    //** MARK: - Util Functions
    
    private func tryPreloadPersistentPage(direction:ScrollDirection) {
        
        if let paths = tableView.indexPathsForVisibleRows {
            
            if(paths.count <= 0) {
                return
            }
            
            switch direction{
            case ScrollDirection.ScrollDirectionUp:
                let row = paths[paths.startIndex].row
                let nextPage = PersistentTableDataSource.convertFromRowToPageNo(row) + 1

                if(dataSource.checkWithinStoreForPage(nextPage)) {
                    NSLog("== Preload Next Page[\(nextPage)] ==")
                    dataSource.loadDataForPage(nextPage)
                }
            case ScrollDirection.ScrollDirectionDown:
                let row = paths[paths.endIndex-1].row
                let prevPage = PersistentTableDataSource.convertFromRowToPageNo(row) - 1

                if(dataSource.checkWithinStoreForPage(prevPage)) {
                    NSLog("== Preload Previous Page[\(prevPage)] ==")
                    dataSource.loadDataForPage(prevPage)
                }
            default: break
                
            }
        }
    }
    
    private func loadHouseListPage(pageNo: Int) {
        
        dataSource.loadDataForPage(pageNo)
        
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            switch identifier{
            case "showDebugInfo":
                let debugVc = segue.destinationViewController as UIViewController
                
                if let pVc = debugVc.presentationController {
                    pVc.delegate = self
                }
                
                let view:[UIView] = debugVc.view.subviews
                
                if let textView = view[0] as? UITextView {
                    textView.text = self.debugTextStr
                }
                
            default: break
            }
        }
    }
    
    //Need to figure out the use of this...
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}
