//
//  CoinTradingDetail.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class CoinTradingDetail {
    
    var symbol: String          // ticker symbol
    var volumeRatio: Double     // recent volume compared to normalized historical volume
    var priceRatio: Double      // ratio of current price to average
    
    var priceIncreasePercent: Double {
        return round((priceRatio - 1) * 1000) / 10
    }
    
    init(symbol sym: String, volumeRatio vr: Double, priceRatio pr: Double) {
        symbol = sym
        volumeRatio = vr
        priceRatio = pr
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, volumeRatio: 0, priceRatio: 0)
    }
    
    
     
}
