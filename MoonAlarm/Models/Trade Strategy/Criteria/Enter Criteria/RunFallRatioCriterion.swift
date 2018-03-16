//
//  RunFallRatioCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 3/15/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class RunFallRatioEnter: TradeEnterCriterion {
    
    var minRunFallRatio: Double = 1.0
    
    /// Spare runway must be greater than fallway by specified ratio
    ///
    /// - Parameter minRatio: ratio (i.e. 1.0 means runway and fallway must be equal)
    init(_ minRatio: Double) {
        self.minRunFallRatio = minRatio
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard   let runwayPercent = snapshot.runwayPercent1Period,
                let fallwayPercent = snapshot.fallwayPercent1Period
                else { return false }
        
        return (runwayPercent / fallwayPercent) >= minRunFallRatio
    }
    
}
