//
//  StochRSIEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/11/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class StochRSIEnter: TradeEnterCriterion {
    
    let maxStochRSI: Double
    let requireSignalCross: Bool
    
    init(max: Double = 100, requireCross: Bool = true) {
        self.maxStochRSI = max
        self.requireSignalCross = requireCross
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        
        // Check for valid data
        let sticks = snapshot.candleSticks
        guard   let currentStochRSI = sticks.last?.stochRSIK,
                let currentSignalDelta = sticks.last?.stochRSISignalDelta,
                let prevSignalDelta = sticks[sticks.count - 2].stochRSISignalDelta
                else {
            NSLog("invalid data in StochRSIEnter Criterion")
            return false
        }
        
        // Verify we're below maximum stoch RSI
        guard   currentStochRSI < self.maxStochRSI
                else { return false }
        
        // look for signal cross
        if self.requireSignalCross {
            let didCross = currentSignalDelta > 0 && prevSignalDelta < 0
            return didCross
        }
        
        // No signal cross required and we're below maximum, good to go!
        return true
    }
    
}
