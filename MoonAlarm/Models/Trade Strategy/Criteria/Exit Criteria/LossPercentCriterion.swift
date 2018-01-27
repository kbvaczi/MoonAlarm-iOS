//
//  LossPercentCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation


class LossExit: TradeExitCriterion {
    
    var maxLossPercent: Percent
    
    override var logMessage: String {
        return "LossExit (\(maxLossPercent)%)"
    }
    
    init(percent: Percent = 1.0) {
        self.maxLossPercent = percent
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let profitPercent = trade.profitPercent else { return false }
        
        // exit as soon as profit reaches a given percent
        if profitPercent <= (self.maxLossPercent * -1) {
            return true
        }
        return false
    }
    
    override func copy() -> LossExit {
        return LossExit(percent: self.maxLossPercent)
    }
    
}
