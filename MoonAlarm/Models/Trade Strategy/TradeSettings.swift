//
//  TradeSettings.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeSettings {
    
    static var instance = TradeSettings() // singleton
    
    private init() { } // prevent declaring instances of this class
    
    // Settings //
    var tradingPairSymbol = "BTC"
    var tradingFeeCoinSymbol: String? = "BNB"
    var tradingPairBalance: Double = 0
    var tradingFeeCoinBalance: Double = 0
    
    var marketMin24HrVol: Double = 1000
    var tradeAmountTarget: Double = 0.005
    var maxOpenTrades: Int = 5
    var expectedFeePerTrade: Percent = 0.1
    var testMode: Bool = true

    var candleStickPeriod: BinanceAPI.KLineInterval = .m5
    
    var tradeStrategy = TradeStrategy()
    
    /// Update balances for trading pair and fee coin
    func updateBalances() {
        // Only set balances in test mode
        guard !self.testMode else  { return }
        
        BinanceAPI.instance.getBalance(for: self.tradingPairSymbol) {
            isSuccess, returnedBalance in
            guard isSuccess, let newBalance = returnedBalance else { return }
            self.tradingPairBalance = newBalance
        }
        guard let feeCoinSymbol = self.tradingFeeCoinSymbol else { return }
        BinanceAPI.instance.getBalance(for: feeCoinSymbol) {
            isSuccess, returnedBalance in
            guard isSuccess, let newBalance = returnedBalance else { return }
            self.tradingFeeCoinBalance = newBalance
        }
    }
    
}
