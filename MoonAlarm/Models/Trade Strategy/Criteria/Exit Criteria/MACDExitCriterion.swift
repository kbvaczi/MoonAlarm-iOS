//
//  MACDExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDExitCriterion: TradeExitCriterion {
    
    override init() { }
    
    override func passedFor(trade: Trade) -> Bool {
        let count = trade.marketSnapshot.candleSticks.count
        let sticks = trade.marketSnapshot.candleSticks
        guard   let currentMacdHistogram = sticks.last?.macdHistogram,
                let prevMacdHistogram = sticks[count - 1].macdHistogram else {
                    return false
        }
        // MACD Crosses above the signal line, or Histogram goes from - to +
        return currentMacdHistogram < 0 && prevMacdHistogram > 0
    }
    
}


