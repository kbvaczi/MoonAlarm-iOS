//
//  MACDExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDExitCriterion: TradeExitCriterion {
      
    var decreasingTrendPeriod: Int
    
    init(decreasingTrendFor trendLength: Int = 1) {
        self.decreasingTrendPeriod = trendLength
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid inputs
        guard   decreasingTrendPeriod > 0
                else { return false }
        
        // Check for valid data
        let sticks = trade.marketSnapshot.candleSticks
        let requiredSticks = self.decreasingTrendPeriod + 1
        guard   sticks.count > requiredSticks
                else { return false }
        
        // look for decreasing trend
        var isDecreasingTrend = true
        let trendSticks = sticks.suffix(requiredSticks)
        for (index, stick) in trendSticks.enumerated() {
            let sticksIndex = index + trendSticks.startIndex
            if  let macdH = stick.macdHistogram,
                let macdHPrev = sticks[sticksIndex - 1].macdHistogram,
                macdH >= macdHPrev {
                isDecreasingTrend = false
            }
        }
        if isDecreasingTrend {
            print("\(trade.symbol): MACD Exit Decreasing Trend")
            return true
        }
        
        // Look for MACD cross below signal line, histogram goes from + to -
        guard   let macdH = sticks.last?.macdHistogram,
                let macdHPrev = sticks[sticks.count - 2].macdHistogram
                else { return false }
        
        let isSignalCross = macdH < 0 && macdHPrev > 0
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


