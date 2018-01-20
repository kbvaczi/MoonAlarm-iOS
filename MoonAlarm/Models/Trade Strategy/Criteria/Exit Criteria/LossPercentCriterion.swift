//
//  LossPercentCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation


class LossPercentCriterion: TradeExitCriterion {
    
    var maxLossPercent: Percent = 0.5
    
    override init() { }
    
    init(percent: Percent) {
        self.maxLossPercent = percent
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let profitPercent = trade.profitPercent else { return false }
        
        // exit as soon as profit reaches a given percent
        if profitPercent <= (self.maxLossPercent * -1) {
            print("\(trade.symbol): Loss Percent Criteria Passed")
            return true
        }
        return false
    }
    
    override func copy() -> LossPercentCriterion {
        return LossPercentCriterion(percent: self.maxLossPercent)
    }
    
}
