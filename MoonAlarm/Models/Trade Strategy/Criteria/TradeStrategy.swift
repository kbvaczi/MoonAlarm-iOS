//
//  TradeStrategy.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/17/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Strategy to determine when to enter and exit trades
class TradeStrategy {
    
    /// Criteria that must pass prior to entering a new trade
    var entranceCriteria = TradeEnterCriteria()
    /// One of these criteria must pass prior to exiting an open trade
    var exitCriteria = TradeExitCriteria()
    
    /// Wait this long before entering a trade as long as entrance criteria stays passing
    var delayBeforeEnter: Seconds
    /// Used to keep track of when market snapshots originally pass criteira
    var enterDelayStartedAt = [Symbol:Milliseconds]()
    
    /// Strategy to determine when to enter and exit trades
    ///
    /// - Parameters:
    ///   - entranceCriteria: Criteria that must pass prior to entering a new trade
    ///   - exitCriteria: One of these criteria must pass prior to exiting an open trade
    ///   - delayBeforeEnter: Wait before entering a trade after entrance criteria begins passing
    init(entranceCriteria: TradeEnterCriteria = [], exitCriteria: TradeExitCriteria = [],
         delayBeforeEnter: Seconds = 90) {
        self.entranceCriteria = entranceCriteria
        self.exitCriteria = exitCriteria
        self.delayBeforeEnter = delayBeforeEnter
    }
    
    /// Determine if we should enter a new trade based on recent market snapshot
    ///
    /// - Parameter snapshot: market data used to determine whether to enter trade
    /// - Returns: True if we should enter trade, false otherwise
    func shouldEnterTrade(for snapshot: MarketSnapshot) -> Bool {
        if self.entranceCriteria.allPassedFor(snapshot) {
            let currentTime = Date.currentTimeInMS
            if let delayStartedAt = self.enterDelayStartedAt[snapshot.symbol] {
                let delayPassed = currentTime - delayStartedAt > delayBeforeEnter.secondsToMilliseconds
                if delayPassed { return true }
            } else {
                self.enterDelayStartedAt[snapshot.symbol] = currentTime
            }
        } else {
            self.enterDelayStartedAt.removeValue(forKey: snapshot.symbol)
        }
        return false
    }
    
    /// Determine if we should exit an existing trade based on recent market snapshot
    ///
    /// - Parameter trade: trade we are considering whether to exit
    /// - Returns: true if we should exit trade, false if we should stay in trade
    func shouldExitTrade(_ trade: Trade) -> Bool {
        return self.exitCriteria.onePassedFor(trade)
    }
    
}
