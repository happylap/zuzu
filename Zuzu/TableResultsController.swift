//
//  TableResultsController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

protocol TableResultsController : NSObjectProtocol
{
    func refreshData()
    
    func getNumberOfSectionsInTableView() -> Int
    
    func getNumberOfRowInSection(section: Int) -> Int
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject
    
    func setDelegate(resultControllerDelegate: TableResultsControllerDelegate)
}


protocol TableResultsControllerDelegate : NSObjectProtocol
{
    
    func controllerWillChangeContent(controller: TableResultsController)
    
    
    func controller(controller: TableResultsController, didChangeObject: AnyObject, atIndexPath: NSIndexPath?, forChangeType: TableResultsChangeType, newIndexPath: NSIndexPath?)
    
    
    func controllerDidChangeContent(controller: TableResultsController)
}

public enum TableResultsChangeType : UInt {
    case Insert
    case Delete
    case Move
    case Update
}