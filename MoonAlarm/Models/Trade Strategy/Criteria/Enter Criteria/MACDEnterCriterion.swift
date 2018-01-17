//
//  MACDEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDEnterCriterion: TradeEnterCriterion {
    
    override init() { }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        let count = snapshot.candleSticks.count
        let sticks = snapshot.candleSticks
        guard   let currentMacdHistogram = sticks.last?.macdHistogram,
                let prevMacdHistogram = sticks[count - 2].macdHistogram else {
                    return false
        }
        
        // MACD Crosses under the signal line, or Histogram goes from + to -        
        return currentMacdHistogram > 0 && prevMacdHistogram < 0
    }
    
}


