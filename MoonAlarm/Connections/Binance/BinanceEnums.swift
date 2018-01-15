//
//  BinanceEnums.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/14/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension BinanceAPI {
    
    // KLineInterval
    // duration of each candlestick
    enum KLineInterval: String {
        case m1 = "1m"
        case m3 = "3m"
        case m5 = "5m"
        case m15 = "15m"
        case m30 = "30m"
        case h1 = "1h"
        case h12 = "12h"
        case d1 = "1d"
    }
    
}
