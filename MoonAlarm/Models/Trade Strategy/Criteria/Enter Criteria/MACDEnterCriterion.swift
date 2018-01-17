//
//  MACDEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDEnterCriterion: TradeEnterCriterion {
    
    var requireIncreasingTrend: Bool = true
    
    override init() { }
    
    init(requireTrend: Bool) {
        self.requireIncreasingTrend = requireTrend
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        let sticks = snapshot.candleSticks.suffix(3)
        let startIndex = sticks.startIndex
        let endIndex = sticks.endIndex
        
        guard   let currentMacdHistogram = sticks.last?.macdHistogram,
                let prevMacdHistogram = sticks[endIndex - 2].macdHistogram else {
                    return false
        }
        
        // look for increasing trend
        if requireIncreasingTrend {
            for i in (startIndex + 1)..<endIndex {
                guard   let macdH = sticks[i].macdHistogram,
                        let macdHPrev = sticks[i - 1].macdHistogram else { return false }
                if macdH < macdHPrev { return false }
            }
        }
        
        // MACD Crosses under the signal line, or Histogram goes from + to -        
        return currentMacdHistogram > 0 && prevMacdHistogram < 0
    }
    
}


