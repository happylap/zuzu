//
//  NotificationHouseItem.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

@objc(NotificationHouseItem)
class NotificationHouseItem: AbstractHouseItem {

    override var description: String {
        let string = "NotificationHouseItem: id = \(id)\n title = \(title)\n post_time = \(postTime)"
        return string
    }

}
