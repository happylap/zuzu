//
//  Note.swift
//  Zuzu
//
//  Created by eechih on 2015/10/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

public class Note: NSManagedObject {
    
    @NSManaged var createDate: NSDate?
    @NSManaged var desc: String?
    @NSManaged var title: String?
    @NSManaged var houseId: String?
}