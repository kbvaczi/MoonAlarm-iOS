//
//  MACDEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDEnterCriterion: TradeEnterCriterion {
    
    var increasingTrendPeriod: Int? = 3
    var requireSignalCross: Bool = true
    
    init(incTrendFor trendLength: Int?, requireCross: Bool) {
        self.increasingTrendPeriod = trendLength
        self.requireSignalCross = requireCross
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        let stickCount = self.increasingTrendPeriod ?? 1
        let sticks = snapshot.candleSticks.suffix(stickCount)
        let startIndex = sticks.startIndex
        let endIndex = sticks.endIndex
        
        guard sticks.count > 0 else { return false }
        
        // look for increasing trend if required
        let requireIncreasingTrend = increasingTrendPeriod ?? 0 > 1
        if requireIncreasingTrend {
            for i in (startIndex + 1)..<endIndex {
                guard   let macdH = sticks[i].macdHistogram,
                        let macdHPrev = sticks[i - 1].macdHistogram else { return false }
                if macdH < macdHPrev { return false }
            }
            
            // require last stick price to be higher than previous
            let prevPrice = sticks[endIndex - 2].closePrice
            if let currentPrice = snapshot.currentPrice, currentPrice < prevPrice {
                return false
            }
        }
        
        // MACD Crosses under the signal line, or Histogram goes from + to -
        if requireSignalCross {
            guard   let currentMacdHistogram = sticks.last?.macdHistogram,
                    let prevMacdHistogram = sticks[endIndex - 2].macdHistogram
                    else { return false }
            return currentMacdHistogram > 0 && prevMacdHistogram < 0
        }
        
        // if neither criteria drops out, we assume criterion has passed
        return true
    }
    
}


