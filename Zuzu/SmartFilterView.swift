//
//  SmartFilterView.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import UIKit
import SwiftyJSON

class SmartFilterView: UIView {
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
    // Drawing code
    }
    */
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    private static func loadFilterData(resourceName: String) ->  [(label:String, value:Int)]{
        
        var resultItems = [(label: String, value: Int)]()
        
        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[resourceName].arrayValue
                
                NSLog("\(resourceName) = %d", items.count)
                
                for itemJsonObj in items {
                    let label = itemJsonObj["label"].stringValue
                    let value = itemJsonObj["value"].intValue
                    
                    resultItems.append( (label: label, value: value) )
                }
                
            } catch let error as NSError{
                
                NSLog("Cannot load area json file %@", error)
                
            }
        }
        
        return resultItems
    }
    
    private func setup() {
        //Load filters
        let filters = SmartFilterView.loadFilterData("smartFilters")
        let xOffset:CGFloat = 8.0
        let yOffset:CGFloat = 10.0
        let buttonSpace:CGFloat = 8.0
        let buttonWidth:CGFloat = 80.0
        let buttonHeight:CGFloat = 35.0
        
        for (index, filter) in filters.enumerate() {
            let newXOffset = xOffset + CGFloat(index) * (buttonWidth + buttonSpace)
            let button : ToggleButton = ToggleButton()
            button.setTitle(filter.label, forState: .Normal)
            button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            button.frame =
                CGRectMake(newXOffset, yOffset,
                    buttonWidth, buttonHeight) // X, Y, width, height
            
            button.addTarget(self, action: "onFilterButtonTouched:", forControlEvents: UIControlEvents.TouchDown)
            
            self.addSubview(button)
        }
        
    }
    
    func onFilterButtonTouched(sender: UIButton) {
        if let toogleButton = sender as? ToggleButton {
            toogleButton.toggleButtonState()
        }
    }
    
}
