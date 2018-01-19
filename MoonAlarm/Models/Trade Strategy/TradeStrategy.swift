//
//  TradeStrategy.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeStrategy {
    
    static var instance = TradeStrategy() // singleton
    
    // Settings //
    var tradingPairSymbol = "BTC"
    var tradeAmountTarget: Double = 0.1
    var maxOpenTrades: Int = 5
    var expectedFeePerTrade: Percent = 0.2
    var entranceCriteria = TradeEnterCriteria()
    var exitCriteria = TradeExitCriteria()
    
    private init() { } // prevent declaring instances of this class
    
    func entranceCriteriaPassedFor(snapshot: MarketSnapshot) -> Bool {
        return entranceCriteria.allPassedFor(snapshot)
    }
    
    func exitCriteriaPassedFor(trade: Trade) -> Bool {
        return exitCriteria.onePassedFor(trade)
    }
}
