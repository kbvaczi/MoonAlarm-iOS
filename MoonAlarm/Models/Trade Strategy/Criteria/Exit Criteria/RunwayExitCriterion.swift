//
//  RunwayExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/25/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class RunwayExitCriterion: TradeExitCriterion {
    
    var minRunwayPercent: Percent
    
    init(min runway: Percent) {
        self.minRunwayPercent = runway
    }
    
    override func passedFor(trade: Trade) -> Bool {
        guard   let runwayPercent = trade.marketSnapshot.runwayPercent1Period
                else { return false }
        
        if runwayPercent < self.minRunwayPercent {
            print("\(trade.symbol): Runway Exit Criterion Passed (\(runwayPercent.roundTo(2)))")
            return true
        }
        
        return false
    }
    
    override func copy() -> TradeExitCriterion {
        return RunwayExitCriterion(min: self.minRunwayPercent)
    }
    
}
