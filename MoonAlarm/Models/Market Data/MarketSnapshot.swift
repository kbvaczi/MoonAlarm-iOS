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
    var orderBook: OrderBook
    
    init(symbol sym: String, candleSticks cSticks: CandleSticks, orderBook oBook: OrderBook) {
        self.symbol = sym
        self.candleSticks = cSticks
        self.orderBook = oBook
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, candleSticks: CandleSticks(), orderBook: OrderBook(symbol: sym))
    }
    
    var runwayPercent1M: Double? {
        guard   let cVol = candleSticks.currentStickVolumeProrated else { return nil }
        guard   let rwPercent = orderBook.runwayPercent(forVolume: cVol) else { return nil }
        return  rwPercent
    }
    
    var fallwayPercent1M: Double? {
        guard   let cVol = candleSticks.currentStickVolumeProrated else { return nil }
        guard   let fwPercent = orderBook.fallwayPercent(forVolume: cVol) else { return nil }
        return  fwPercent
    }
    
    var currentPrice: Double? {
        guard self.candleSticks.count > 0 else { return nil }
        return self.candleSticks.last!.closePrice
    }

    func updateData(callback: @escaping () -> Void) {
        updateCandleSticks {
            self.updateOrderBook {
                callback()
            }
        }
    }
    
    private func updateCandleSticks(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeStrategy.instance.tradingPairSymbol
        BinanceAPI.instance.getCandleSticks(symbolPair: symbolPair, interval: .m3, limit: 100) {
            (isSuccess, cSticks) in
            if isSuccess {
                self.candleSticks = cSticks
                self.candleSticks.calculateMACD()
            }
            callback()
        }
    }
    
    private func updateOrderBook(callback: @escaping () -> Void) {
        self.orderBook.updateData {
            callback()
        }
    }
}
