//
//  SmartFilterView.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class Filter {
    var key:String
    var value:String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

class SmartFilterView: UIView {
    
    var filterButtons = [ToggleButton]()
    var filtersByButton = [ToggleButton:Filter]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    ///The correct place to layout subviews (with correct frame & bounds info)
    override func layoutSubviews() {
        NSLog("layoutSubviews")

        var buttonSpace:CGFloat = 8.0
        var buttonWidth:CGFloat = 80.0
        let buttonHeight:CGFloat = 35.0
        
        let widthNeeded = 4 * buttonWidth + 3 * buttonSpace
        
        if(self.frame.width < widthNeeded) {
            let ratio =  self.frame.width / widthNeeded
            buttonSpace *= ratio
            buttonWidth *= ratio
        }
        
        let xOffset:CGFloat = (self.frame.width - 4 * buttonWidth - 3 * buttonSpace) / 2
        let yOffset:CGFloat = (self.frame.height - buttonHeight) / 2
        
        for (index, button) in filterButtons.enumerate() {
            let newXOffset = xOffset + CGFloat(index) * (buttonWidth + buttonSpace)
            button.frame =
                CGRectMake(newXOffset, yOffset,
                    buttonWidth, buttonHeight) // X, Y, width, height
        }
    }
    
    private static func loadFilterData(resourceName: String, criteriaLabel: String) ->  [(label: String, filter: Filter)]{
        
        var resultItems = [(label: String, filter: Filter)]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[criteriaLabel].arrayValue
                
                NSLog("\(criteriaLabel) = %d", items.count)
                
                for itemJsonObj in items {
                    let label = itemJsonObj["label"].stringValue
                    let key = itemJsonObj["filterKey"].stringValue
                    let value = itemJsonObj["filterValue"].stringValue
                    
                    resultItems.append( (label: label, filter: Filter(key: key, value: value)) )
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load json file %@", error)
                
            }
        }
        
        return resultItems
    }
    
    private func setup() {
        self.backgroundColor = UIColor(red: 0x1C/255, green: 0xD4/255, blue: 0xC6/255, alpha: 1)
        
        //Load filters
        let filters = SmartFilterView.loadFilterData("resultFilters", criteriaLabel: "smartFilters")
        
        for filter in filters {
            let button : ToggleButton = ToggleButton()
            button.setTitle(filter.label, forState: .Normal)
            button.titleLabel!.font =  UIFont.systemFontOfSize(14)
            button.offBackgroundColor = UIColor(red: 0x01/255, green: 0xA7/255, blue: 0x9A/255, alpha: 0.65)
             button.onBackgroundColor = UIColor(red: 0x16/255, green: 0xBF/255, blue: 0xB3/255, alpha: 1)
            button.onColor = UIColor.whiteColor()
            button.setToggleState(false)
            
            filtersByButton[button] = filter.filter
            filterButtons.append(button)
            
            self.addSubview(button)
        }
        
    }
}
