//
//  TimeLimitUnprofitableCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TimeLimitExit: TradeExitCriterion {
    
    var exitAfterDuration: Milliseconds
    
    override var logMessage: String {
        let minutes = self.exitAfterDuration.msToMinutes.roundTo(1)
        return "TimeLimitProfitExit (\(minutes) minutes)"
    }
    
    init(_ timeLimit: Minutes = 60) {
        self.exitAfterDuration = timeLimit.minutesToMilliseconds
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit no matter if trade is profitable or not
        if trade.duration > self.exitAfterDuration {
            return true
        }
        return false
    }
    
    override func copy() -> TimeLimitExit {
        return TimeLimitExit(self.exitAfterDuration.msToMinutes)
    }
    
}
