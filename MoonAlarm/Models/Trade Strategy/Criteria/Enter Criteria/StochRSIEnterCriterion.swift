//
//  StochRSIEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/11/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Enter trades based on Stoch RSI Indicator
class StochRSIEnter: TradeEnterCriterion {
    
    /// Only enter trades when current stoch RSI is below this value
    let maxStochRSI: Double
    /// Stoch RSI must have signal cross to enter trade
    let requireSignalCross: Bool
    /// To reduce weak crosses, only enter trade if no cross has happened recently
    let noPriorCrossInLast: Int
    
    /// Enter trades based on Stoch RSI Indicator
    ///
    /// - Parameters:
    ///   - max: Only enter trades when current stoch RSI is below this value
    ///   - requireCross: Stoch RSI must have signal cross to enter trade
    ///   - noCrossInLast: To reduce weak crosses, only enter trade if no cross has happened recently
    init(max: Double = 80, requireCross: Bool = true, noPriorCrossInLast: Int = 6) {
        self.maxStochRSI = max
        self.requireSignalCross = requireCross
        self.noPriorCrossInLast = noPriorCrossInLast
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        
        // Check for valid data
        let sticks = snapshot.candleSticks
        guard   snapshot.candleSticks.count > 3,
                let currentStochRSI = sticks.last?.stochRSIK,
                let currentSignalDelta = sticks.last?.stochRSISignalDelta,
                let prev1SignalDelta = sticks[sticks.count - 2].stochRSISignalDelta
                else {
            NSLog("invalid data in StochRSIEnter Criterion")
            return false
        }
        
        // Verify we're below maximum stoch RSI
        guard   currentStochRSI < self.maxStochRSI
                else { return false }
        
        // Verify there hasn't been a recent cross
        let lastSticksToIgnore = 3
        if noPriorCrossInLast > lastSticksToIgnore {
            var wasPriorCross = false
            let crossDataSet = snapshot.candleSticks.suffix(noPriorCrossInLast)
                                                    .dropLast().dropLast().dropLast()
            let startIndex = crossDataSet.startIndex
            for (i, stick) in crossDataSet.enumerated() {
                let priorIndex = startIndex + i - 1
                if  let priorSRSID = snapshot.candleSticks[priorIndex].stochRSISignalDelta,
                    let currentSRSID = stick.stochRSISignalDelta,
                    priorSRSID < 0 && currentSRSID > 0 {
                        wasPriorCross = true
                }
            }
            if wasPriorCross { return false }
        } else {
            NSLog("invalid noCrossInLast for StochRSIEnter Criterion")
        }
        
        
        // look for signal cross in the last two candlesticks
        if self.requireSignalCross {
            let wasNegativePreviously = prev1SignalDelta < 0
            let isPositiveNow = currentSignalDelta > 0
            let didCross = isPositiveNow && wasNegativePreviously
            return didCross
        }
        
        // No signal cross required and we're below maximum, good to go!
        return true
    }
    
}
