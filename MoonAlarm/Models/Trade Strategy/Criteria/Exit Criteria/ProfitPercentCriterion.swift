//
//  ProfitPercentCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class ProfitPercentCriterion: TradeExitCriterion {
    
    var targetProfitPercent: Percent = 1.0
    
    override init() { }
    
    init(percent: Percent) {
        self.targetProfitPercent = percent
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let profitPercent = trade.profitPercent else { return false }
        // exit as soon as profit reaches a given percent
        if profitPercent >= self.targetProfitPercent {
            print("Profit Percent Exit Criteria Passed")
            return true
        }
        return false
    }
    
}
