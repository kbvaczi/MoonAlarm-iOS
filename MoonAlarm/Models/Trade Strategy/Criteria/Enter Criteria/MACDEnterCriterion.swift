//
//  MACDEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/16/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MACDEnterCriterion: TradeEnterCriterion {
    
    var increasingTrendPeriod: Int
    var requireSignalCross: Bool
    var signalCrossPeriod: Int
    
    init(incTrendFor trendLength: Int = 1, requireCross: Bool = true, inLast crossLength: Int = 1) {
        self.increasingTrendPeriod = trendLength
        self.requireSignalCross = requireCross
        self.signalCrossPeriod = crossLength
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
    
        // Check for valid inputs
        guard   increasingTrendPeriod > 0,
                signalCrossPeriod > 0 else { return false }
    
        // Check for valid data
        let sticks = snapshot.candleSticks
        let requiredSticks = max(self.increasingTrendPeriod + 1,
                                 self.signalCrossPeriod + 1)
        guard   sticks.count > requiredSticks else { return false }
        
        // look for increasing trend
        let trendSticks = sticks.suffix(self.increasingTrendPeriod)
        for (index, stick) in trendSticks.enumerated() {
            let sticksIndex = index + trendSticks.startIndex
            
            guard   let macdH = stick.macdHistogram,
                    let macdHPrev = sticks[sticksIndex - 1].macdHistogram,
                    macdH > macdHPrev
                    else { return false }
        }
        
        // there is an increasing trend if we got past this point
        
        // look for signal cross if required
        if requireSignalCross {
            var didCross = false
            let signalSticks = sticks.suffix(self.signalCrossPeriod)
            for (index, stick) in signalSticks.enumerated() {
                
                let sticksIndex = index + signalSticks.startIndex
                
                guard   let macdH = stick.macdHistogram,
                        let macdHPrev = sticks[sticksIndex - 1].macdHistogram
                        else { return false }
                
                if macdH > 0, macdHPrev < 0 { didCross = true }
            }
            
            return didCross
        }
        
        return true // Cross not required, but there's an increasing trend
    }
    
}


