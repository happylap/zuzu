//
//  Note+CoreDataProperties.swift
//  Zuzu
//
//  Created by Harry Yeh on 6/2/16.
//  Copyright © 2016 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

extension Note {
    
    @NSManaged var id: String
    @NSManaged var title: String?
    @NSManaged var desc: String?
    @NSManaged var createDate: NSDate?
    @NSManaged var houseId: String
    
}
