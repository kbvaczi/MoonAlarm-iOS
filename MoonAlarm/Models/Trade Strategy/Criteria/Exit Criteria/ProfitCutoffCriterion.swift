//
//  ProfitCutoffCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class ProfitCutoffExit: TradeExitCriterion {
    
    var profitPercentCutoff: Percent
    
    override var logMessage: String {
        return "ProfitCutoffExit (\(self.profitPercentCutoff.roundTo(1))%)"
    }
    
    init(percent pp: Percent = 1.0) {
        self.profitPercentCutoff = pp
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit if trade reaches a certain profit
        guard let profitPercent = trade.profitPercent else { return false }
        
        if profitPercent >= profitPercentCutoff {
            return true
        }
        
        return false
    }
    
    override func copy() -> ProfitCutoffExit {
        return ProfitCutoffExit(percent: self.profitPercentCutoff)
    }
    
}
