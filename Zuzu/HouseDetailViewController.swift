//
//  HouseDetailViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit

class HouseDetailViewController: UIViewController {
    
    var houseItem:HouseItem? {
        didSet {
            fetchHouseDetail(houseItem!)
        }
    }
    
    var houseItemDetail: AnyObject?
    
    @IBOutlet weak var tableView: UITableView!
    
    struct Const {
        static let SECTION_NUM:Int = 1
    }
    
    enum CellIdentifier: String {
        case HouseDetailTitleCell = "houseDetailTitleCell"
        case RightDetailCell = "rightDetailCell"
        case AddressCell = "addressCell"
        case ExpandableHeaderCell = "expandableHeaderCell"
        case ExpandableContentCell = "expandableContentCell"
    }
    
    
    struct CellInfo {
        let cellIdentifier:CellIdentifier
        var cellHeight:CGFloat
        let handler: (UITableViewCell) -> ()
    }
    
    let cellIdentifier = "houseDetailTitleCell"
    
    var tableRows:[Int: CellInfo]!
    
    private func fetchHouseDetail(houseItem: HouseItem) {
        HouseDataRequester.getInstance().searchById(houseItem.id) { (result, error) -> Void in
            if let error = error {
                NSLog("Cannot get remote data %@", error.localizedDescription)
                return
            }
            
            if let result = result {
                if let item = result.array?.first {
                    self.houseItemDetail = item
                }
            }
        }
    }
    
    private func configureTableView() {
        //Configure cell height
        tableView.estimatedRowHeight = 213//tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //Configure table DataSource & Delegate
        tableView.dataSource = self
        tableView.delegate = self
        
        //Remove extra cells when the table height is smaller than the screen
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableRows = [
            0:CellInfo(cellIdentifier: .HouseDetailTitleCell,cellHeight: 213, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailTitleViewCell {
                    
                    let placeholderImg = UIImage(named: "house_img")
                    
                    if let imgString = self.houseItem?.imgList?.first,
                    let imgUrl = NSURL(string: imgString){

                        cell.titleImage.af_setImageWithURL(imgUrl, placeholderImage: placeholderImg, filter: nil, imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                            NSLog("Img loading done, status = \(response)")
                        }
                        
                    }
                }
            }),
            1:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                        cell.leftInfoText.text = "\(houseItem.price) 月/元"
                        cell.rightInfoText.text = "\(houseItem.size) 坪"
                    }
                }
            }),
            2:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    if let houseItem = self.houseItem {
                    cell.leftInfoText.text = "西門鋼骨"
                    cell.rightInfoText.text = "\(houseItem.houseType) / \(houseItem.purposeType)"
                    }
                }
            }),
            3:CellInfo(cellIdentifier: .RightDetailCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailBasicInfoCell {
                    cell.leftInfoText.text = "樓層: 2/15"
                    cell.rightInfoText.text = "3房2廳"
                }
            }),
            4:CellInfo(cellIdentifier: .AddressCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailAddressCell {
                    if let houseItem = self.houseItem {
                    cell.addressLabel.text = houseItem.addr
                    }
                }
            }),
            5:CellInfo(cellIdentifier: .ExpandableHeaderCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableHeaderCell {
                    
                }
            }),
            6:CellInfo(cellIdentifier: .ExpandableContentCell, cellHeight: 44, handler: { (cell) -> () in
                if let cell = cell as? HouseDetailExpandableContentCell {
                }
            })
        ]
        
        configureTableView()
        
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


extension HouseDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Const.SECTION_NUM
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableRows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if var cellInfo = tableRows[indexPath.row] {
            
            let cell = tableView.dequeueReusableCellWithIdentifier(cellInfo.cellIdentifier.rawValue, forIndexPath: indexPath)
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            
            cellInfo.handler(cell)
            
            if let cell = cell as? HouseDetailTitleViewCell {
                cellInfo.cellHeight = cell.titleImage.frame.height
                
                NSLog("Cell Size: %f, %f", cell.titleImage.frame.size.width, cell.titleImage.frame.size.height)
            }
            
            tableRows[indexPath.row] = cellInfo
            
            NSLog("- Cell Instance [%p] Prepare Cell For Row[\(indexPath.row)]", cell)
            
            return cell
        }
        
        assert(false)
        
    }
    
}
