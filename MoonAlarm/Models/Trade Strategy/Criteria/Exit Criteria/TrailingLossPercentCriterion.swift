//
//  TrailingLossPercentCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/20/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TrailingLossExit: TradeExitCriterion {
    
    var afterGainPercent: Percent = 0.3
    var ignoreAbovePercent: Percent = 1.0
    var hasExceededGain: Bool = false
    var maxLossPercent: Percent = 0.3
    
    override var logMessage: String {
        return "Trailing Loss (\(self.maxLossPercent)% after \(self.afterGainPercent)%)"
    }
    
    init(percent loss: Percent = 0.3, after gain: Percent = 0.3, ignoreAbove: Percent = 1.0) {
        self.maxLossPercent = loss
        self.afterGainPercent = gain
        self.ignoreAbovePercent = ignoreAbove
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        // Check for valid inputs
        guard   self.afterGainPercent > 0,
                self.maxLossPercent > 0,
                self.ignoreAbovePercent >= afterGainPercent
                else { return false }
        
        // Check for valid data
        guard   let profitPercent = trade.profitPercent
                else { return false }
        
        // Once we exceed target gain, begin looking for loss
        if profitPercent >= self.afterGainPercent {
            self.hasExceededGain = true
            self.afterGainPercent = min(profitPercent, self.ignoreAbovePercent)
        }
        
        // exit trade if we see a loss after target gain
        if self.hasExceededGain {
            let lossAfterGain = self.afterGainPercent - profitPercent
            if lossAfterGain >= self.maxLossPercent {
                return true
            }
        }
        
        return false
    }
    
    override func copy() -> TrailingLossExit {
        return TrailingLossExit(percent: self.maxLossPercent, after: self.afterGainPercent)
    }
}
