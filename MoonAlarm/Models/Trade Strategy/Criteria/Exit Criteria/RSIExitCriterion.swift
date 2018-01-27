//
//  RSIExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/21/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class RSIExit: TradeExitCriterion {
    
    var maxRSI: Double
    
    override var logMessage: String {
        return "RSIExit (\(self.maxRSI))"
    }
    
    init(max rsi: Double = 60) {
        self.maxRSI = rsi
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid inputs
        guard   self.maxRSI > 0 else { return false }
        
        // Check for valid data
        let lastTwoSticks = trade.marketSnapshot.candleSticks.suffix(2)
        
        var allAboveMax = true
        for stick in lastTwoSticks {
            if  let rsi = stick.rsi,
                rsi < maxRSI {
                allAboveMax = false
            }
        }
        
        if allAboveMax {
            return true
        }
        
        return false
    }
    
    override func copy() -> RSIExit {
        return RSIExit(max: maxRSI)
    }
    
}
