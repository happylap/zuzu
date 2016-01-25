//
//  SmartFilterView.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

private let Log = Logger.defaultLogger

class SmartFilterView: UIView {

    private let filtersPerPage = 4
    var filterPage = 1

    var filterButtons = [ToggleButton]()
    var filtersByButton = [ToggleButton:FilterGroup]()
    
    init(frame: CGRect, page: Int = 1) {
        super.init(frame: frame)
        self.filterPage = page
        self.setup()
    }

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    ///The correct place to layout subviews (with correct frame & bounds info)
    override func layoutSubviews() {
        Log.verbose("layoutSubviews")
        
        var buttonSpace:CGFloat = 8.0
        var buttonWidth:CGFloat = 80.0
        var buttonHeight:CGFloat = buttonWidth * 115/320
        
        let widthNeeded = 4 * buttonWidth + 5 * buttonSpace //including leading & trailing to the superview
        
        if(self.frame.width < widthNeeded) {
            let ratio =  self.frame.width / widthNeeded
            buttonSpace *= ratio
            buttonWidth *= ratio
        }
        
        let xOffset:CGFloat = (self.frame.width - 4 * buttonWidth - 3 * buttonSpace) / 2
        let yOffset:CGFloat = (self.frame.height - buttonHeight) / 2
        
        for (index, button) in filterButtons.enumerate() {
            let newXOffset = xOffset + CGFloat(index) * (buttonWidth + buttonSpace)
            
            let buttonFrame = CGRect(x: newXOffset, y: yOffset, width: buttonWidth, height: buttonHeight) // X, Y, width, height
            
            Log.verbose("SmartFilterView buttonFrame = \(buttonFrame)")
            
            button.frame = buttonFrame
        }
    }
    
    private static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [FilterGroup]{
        
        var resultItems = [FilterGroup]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[criteriaLabel].arrayValue
                
                Log.debug("\(criteriaLabel) = \(items.count)")
                
                for (index, itemJsonObj) in items.enumerate() {
                    let groupId = itemJsonObj["id"].stringValue
                    let type = itemJsonObj["type"].intValue
                    let label = itemJsonObj["label"].stringValue
                    let key = itemJsonObj["filterKey"].stringValue
                    let value = itemJsonObj["filterValue"].stringValue
                    
                    let filterGroup = FilterGroup(id: groupId, label: label,
                        type: DisplayType(rawValue: type)!,
                        filters: [Filter(label: label, key: key, value: value, order: index)])

                    resultItems.append(filterGroup)
                }
                
            } catch let error as NSError{
                
                Log.debug("Cannot load json file \(error.localizedDescription)")
                
            }
        }
        
        return resultItems
    }
    
    private func setup() {
        self.backgroundColor = UIColor.colorWithRGB(0x1CD4C6, alpha: 1)
        //Load filters
        let filters = SmartFilterView.loadFilterData("resultFilters", criteriaLabel: "smartFilters")
        
        for (index, filter) in filters.enumerate() {
            
            if(index < (filterPage-1) * filtersPerPage) {
                continue
            }
            
            if(index >= filterPage * filtersPerPage) {
                break
            }

            let button : ToggleButton = ToggleButton()
            button.setTitle(filter.label, forState: .Normal)
            button.titleLabel!.font =  UIFont.systemFontOfSize(14)
            button.titleLabel?.autoScaleFontSize = true
            button.offBackgroundColor = UIColor.clearColor()
            button.offColor = UIColor.whiteColor().colorWithAlphaComponent(0.65)
            
            button.onBackgroundColor = UIColor.colorWithRGB(0x16BFB3, alpha: 1)
            button.onColor = UIColor.whiteColor()
            
            button.layer.cornerRadius = 10
            button.setToggleState(false)
            
            filtersByButton[button] = filter
            filterButtons.append(button)
            
            self.addSubview(button)
        }
        
    }
}
