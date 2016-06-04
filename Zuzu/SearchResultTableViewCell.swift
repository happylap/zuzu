//
//  SearchResultTableViewCell.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/9/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//
import Alamofire
import AlamofireImage
import UIKit
import Foundation
import Dollar

private let Log = Logger.defaultLogger

class SearchResultTableViewCell: UITableViewCell {
    
    static let labelMaker:LabelMaker! = DisplayLabelMakerFactory.createDisplayLabelMaker(.House)
    
    private let placeholderImg = UIImage(named: "house_img")
    
    private let collectedImg = UIImage(named: "heart_pink")
    
    private var isCollected = false
    
    private var collectionButtonTouchEventCallback: CollectionEventCallback? = nil
    
    enum CollectionEvent: Int {
        case ADD = 1
        case DELETE = 2
    }
    
    typealias CollectionEventCallback = (event: CollectionEvent, houseItem: HouseItem)-> Void
    
    enum HouseFlag: Int {
        case OFF_SHELF = 1  // 已下架
        case PRICE_CUT = 2  // 已降價
        case PET       = 3  // 可養寵物
        case MANY_IMG  = 4  // 多張圖
    }
    
    let titleBackground = CAGradientLayer()
    
    let infoBackground = CALayer()
    
    @IBOutlet weak var houseImg: UIImageView!
    @IBOutlet weak var houseTitle: UILabel!
    @IBOutlet weak var houseTitleForCollection: UILabel!
    @IBOutlet weak var houseTypeAndUsage: UILabel!
    @IBOutlet weak var houseSize: UILabel!
    @IBOutlet weak var houseAddr: UILabel!
    @IBOutlet weak var housePrice: UILabel!
    @IBOutlet weak var addToCollectionButton: UIImageView!
    @IBOutlet weak var prefixedButton: UIImageView!
    @IBOutlet weak var contactedView: UIView!
    
    @IBOutlet weak var houseSourceBox: UIView! {
        didSet {
            houseSourceBox.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var houseSourceLabel: UILabel!
    @IBOutlet weak var offShelfView: UIView!
    @IBOutlet weak var offShelfImg: UIImageView!
    @IBOutlet weak var offShelfLabel: UILabel!
    
    weak var parentTableView: UITableView!
    
    var indexPath: NSIndexPath!
    
    var houseItem: HouseItem? {
        didSet {
            updateUI()
        }
    }
    
    var houseFlags: [HouseFlag]? {
        didSet {
            tagHouseFlag()
        }
    }
    
    var houseItemForCollection: CollectionHouseItem? {
        didSet {
            updateUIForCollection()
        }
    }
    
    // MARK: - Private Utils
    
    private func getTypeString(type: Int) -> String? {
        return SearchResultTableViewCell.labelMaker.fromCodeForField("house_type", code: type)
    }
    
    private func getPurposeString(purpose:Int) -> String? {
        return SearchResultTableViewCell.labelMaker.fromCodeForField("purpose_type", code: purpose)
    }
    
    private func processSourceString(label:UILabel, source:Int) {
        var labelColor: UIColor?
        var sourceText: String?
        
        // Get source label
        sourceText = SearchResultTableViewCell.labelMaker.fromCodeForField("source", code: source)
        
        // Determin label color
        switch source {
        case 1:
            labelColor = UIColor.colorWithRGB(0xFF9500)
        case 2:
            labelColor = UIColor.colorWithRGB(0x55EFCB)
        case 3:
            labelColor = UIColor.colorWithRGB(0xFFCD02)
        case 4:
            labelColor = UIColor.colorWithRGB(0xCCFF66)
        default:
            labelColor = UIColor.colorWithRGB(0xFFFFFF)
            break
        }
        
        if let sourceText = sourceText, let labelColor = labelColor {
            houseSourceBox.layer.borderColor = labelColor.CGColor
            label.textColor = labelColor
            label.text = sourceText
            
        } else {
            assert(false, " Cannot find source label for: \(source)")
            houseSourceBox.layer.borderColor = labelColor?.CGColor
            label.textColor = labelColor
            label.text = "其他"
        }
    }
    
    private func updateUI() {
        
        // load new information (if any)
        if let houseItem = self.houseItem {
            houseTitle.hidden = false
            houseTitle.text = houseItem.title
            houseAddr.text = houseItem.addr
            
            if let houseTypeStr = self.getTypeString(houseItem.houseType) {
                if let purposeTypeStr = self.getPurposeString(houseItem.purposeType) {
                    houseTypeAndUsage.text = "\(houseTypeStr)/\(purposeTypeStr)"
                } else {
                    houseTypeAndUsage.text = "\(houseTypeStr)"
                }
            } else {
                if let purposeTypeStr = self.getPurposeString(houseItem.purposeType) {
                    houseTypeAndUsage.text = "\(purposeTypeStr)"
                }
            }
            
            processSourceString(houseSourceLabel, source: houseItem.source)
            
            /// Round the size to the second place
            let multiplier:Float = pow(10.0, 2)
            houseSize.text = "\(round(houseItem.size * multiplier)/multiplier) 坪"
            
            housePrice.text = String(houseItem.price)
            houseImg.image = placeholderImg
            
            if let imageURLList = houseItem.imgList {
                if let firstURL = NSURL(string: imageURLList[0]) {
                    
                    let size = houseImg.frame.size
                    
                    Log.debug("Start> Loading Img for Row[\(indexPath.row)]")
                    
                    houseImg.af_setImageWithURL(firstURL, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .None)
                    { (request, response, result) -> Void in
                        Log.debug("End> Loading Img for row = [\(self.indexPath.row)], url = \(firstURL), status = \(response?.statusCode)")
                    }
                }
            }
            
        }
    }
    
    private func updateUIForCollection() {
        
        // load new information (if any)
        if let collectionHouseItem = self.houseItemForCollection {
            self.addToCollectionButton.hidden = !FeatureOption.Collection.enableNote
            
            self.houseTitleForCollection.hidden = false
            self.prefixedButton.hidden = false
            self.contactedView.hidden = !(collectionHouseItem.contacted)
            
            if collectionHouseItem.contacted == true {
                prefixedButton.image = UIImage(named: "checked_green")
            } else {
                prefixedButton.image = UIImage(named: "uncheck")
            }
            self.prefixedButton.userInteractionEnabled = true
            self.prefixedButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SearchResultTableViewCell.onContactTouched(_:))))
            
            
            self.addToCollectionButton.image = UIImage(named: "note_n")
            
            self.houseTitleForCollection.text = collectionHouseItem.title
            //self.houseTitle.text = "    \(house.title)"
            self.housePrice.text = collectionHouseItem.price.description
            self.houseAddr.text = collectionHouseItem.addr
            self.houseSize.text = "\(collectionHouseItem.size) 坪"
            
            let houseTypeStr = self.getTypeString(Int(collectionHouseItem.houseType)) ?? ""
            let purposeTypeStr = self.getPurposeString(Int(collectionHouseItem.purposeType)) ?? ""
            self.houseTypeAndUsage.text = "\(houseTypeStr)/\(purposeTypeStr)"
            
            processSourceString(houseSourceLabel, source: Int(collectionHouseItem.source))
            
            self.houseImg.image = placeholderImg
            
            if collectionHouseItem.img?.count > 0 {
                if let imgUrl = collectionHouseItem.img?[0] {
                    let size = self.houseImg.frame.size
                    
                    self.houseImg.af_setImageWithURL(NSURL(string: imgUrl)!, placeholderImage: placeholderImg, filter: AspectScaledToFillSizeFilter(size: size), imageTransition: .CrossDissolve(0.2)) { (request, response, result) -> Void in
                        
                        Log.debug("End> Loading Img for Row = [\(self.indexPath.row)], status = \(response?.statusCode)")
                    }
                }
            }
        }
    }
    
    private func tagHouseFlag() {
        
        if let flags = self.houseFlags{
            if flags.count > 0 {
                var majorFlag: HouseFlag = flags[0]
                
                for flag in flags {
                    if majorFlag.rawValue > flag.rawValue {
                        majorFlag = flag
                    }
                }
                
                if let origImage = self.offShelfImg?.image {
                    self.offShelfImg.image = origImage.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    
                    switch majorFlag {
                    case .OFF_SHELF:
                        self.offShelfImg.tintColor = UIColor.colorWithRGB(0x808080, alpha: 1)
                        self.offShelfLabel.text = "已下架"
                    case .PRICE_CUT:
                        self.offShelfImg.tintColor = UIColor.colorWithRGB(0xFF6347, alpha: 1)
                        self.offShelfLabel.text = "已降價"
                    case .PET:
                        self.offShelfImg.tintColor = UIColor.colorWithRGB(0x808080, alpha: 1)
                        self.offShelfLabel.text = "可養寵物"
                    case .MANY_IMG:
                        self.offShelfImg.tintColor = UIColor.colorWithRGB(0x808080, alpha: 1)
                        self.offShelfLabel.text = "多張圖"
                    }
                }
                
                self.offShelfView.hidden = false
                return
            }
        }
        
        self.offShelfView.hidden = true
        
    }
    
    private func continueCollectionCallback() {
        if let houseItem = self.houseItem {
            
            if (self.isCollected){
                Log.debug("Delete continueCollectionCallback: \(houseItem.id)")
                self.collectionButtonTouchEventCallback?(event: CollectionEvent.DELETE, houseItem: houseItem)
                
            } else {
                Log.debug("Add continueCollectionCallback: \(houseItem.id)")
                self.collectionButtonTouchEventCallback?(event: CollectionEvent.ADD, houseItem: houseItem)
            }
            
            self.parentTableView.reloadRowsAtIndexPaths([self.indexPath], withRowAnimation: UITableViewRowAnimation.None)
            
        } else {
            assert(false, "The house item for the cell should not be nil")
        }
    }
    
    // MARK: - Public APIs
    func enableCollection(isCollected: Bool, eventCallback: CollectionEventCallback) {
        
        Log.debug("enableCollection")
        
        self.collectionButtonTouchEventCallback = eventCallback
        
        /// Enable add to collection button
        self.addToCollectionButton.hidden = false
        self.addToCollectionButton.userInteractionEnabled = true
        
        /// Add default touch event handler
        self.addToCollectionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SearchResultTableViewCell.onAddToCollectionTouched(_:))))
        
        /// Set to collected state
        self.isCollected = isCollected
        
        if(isCollected) {
            self.addToCollectionButton.image = collectedImg
        }
    }
    
    // MARK: - Inherited Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        Log.debug("prepareForReuse")
        
        self.selectionStyle = UITableViewCellSelectionStyle.None
        
        // Reset any existing information
        houseTitle.text = nil
        houseAddr.text = nil
        houseTypeAndUsage.text = nil
        houseSize.text = nil
        housePrice.text = nil
        addToCollectionButton.image = UIImage(named: "heart_n")
        prefixedButton.image = UIImage(named: "uncheck")
        
        // Cancel image loading operation
        houseImg.af_cancelImageRequest()
        houseImg.layer.removeAllAnimations()
        houseImg.image = nil
        
        houseTitle.hidden = true
        houseTitleForCollection.hidden = true
        contactedView.hidden = true
        offShelfView.hidden = true
        
        self.isCollected = false
        
        Log.debug("\n- Cell Instance [\(self)] Reset Data For Current Row[\(indexPath.row)]")
        
    }
    
    // MARK: - Action Handlers
    func onContactTouched(sender: UITapGestureRecognizer) {
        Log.debug("\(self) onContactTouched")
        
        if let item: CollectionHouseItem = houseItemForCollection {
            let collectionService = CollectionItemService.sharedInstance
            if collectionService.isContacted(item.id) {
                collectionService.updateContacted(item.id, contacted: false)
            } else {
                collectionService.updateContacted(item.id, contacted: true)
            }
        }
    }
    
    func onAddToCollectionTouched(sender: UITapGestureRecognizer) {
        
        if(self.window?.rootViewController == nil) {
            return
        }
        
        let viewController:UIViewController! = self.window?.rootViewController
        
        if (!AmazonClientManager.sharedInstance.isLoggedIn()) {
            AmazonClientManager.sharedInstance.loginFromView(viewController) {
                (task: AWSTask!) -> AnyObject! in
                
                if let error = task.error {
                    Log.debug("Login error = \(error)")
                    return nil
                }
                
                /// Login Form is closed
                if let result = task.result as? Int,
                    loginResult = LoginResult(rawValue: result) where loginResult == LoginResult.Cancelled {
                    
                    Log.debug("Login cancelled")
                    
                    return nil
                }
                
                viewController.runOnMainThread({ () -> Void in
                    self.continueCollectionCallback()
                })
                
                
                
                return nil
            }
            return
        }
        
        self.continueCollectionCallback()
    }
}
