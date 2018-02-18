//
//  StochRSIExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/15/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class StochRSIExit: TradeExitCriterion {
    
    let maxStochRSI: Double
    
    override var logMessage: String {
        return "StochRSIExit"
    }
    
    init(max: Double = 80) {
        self.maxStochRSI = max
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid data
        let sticks = trade.marketSnapshot.candleSticks
        guard   let currentSRSIK = sticks.last?.stochRSIK,
                let currentSignalDelta = sticks.last?.stochRSISignalDelta,
                let prevSignalDelta = sticks[sticks.count - 2].stochRSISignalDelta
                else {
                    NSLog("invalid data in StochRSIExit Criterion")
                    return false
        }
        
        // Determine if we are over the max
        if currentSRSIK > self.maxStochRSI { return true }
        
        // look for signal cross
        let didCross = currentSignalDelta < 0 && prevSignalDelta > 0
        return didCross
    }
    
    override func copy() -> StochRSIExit {
        return StochRSIExit(max: self.maxStochRSI)
    }
    
}
