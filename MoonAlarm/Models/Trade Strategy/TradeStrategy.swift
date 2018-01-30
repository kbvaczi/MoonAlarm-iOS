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
    
    private init() { } // prevent declaring instances of this class
    
    
    // Settings //
    var tradingPairSymbol = "BTC"
    var marketMin24HrVol: Double = 1000
    var tradeAmountTarget: Double = 0.01
    var maxOpenTrades: Int = 8
    var expectedFeePerTrade: Percent = 0.1
    
    
    var candleStickPeriod: BinanceAPI.KLineInterval = .m5
    
    var entranceCriteria = TradeEnterCriteria()
    var exitCriteria = TradeExitCriteria()
    
    func entranceCriteriaPassedFor(snapshot: MarketSnapshot) -> Bool {
        return entranceCriteria.allPassedFor(snapshot)
    }
    
}
