//
//  SearchItemService.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/22.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

enum SearchItemError : ErrorType {
    case ExceedingMaxItemSize(currentSize: Int)
}

class SearchItemService {
    
    static let maxItemSize = 10
    
    private let searchItemsDataStore : SearchHistoryDataStore = UserDefaultsSearchHistoryDataStore.getInstance()
    
    private static let instance = SearchItemService()
    
    static func getInstance() -> SearchItemService {
        return SearchItemService.instance
    }
    
    func getSearchItemsByType(itemType: SearchType) -> [SearchItem]? {
        var data:[SearchItem]?
        
        if let itemList = searchItemsDataStore.loadSearchItems() {
            data = itemList.filter({ (item: SearchItem) -> Bool in
                return item.type == itemType
            })
        }
        return data
    }
    
    func addNewSearchItem(item: SearchItem) throws {
        
        let typeToAdd = item.type
        
        if var searchItems = searchItemsDataStore.loadSearchItems() {
            
            let typeCount = searchItems.filter{ $0.type == typeToAdd}.count
            
            if(typeCount >= SearchItemService.maxItemSize) {
                    throw SearchItemError.ExceedingMaxItemSize(currentSize: searchItems.count)
            }
            
            searchItems.insert(item, atIndex: searchItems.startIndex)
  
            searchItemsDataStore.saveSearchItems(searchItems)
        } else {
            
            searchItemsDataStore.saveSearchItems([item])
        }
    }
    
    func deleteSearchItem(row: Int, itemType: SearchType) -> Bool{
        
        if var itemList = searchItemsDataStore.loadSearchItems() {
            
            if(itemList.count <= 0) {
                return false
            }
            ///Delete & Persist Result
            var indexForType = 0
            for (index, item) in itemList.enumerate() {
                if(item.type == itemType){
                    
                    if(indexForType == row) {
                        itemList.removeAtIndex(index)
                        break
                    }
                    
                    indexForType++
                }
            }
            self.searchItemsDataStore.saveSearchItems(itemList)
            
            return true
        }
        
        return false
    }
    
}