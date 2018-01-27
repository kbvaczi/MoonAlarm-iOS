//
//  TrailingLossPercentCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/20/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TrailingLossExit: TradeExitCriterion {
    
    var afterGainPercent: Percent = 2.0
    var hasExceededGain: Bool = false
    
    var maxLossPercent: Percent = 1.0
    
    init(percent loss: Percent = 1.0, after gain: Percent = 2.0) {
        self.maxLossPercent = loss
        self.afterGainPercent = gain
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid inputs
        guard   self.afterGainPercent > 0,
                self.maxLossPercent > 0
                else { return false }
        
        // Check for valid data
        guard   let profitPercent = trade.profitPercent
                else { return false }
        
        // Once we exceed target gain, begin looking for loss
        if profitPercent >= self.afterGainPercent {
            self.hasExceededGain = true
            self.afterGainPercent = profitPercent
        }
        
        // exit trade if we see a loss after target gain
        if self.hasExceededGain {
            let lossAfterGain = self.afterGainPercent - profitPercent
            if lossAfterGain >= self.maxLossPercent {
                print("\(trade.symbol): Trailing Loss Exit Criterion Passed \(self.afterGainPercent)%")
                return true
            }
        }
        
        return false
    }
    
    override func copy() -> TrailingLossExit {
        return TrailingLossExit(percent: self.maxLossPercent, after: self.afterGainPercent)
    }
}
