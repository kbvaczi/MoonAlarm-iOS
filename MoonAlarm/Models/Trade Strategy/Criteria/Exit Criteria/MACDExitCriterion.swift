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
        let sticks = trade.marketSnapshot.candleSticks.suffix(3)
        let startIndex = sticks.startIndex
        let endIndex = sticks.endIndex
        
        guard   let currentMacdHistogram = sticks.last?.macdHistogram,
                let prevMacdHistogram = sticks[endIndex - 2].macdHistogram else {
                    return false
        }
        
        // look for decreasing trend
        var decreasingTrend = true
        for i in (startIndex + 1)..<endIndex {
            guard   let macdH = sticks[i].macdHistogram,
                    let macdHPrev = sticks[i - 1].macdHistogram else { return false }
            if macdH > macdHPrev { decreasingTrend = false}
        }
        if decreasingTrend {
            print("\(trade.symbol): MACD Exit Decreasing Trend")
            return true
        }
        
        // MACD Crosses above the signal line, or Histogram goes from - to +
        let isSignalCross = currentMacdHistogram < 0 && prevMacdHistogram > 0
        if isSignalCross  {
            print("\(trade.symbol): MACD Exit Signal Cross")
            return true
        }
        
        return false
    }
    
    override func copy() -> MACDExitCriterion {
        return MACDExitCriterion()
    }
    
}


