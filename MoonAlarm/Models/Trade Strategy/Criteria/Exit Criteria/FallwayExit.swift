//
//  FallwayExit.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/26/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class FallwayExit: TradeExitCriterion {
    
    var maxFallwayPercent: Percent
    
    override var logMessage: String {
        return "FallwayExit (\(self.maxFallwayPercent)%)"
    }
    
    init(percent fallway: Percent) {
        self.maxFallwayPercent = fallway
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let fallwayPercent = trade.marketSnapshot.fallwayPercent1Period
                else { return false }
        
        if fallwayPercent > self.maxFallwayPercent {
            return true
        }
        
        return false
    }
    
    override func copy() -> FallwayExit {
        return FallwayExit(percent: self.maxFallwayPercent)
    }
    
}
