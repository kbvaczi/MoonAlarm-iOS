//
//  ProfitCutoffCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/19/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class ProfitCutoffCriterion: TradeExitCriterion {
    
    var profitCutoffPercent: Percent
    
    init(profitCutoffPercent pcp: Percent = 1.0) {
        self.profitCutoffPercent = pcp
    }
    
    override func passedFor(trade: Trade) -> Bool {
        // exit if trade reaches a certain profit
        guard let profit = trade.profit else { return false }
        
        if profit >= profitCutoffPercent {
            print("\(trade.symbol): Profit Cutoff Criteria Passed")
            return true
        }
        return false
    }
    
}
