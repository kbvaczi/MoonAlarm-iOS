//
//  ProfitCutoffCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class ProfitCutoffCriterion: TradeExitCriterion {
    
    var profitPercentCutoff: Percent
    
    init(profitPercent pp: Percent = 1.0) {
        self.profitPercentCutoff = pp
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit if trade reaches a certain profit
        guard let profitPercent = trade.profitPercent else { return false }
        
        if profitPercent >= profitPercentCutoff {
            print("\(trade.symbol): Profit Cutoff Criteria Passed")
            return true
        }
        
        return false
    }
    
}
