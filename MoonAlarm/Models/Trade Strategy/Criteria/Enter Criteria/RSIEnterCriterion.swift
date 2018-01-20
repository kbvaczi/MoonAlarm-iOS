//
//  RSIEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/20/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class RSIEnterCriterion: TradeEnterCriterion {
    
    var maxRSI: Double
    var inLastPeriods: Int
    
    init(max rsi: Double = 30, inLast periods: Int = 1) {
        self.inLastPeriods = periods
        self.maxRSI = rsi
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        
        // Check for valid inputs
        guard self.maxRSI > 0, self.inLastPeriods > 0 else { return false }
        
        // Check for valid data
        let sticks = snapshot.candleSticks.suffix(self.inLastPeriods)
        guard  sticks.count >= self.inLastPeriods else { return false }
        
        var atLeastOneBelowMax = false

        for stick in sticks {
            if let rsi = stick.rsi, rsi < self.maxRSI {
                atLeastOneBelowMax = true
            }
        }
        
        return atLeastOneBelowMax
    }
    
}
