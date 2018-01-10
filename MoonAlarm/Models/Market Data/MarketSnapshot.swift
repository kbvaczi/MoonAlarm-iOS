//
//  MarketSnapshot.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MarketSnapshot {
    
    let symbol: String          // ticker symbol
    var candleSticks: CandleSticks
//    var orderbook: OrderBook
    
    init(symbol sym: String, candleSticks cSticks: CandleSticks) {
        symbol = sym
        candleSticks = cSticks
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, candleSticks: CandleSticks())
    }
    
    var priceIncreasePercent3M: Double {
        guard var pRatio = candleSticks.priceRatio1To3M else { return 0 }
        return round((pRatio.toPercent() - 100) * 100) / 100
    }
    
    var priceIsIncreasing: Bool {
        return candleSticks.priceIsIncreasing
    }
    
    var volumeAvg15M: Double {
        guard let avg = candleSticks.volumeAvg15M else { return 0 }
        return avg
    }
    
    var volumeRatio1To15M: Double {
        guard let pRatio = candleSticks.volumeRatio1To15M else { return 0 }
        return pRatio
    }
    
    var tradesRatio1To15M: Double {
        guard let tRatio = candleSticks.tradesRatio1To15M else { return 0 }
        return tRatio
    }
    
    var currentPrice: Double {
        guard self.candleSticks.count > 0 else { return 0 }
        return self.candleSticks.last!.closePrice
    }

    func update(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeSession.instance.tradingPair
        BinanceAPI.instance.getKLineData(symbolPair: symbolPair, interval: .m1, limit: 15) {
            (isSuccess, cSticks) in
            if isSuccess {
                self.candleSticks = cSticks
            }
            callback()
        }
    }
    
}
