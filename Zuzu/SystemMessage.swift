//
//  System.swift
//  Zuzu
//
//  Created by 李桄瑋 on 2015/12/25.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

struct SystemMessage {

    struct INFO {
        static let EMPTY_NOTIFICATIONS = "尚無任何通知物件\n\n請到「租屋雷達」設定找屋條件，開始接收即時通知"
        static let EMPTY_COLLECTTIONS = "尚無任何收藏的物件\n\n不妨在搜尋結果頁，開始收藏你感興趣的租屋物件"
        static let EMPTY_SAVED_SEARCH = "尚無任何儲存的\"常用搜尋\"\n\n不妨嘗試在搜尋結果頁，把當前搜尋條件儲存起來"
        static let EMPTY_HISTORICAL_SEARCH = "尚無任何\"搜尋紀錄\"\n\n日後任何的搜尋紀錄，都會記錄在這邊，方便查找"
        static let EMPTY_HISTORICAL_PURCHASE = "尚無任何\"購買紀錄\"\n\n不妨嘗試在租屋雷達頁，設定並取符合需求的通知條件"
        static let EMPTY_SEARCH_RESULT = "喔喔...目前的搜尋條件找不到任何物件\n\n嘗試換個條件再搜尋一次！"
        
        static let EXTERNAL_SITE_RESULT = "即將離開豬豬快租\n\n開啟原始房源網頁"
    }

    struct ALERT {
    }

    struct ERROR {
    }
}
