//
//  FeatureOptions.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/11/28.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct FeatureOption {
    struct Collection {
        ///The main Collection function
        static let enableMain = true
        
        /// The sub module depending on the main function
        static let enableNote = false
        
        static let enableLogout = false
    }

    struct Radar {
        static let enableMain = false ///The main Radar function
    }
}