//
//  CollectionHouseItem.swift
//  Zuzu
//
//  Created by Ted on 2015/12/21.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import ObjectMapper


class CollectionHouseItem: AbstractHouseItem, Mappable
{
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: CoreDataManager.shared.managedObjectContext)
    }
    
    required init?(_ map: Map) {
        
        let ctx = CoreDataManager.shared.managedObjectContext
        let entity = NSEntityDescription.entityForName(EntityTypes.CollectionHouseItem.rawValue, inManagedObjectContext: ctx)
        super.init(entity: entity!, insertIntoManagedObjectContext: ctx)
        
        mapping(map)
    }
    
    func mapping(map: Map) {
        id          <-  map["id"]
        title       <-  map["title"]
        addr        <-  map["addr"]
        houseType   <- (map["houseType"],   TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        purposeType <- (map["purposeType"], TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        price       <- (map["price"],       TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        size        <-  map["size"]
        source      <- (map["source"],      TransformOf<Int32, Int>(fromJSON: { Int32($0!) }, toJSON: { $0.map { Int($0) } }))
        img         <-  map["img"]
        contacted   <-  map["contacted"]
        collectTime <-  map["collectTime"]
    }    
}
