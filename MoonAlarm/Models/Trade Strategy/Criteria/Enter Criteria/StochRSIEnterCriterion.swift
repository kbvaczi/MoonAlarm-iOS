//
//  StochRSIEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/11/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class StochRSIEnter: TradeEnterCriterion {
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        
        // Check for valid data
        let sticks = snapshot.candleSticks
        guard   let currentSignalDelta = sticks.last?.stochRSISignalDelta,
                let prevSignalDelta = sticks[sticks.count - 2].stochRSISignalDelta
                else { return false }
        
        // look for signal cross
        let didCross = currentSignalDelta > 0 && prevSignalDelta < 0

        return didCross
    }
    
}
