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
    
    init(max fallway: Percent) {
        self.maxFallwayPercent = fallway
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let fallwayPercent = trade.marketSnapshot.fallwayPercent1Period
                else { return false }
        
        if fallwayPercent > self.maxFallwayPercent {
            print("\(trade.symbol): Fallway Exit Criterion Passed (\(fallwayPercent.roundTo(2)))")
            return true
        }
        
        return false
    }
    
    override func copy() -> FallwayExit {
        return FallwayExit(max: self.maxFallwayPercent)
    }
    
}
