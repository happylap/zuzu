//
//  EntityTypes.swift
//  Zuzu
//
//  Created by eechih on 2015/10/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

enum EntityTypes: String {
    case House = "House"
    case Note = "Note"
    case AbstractHouseItem = "AbstractHouseItem"
    case CollectionHouseItem = "CollectionHouseItem"
    case NotificationHouseItem = "NotificationHouseItem"

    static let getAll = [House, Note]
}
