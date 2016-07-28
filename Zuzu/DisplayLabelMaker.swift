//
//  DisplayLabel.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/16.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import SwiftyJSON

private let Log = Logger.defaultLogger

class DisplayLabelMakerFactory: NSObject {

    enum Type {
        case House
    }

    class internal func createDisplayLabelMaker(type: Type) -> LabelMaker? {
        if(type == .House) {
            return HouseLabelMaker()
        } else {
            return nil
        }
    }
}

protocol LabelMaker {
    func fromCodeForField(field: String, code: Int) -> String?

    func fromCodeForField(field: String, code: Int, defaultValue: String) -> String
}

class HouseLabelMaker: LabelMaker {

    let labelResourceName = "filedLabels"

    static var labelItemsByFields:[(field: String, labels: [Int : String])] = HouseLabelMaker.loadLabelData("fieldLabels", root: "field_labels")

    private static func loadLabelData(resourceName: String, root: String) ->  [(field: String, labels: [Int : String])] {

        var resultItems = [(field: String, labels : [Int : String])]()

        if let path = NSBundle.mainBundle().pathForResource(resourceName, ofType: "json") {

            do {
                let jsonData = try NSData(contentsOfFile: path, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                let json = JSON(data: jsonData)
                let items = json[root].dictionaryValue

                Log.debug("\(root) = \(items.count)")

                for itemJsonObj in items {

                    let key = itemJsonObj.0
                    let labelDic = itemJsonObj.1.dictionaryValue
                    var newDic = [Int: String]()

                    for labelEntry in labelDic {
                        newDic[Int(labelEntry.0)!] = labelEntry.1.stringValue
                    }

                    resultItems.append((field: key, labels: newDic))
                }

            } catch let error as NSError {

                Log.debug("Cannot load json file \(error.localizedDescription)")

            }
        }

        return resultItems
    }

    internal func fromCodeForField(field: String, code: Int) -> String? {

        for fieldLabelItems in HouseLabelMaker.labelItemsByFields {
            if(fieldLabelItems.field == field) {
                return fieldLabelItems.labels[code]
            }
        }

        return nil
    }

    internal func fromCodeForField(field: String, code: Int, defaultValue: String) -> String {

        for fieldLabelItems in HouseLabelMaker.labelItemsByFields {
            if(fieldLabelItems.field == field) {
                return fieldLabelItems.labels[code] ?? defaultValue
            }
        }

        return defaultValue
    }

}
