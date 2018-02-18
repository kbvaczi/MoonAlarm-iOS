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
        guard   snapshot.candleSticks.count > 3,
                let currentStochRSI = sticks.last?.stochRSIK,
                let currentSignalDelta = sticks.last?.stochRSISignalDelta,
                let prev1SignalDelta = sticks[sticks.count - 2].stochRSISignalDelta,
                let prev2SignalDelta = sticks[sticks.count - 3].stochRSISignalDelta
                else {
            NSLog("invalid data in StochRSIEnter Criterion")
            return false
        }
        
        // Verify we're below maximum stoch RSI
        guard   currentStochRSI < self.maxStochRSI
                else { return false }
        
        // look for signal cross in the last two candlesticks
        if self.requireSignalCross {
            let wasNegativePreviously = prev1SignalDelta < 0 || prev2SignalDelta < 0
            let isPositiveNow = currentSignalDelta > 0
            let didCross = isPositiveNow && wasNegativePreviously
            return didCross
        }
        
        // No signal cross required and we're below maximum, good to go!
        return true
    }
    
}
