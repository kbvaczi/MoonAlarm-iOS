//
//  TimeLimitProfitableCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TimeLimitProfitableCriterion: TradeExitCriterion {
    
    var exitAfterDurationIfProfitable: Milliseconds = 60.secondsToMilliseconds
    
    override init() { }
    
    init(timeLimit: Milliseconds) {
        self.exitAfterDurationIfProfitable = timeLimit
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // If we aren't currently profitable, don't exit yet
        guard   let profit = trade.profit,
                profit > 0 else { return false }
        
        
        // only exit if time has expired and trade is currently in profit
        if trade.duration > self.exitAfterDurationIfProfitable {
            print("\(trade.symbol): TimeLimitProfitable Exit Criteria Passed")
            return true
        }
        return false
    }
    
}
