//
//  TimeLimitUnprofitableCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TimeLimitExit: TradeExitCriterion {
    
    var exitAfterDuration: Milliseconds = 5.minutesToMilliseconds
    
    override init() { }
    
    init(_ timeLimit: Minutes = 60) {
        self.exitAfterDuration = timeLimit.minutesToMilliseconds
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit no matter if trade is profitable or not
        if trade.duration > self.exitAfterDuration {
            print("\(trade.symbol): Time Limit Unprofitable Exit Criteria Passed")
            return true
        }
        return false
    }
    
    override func copy() -> TimeLimitExit {
        return TimeLimitExit(self.exitAfterDuration.msToMinutes)
    }
    
}
