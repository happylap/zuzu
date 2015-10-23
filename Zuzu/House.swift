//
//  House.swift
//  Zuzu
//
//  Created by eechih on 2015/10/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData

@objc(House)
public class House:NSManagedObject {
    
    @NSManaged var title:String?
    
}