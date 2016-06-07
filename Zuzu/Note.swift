//
//  Note.swift
//  Zuzu
//
//  Created by eechih on 2015/10/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import ObjectMapper

class Note: NSManagedObject, Mappable {
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: CoreDataManager.shared.managedObjectContext)
    }
    
    required init?(_ map: Map) {
        
        let ctx = CoreDataManager.shared.managedObjectContext
        let entity = NSEntityDescription.entityForName(EntityTypes.Note.rawValue, inManagedObjectContext: ctx)
        super.init(entity: entity!, insertIntoManagedObjectContext: ctx)
        
        mapping(map)
    }
    
    func mapping(map: Map) {
        id          <-  map["id"]
        title       <-  map["title"]
        desc        <-  map["desc"]
        createDate  <-  (map["createDate"], DateTransform())
        houseId     <-  map["houseId"]
    }
    
    func fromJSON(obj: AnyObject)
    {
        let note = self
        var data = JSON(obj)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"//this your string date format
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        
        note.id = data["id"].stringValue
        note.title = data["title"].stringValue
        note.desc = data["desc"].stringValue
        note.createDate = NSDate()
        note.houseId = data["houseId"].stringValue
        
    }
    
}