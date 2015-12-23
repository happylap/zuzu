//
//  TableResultsController.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/23.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

protocol TableResultsController
{
    func refresh()
    
    func numberOfSectionsInTableView() -> Int
    
    func getNumberOfRowInSection(section: Int) -> Int
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject
}