//
//  TimeLimitProfitableCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TimeLimitProfitExit: TradeExitCriterion {
    
    var exitAfterDurationIfProfitable: Milliseconds
    
    override var logMessage: String {
        let minutes = self.exitAfterDurationIfProfitable.msToMinutes.roundTo(1)
        return "TimeLimitProfitExit (\(minutes) minutes)"
    }
    
    init(_ timeLimit: Minutes = 60) {
        self.exitAfterDurationIfProfitable = timeLimit.minutesToMilliseconds
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // If we aren't currently profitable, don't exit yet
        guard   let profit = trade.profit,
                profit > 0 else { return false }
        
        
        // only exit if time has expired and trade is currently in profit
        if trade.duration > self.exitAfterDurationIfProfitable {
            return true
        }
        return false
    }
    
    override func copy() -> TimeLimitProfitExit {
        return TimeLimitProfitExit(self.exitAfterDurationIfProfitable.msToMinutes)
    }
    
}
