//
//  TimeDelayCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/4/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Wait a period of time after completing a trade before entering a new trade with the same coin
class TimeDelayEnter: TradeEnterCriterion {
    
    let timeDelay: Minutes
    
    /// Wait period of time after completing trade before entering new trade with the same coin
    ///
    /// - Parameter delay: time to wait, in minutes
    init(delay: Minutes) {
        self.timeDelay = delay
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        
        // Check for valid inputs
        guard   self.timeDelay > 0 else { return true }
        
        // Check for previous trade, if no trade then criteria passes
        let tradeSymbol = snapshot.symbol
        let previousTrades = TradeSession.instance.trades
        // Newest trades are inserted in the front
        guard   let lastTrade = previousTrades.first(where: { $0.symbol == tradeSymbol}),
                let lastTradeFinishTime = lastTrade.endTime
                else { return true }
        
        let timeSinceLastTrade = Date.currentTimeInMS - lastTradeFinishTime
        let minutesSinceLastTrade = timeSinceLastTrade.msToMinutes
        
        return minutesSinceLastTrade > timeDelay
    }
    
}

