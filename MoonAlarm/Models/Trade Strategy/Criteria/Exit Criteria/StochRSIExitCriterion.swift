//
//  StochRSIExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/15/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class StochRSIExit: TradeExitCriterion {
    
    override var logMessage: String {
        return "StochRSIExit"
    }
    
    override init() { }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid data
        let sticks = trade.marketSnapshot.candleSticks
        guard   let currentSignalDelta = sticks.last?.stochRSISignalDelta,
            let prevSignalDelta = sticks[sticks.count - 2].stochRSISignalDelta
            else {
                NSLog("invalid data in StochRSIExit Criterion")
                return false
        }
        
        // look for signal cross
        let didCross = currentSignalDelta < 0 && prevSignalDelta > 0
        return didCross
    }
    
    override func copy() -> StochRSIExit {
        return StochRSIExit()
    }
    
}
