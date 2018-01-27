//
//  RunwayExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/25/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MinRunwayExit: TradeExitCriterion {
    
    var minRunwayPercent: Percent
    
    override var logMessage: String {
        return "MinRunwayExit (\(self.minRunwayPercent)%)"
    }
    
    init(percent runway: Percent) {
        self.minRunwayPercent = runway
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let runwayPercent = trade.marketSnapshot.runwayPercent1Period
                else { return false }
        
        if runwayPercent < self.minRunwayPercent {
            return true
        }
        
        return false
    }
    
    override func copy() -> MinRunwayExit {
        return MinRunwayExit(percent: self.minRunwayPercent)
    }
    
}
