//
//  Note.swift
//  Zuzu
//
//  Created by eechih on 2015/10/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    
    /* Mandatory Fields */
    @NSManaged var id: String
    @NSManaged var houseId: String
    @NSManaged var desc: String
    @NSManaged var createDate: NSDate
}