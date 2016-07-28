//
//  SearchHistoryDataStore.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/20.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

enum DisplayType: Int {
    case SimpleView = 0
    case DetailView = 1
}

enum ChoiceType: String {
    case SingleChoice = "single"
    case MultiChoice = "multi"
}

enum LogicType: String {
    case And = "AND"
    case Or = "OR"
}


class FilterIdentifier: NSObject {
    let key: String
    let value: String
    let order: Int

    init(key: String, value: String, order: Int) {
        self.key = key
        self.value = value
        self.order = order
    }

    convenience required init?(coder decoder: NSCoder) {
        let key = decoder.decodeObjectForKey("key") as? String ?? ""
        let value = decoder.decodeObjectForKey("value") as? String ?? ""
        let order = decoder.decodeObjectForKey("order") as? Int ?? 0

        self.init(key: key, value: value, order: order)
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(key, forKey:"key")
        aCoder.encodeObject(value, forKey:"value")
        aCoder.encodeObject(order, forKey:"order")
    }

    /// We only use key & value to determine if two filterIdentifiers are the equal
    override func isEqual(object: AnyObject?) -> Bool {
        if let identifier = (object as? FilterIdentifier) {
            return identifier.key == key && identifier.value == value
        }

        return false
    }

    ///Used by some collection type to determine if two objects are the same
    override var hashValue: Int {
        get {
            //NSLog("hashValue %d", "\(key)\(value)".hashValue)
            return "\(key)\(value)".hashValue
        }
    }

    override var description: String {
        let string = "FilterIdentifier: key = \(key), value = \(value)"
        return string
    }
}

class FilterSection: NSObject {
    let label: String
    let filterGroups: [FilterGroup]

    init(label: String, filterGroups: [FilterGroup]) {
        self.label = label
        self.filterGroups = filterGroups
    }
}

class FilterGroup: NSObject, NSCopying {
    let id: String
    let type: DisplayType
    let label: String
    var filters: [Filter]
    var logicType: LogicType?
    var choiceType: ChoiceType?

    var filterDic: [String:String] {
        get {
            var result = [String:String]()

            ///SimpleView or DetailView/SingleChoice
            if(type == .SimpleView || choiceType == .SingleChoice) {

                if let filter = filters.first {
                    result[filter.key] = filter.value
                }
                return result

            }

            var tempResult = [String:[String]]()
            ///DetailView/MultiChoice
            for filter in filters {
                if var value = tempResult[filter.key] {

                    value.append(filter.value)

                    tempResult[filter.key] = value

                } else {

                    tempResult[filter.key] = [filter.value]
                }
            }

            ///Generate final result
            for (key, valueList) in tempResult {
                if let op = logicType?.rawValue {
                    result[key] = "( \(valueList.joinWithSeparator(" \(op) ")) )"
                }
            }

            return result
        }
    }

    init(id: String, label: String, type: DisplayType, filters: [Filter]) {
        self.id = id
        self.label = label
        self.filters = filters
        self.type = type
    }

    override var description: String {
        let string = "FilterGroup: label = \(label), displayType = \(type), filters = \(filters)"
        return string
    }

    func copyWithZone(zone: NSZone) -> AnyObject {

        let filtersCopy = self.filters.map { (filter) -> Filter in
            return filter.copy() as! Filter
        }

        let filterGroupCopy = FilterGroup(id: id, label: self.label, type: self.type, filters: filtersCopy)

        filterGroupCopy.choiceType = self.choiceType
        filterGroupCopy.logicType = self.logicType

        return filterGroupCopy
    }
}

class Filter: NSObject, NSCopying {
    static let defaultKeyUnlimited = "unlimited"

    var identifier: FilterIdentifier {
        get {
            return FilterIdentifier(key: key, value: value, order: order)
        }
    }

    let label: String
    let key: String
    let value: String

    ///The order is currently defined by the order in the config file
    let order: Int

    init(label: String, key: String, value: String, order: Int = 0) {
        self.label = label
        self.key = key
        self.value = value
        self.order = order
    }

    override var description: String {
        let string = "Filter: label = \(label), key = \(key), value = \(value), order = \(order)"
        return string
    }

    func copyWithZone(zone: NSZone) -> AnyObject {
        let filterCopy = Filter(label: self.label, key: self.key, value: self.value, order: self.order)
        return filterCopy
    }
}

protocol FilterSettingDataStore: class {
    func saveAdvancedFilterSetting(filterSetting: [String:Set<FilterIdentifier>])
    func saveSmartFilterSetting(filterSetting: [String:Set<FilterIdentifier>])

    func loadAdvancedFilterSetting() -> [String:Set<FilterIdentifier>]?
    func loadSmartFilterSetting() -> [String:Set<FilterIdentifier>]?

    func clearFilterSetting()
}

class UserDefaultsFilterSettingDataStore: FilterSettingDataStore {

    static let instance = UserDefaultsFilterSettingDataStore()

    static let radarFilterKey = "radarFilterSetting"
    static let advancedFilterKey = "advancedFilterSetting"
    static let smartFilterKey = "smartFilterSetting"

    static func getInstance() -> UserDefaultsFilterSettingDataStore {
        return UserDefaultsFilterSettingDataStore.instance
    }

    func saveAdvancedFilterSetting(filterSetting: [String:Set<FilterIdentifier>]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(filterSetting)
        userDefaults.setObject(data, forKey: UserDefaultsFilterSettingDataStore.advancedFilterKey)
    }

    func saveSmartFilterSetting(filterSetting: [String:Set<FilterIdentifier>]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(filterSetting)
        userDefaults.setObject(data, forKey: UserDefaultsFilterSettingDataStore.smartFilterKey)
    }

    func saveRadarFilterSetting(filterSetting: [String:Set<FilterIdentifier>]) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(filterSetting)
        userDefaults.setObject(data, forKey: UserDefaultsFilterSettingDataStore.radarFilterKey)
    }

    func loadAdvancedFilterSetting() -> [String:Set<FilterIdentifier>]? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsFilterSettingDataStore.advancedFilterKey) as? NSData

        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [String:Set<FilterIdentifier>]
    }

    func loadSmartFilterSetting() -> [String:Set<FilterIdentifier>]? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsFilterSettingDataStore.smartFilterKey) as? NSData

        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [String:Set<FilterIdentifier>]
    }

    func loadRadarFilterSetting() -> [String:Set<FilterIdentifier>]? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let data = userDefaults.objectForKey(UserDefaultsFilterSettingDataStore.radarFilterKey) as? NSData

        return (data == nil) ? nil : NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? [String:Set<FilterIdentifier>]
    }

    func clearFilterSetting() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsFilterSettingDataStore.advancedFilterKey)
        userDefaults.removeObjectForKey(UserDefaultsFilterSettingDataStore.smartFilterKey)
    }

    func clearRadarFilterSetting() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.removeObjectForKey(UserDefaultsFilterSettingDataStore.radarFilterKey)
    }
}
