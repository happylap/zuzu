//
//  GAConst.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/30.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct GAConst {
    
    struct Catrgory {
        ///Common UI event
        struct Activity {
            static let Name = "activity"
            
            struct Action {
                
                struct History {
                    static let Name = "history"
                    struct Label {
                        static let Load = "load"
                        static let Save = "save"
                    }
                }

                struct Contact {
                    static let Name = "contact"
                    struct Label {
                        static let Phone = "phone"
                        static let Email = "email"
                    }
                }
                
                static let ViewSource = "viewSource"
                
                static let FanPage = "fanPage"
                
                static let ShareItem = "shareItem"
                
                static let ViewItem = "viewItem"
                
                static let ResetCriteria = "resetCriteria"
                
                static let ResetFilters = "resetFilters"
            }
        }
        
        ///Criteria Setting event
        struct Criteria {
            static let Name = "criteria"
            
            struct Action {
                static let Keyword = "keyword"
                static let Region = "region"
                static let Type = "type"

                struct Price {
                    static let Name = "price"
                    struct Label {
                        static let Max = "max"
                        static let Min = "min"
                    }
                }
                
                struct Size {
                    static let Name = "size"
                    struct Label {
                        static let Max = "max"
                        static let Min = "min"
                    }
                }
            }
        }

        ///Filter Setting event
        static let SmartFilter = "smartFilter"
        
        static let Filter = "filter"
        
        ///Sorting event
        static let Sorting = "sorting"
    }
}