//
//  RSIExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/21/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class RSIExitCriterion: TradeExitCriterion {
    
    var maxRSI: Double
    
    init(max rsi: Double = 60) {
        self.maxRSI = rsi
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid inputs
        guard   self.maxRSI > 0 else { return false }
        
        // Check for valid data
        guard   let lastRSI = trade.marketSnapshot.candleSticks.last?.rsi
                else { return false }
        
        if lastRSI > maxRSI {
            print("\(trade.symbol): RSI Exit Criterion Passed")
            return true
        }
        
        return false
    }
    
    override func copy() -> RSIExitCriterion {
        return RSIExitCriterion(max: maxRSI)
    }
    
}
