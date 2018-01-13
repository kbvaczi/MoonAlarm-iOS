//
//  TimeLimitUnprofitableCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TimeLimitUnprofitableCriterion: TradeExitCriterion {
    
    var exitAfterDuration: Milliseconds = 5.minutesToMilliseconds
    
    override init() { }
    
    init(timeLimit: Milliseconds) {
        self.exitAfterDuration = timeLimit
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit no matter if trade is profitable or not
        if trade.duration > self.exitAfterDuration {
            print("Time Limit Unprofitable Exit Criteria Passed")
            return true
        }
        return false
    }
    
}
