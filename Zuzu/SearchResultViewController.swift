//
//  SearchResultViewController.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/27.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit

class SearchResultViewController: UIViewController {

    // MARK: - Member Fields
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView! {
        didSet{
            stopSpinner()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var debugTextStr: String = ""
    private let searchItemService : SearchItemService = SearchItemService.getInstance()
    private let dataSource: HouseItemTableDataSource = HouseItemTableDataSource()
    private var lastContentOffset:CGFloat = 0
    private var lastDirection: ScrollDirection = ScrollDirection.ScrollDirectionNone
    private var ignoreScroll = false
    
    var searchCriteria: SearchCriteria?
    
    // MARK: - Private Utils
    
    private func alertSavingCurrentSearchSuccess() {
        // Initialize Alert View
        
        let alertView = UIAlertView(
            title: "儲存常用搜尋條件",
            message: "當前的搜尋條件已經被儲存!",
            delegate: self,
            cancelButtonTitle: "知道了")
        
        // Configure Alert View
        alertView.tag = 2
        
        // Show Alert View
        alertView.show()
        
        // Delay the dismissal
        self.runOnMainThreadAfter(2.0) {
            alertView.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    private func alertSavingCurrentSearchFailure() {
        // Initialize Alert View
        
        let alertView = UIAlertView(
            title: "常用搜尋條件已滿",
            message: "常用搜尋條件儲存已達上限，請先刪除不需要的條件",
            delegate: self,
            cancelButtonTitle: "知道了")
        
        // Configure Alert View
        alertView.tag = 2
        
        // Show Alert View
        alertView.show()
        
        // Delay the dismissal
        self.runOnMainThreadAfter(2.0) {
            alertView.dismissWithClickedButtonIndex(-1, animated: true)
        }
    }
    
    private func startSpinner() {
        loadingSpinner.startAnimating()
    }
    
    private func stopSpinner() {
        loadingSpinner.stopAnimating()
    }

    private func loadHouseListPage(pageNo: Int) {
        
        if(pageNo > dataSource.estimatedNumberOfPages){
            NSLog("loadHouseListPage: Exceeding max number of pages [\(dataSource.estimatedNumberOfPages)]")
            return
        }
        
        startSpinner()
        dataSource.loadDataForPage(pageNo)
        
    }
    
    private func onDataLoaded(dataSource: HouseItemTableDataSource, pageNo: Int, error: NSError?) -> Void {
        
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
        
        NSLog("%@ onDataLoaded: Total #Item in Table: \(self.dataSource.getSize())", self)
        
        //self.debugTextStr = self.dataSource.debugStr
    }
    
    // MARK: - Control Action Handlers
    @IBAction func onSaveSearchButtonClicked(sender: UIBarButtonItem) {
        
        if let criteria = self.searchCriteria {
            
            do{
                try searchItemService.addNewSearchItem(SearchItem(criteria: criteria, type: .SavedSearch))
                
                alertSavingCurrentSearchSuccess()
                
            } catch {
                
                alertSavingCurrentSearchFailure()
            }
            
        }
    }
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        super.viewDidLoad()
        
        NSLog("%@ [[viewDidLoad]]", self)
        
        //Configure cell height
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        
        //Configure table DataSource & Delegate
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        //Configure remote data source
        self.dataSource.setDataLoadedHandler(onDataLoaded)
        self.dataSource.criteria = searchCriteria
        
        self.startSpinner()
        self.dataSource.initData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("%@ [[viewWillDisappear]]", self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation
    
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
}

extension SearchResultViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        NSLog("%@ tableView Count: \(dataSource.getSize())", self)
        
        return dataSource.getSize()
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("houseItemCell", forIndexPath: indexPath) as! SearchResultTableViewCell
        
        NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
        
        
        cell.parentTableView = tableView
        cell.indexPath = indexPath
        
        cell.houseItem = dataSource.getItemForRow(indexPath.row)
        return cell
    }

}

extension SearchResultViewController: UIScrollViewDelegate {
    
    // MARK: - Scroll View Delegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        //NSLog("==scrollViewDidEndDecelerating==")
        //NSLog("Content Height: \(scrollView.contentSize.height)")
        //NSLog("Content Y-offset: \(scrollView.contentOffset.y)")
        //NSLog("ScrollView Height: \(scrollView.frame.size.height)")
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = floor(scrollView.contentSize.height - scrollView.frame.size.height)
        let currentContentOffset = floor(scrollView.contentOffset.y)
        
        if (currentContentOffset >= yOffsetForBottom){
            NSLog("%@ Bounced, Scrolled To Bottom", self)
            
            let nextPage = self.dataSource.currentPage + 1
            
            loadHouseListPage(nextPage)
            
        }else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
            NSLog("%@ Bounced, Scrolled To Top", self)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
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
        
        self.lastContentOffset = scrollView.contentOffset.y;
        
        
        
        let yOffsetForTop:CGFloat = 0
        let yOffsetForBottom:CGFloat = (scrollView.contentSize.height - self.tableView.rowHeight) - scrollView.frame.size.height
        
        if(yOffsetForBottom >= 0) {
            if (scrollView.contentOffset.y >= yOffsetForBottom){
                NSLog("%@ Scrolled To Bottom", self)
                
                let nextPage = self.dataSource.currentPage + 1
                
                if(nextPage <= dataSource.estimatedNumberOfPages){
                    startSpinner()
                    return
                }
                
            } else if(scrollView.contentOffset.y + scrollView.contentInset.top <= yOffsetForTop) {
                //NSLog("Scrolled To Top")
            }
        }
    }

    
}

extension SearchResultViewController: UIAdaptivePresentationControllerDelegate {
    
    //Need to figure out the use of this...
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}

extension SearchResultViewController: UIAlertViewDelegate {
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        NSLog("Alert Dialog Button [%d] Clicked", buttonIndex)
    }
    
}