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
        guard   let cVol = candleSticks.currentStickVolume else { return nil }
        guard   let runwayPrice = orderBook.runwayPrice(forVolume: cVol),
                let firstAsk = orderBook.firstAsk else { return nil }
        return  ((runwayPrice / firstAsk) - 1).doubleToPercent
    }
    
    var fallwayPercent1M: Double? {
        guard   let cVol = candleSticks.currentStickVolume else { return nil }
        guard   let fallwayPrice = orderBook.fallwayPrice(forVolume: cVol),
                let firstAsk = orderBook.firstAsk else { return nil }
        return  ((firstAsk / fallwayPrice) - 1).doubleToPercent
    }
    
    var priceIncreasePercent3M: Double? {
        guard   let pRatio = candleSticks.priceRatio1To3M else { return nil }
        return round((pRatio.doubleToPercent - 100) * 100) / 100
    }
    
    var priceHasIncreased: Bool? {
        return candleSticks.priceHasIncreased
    }
    
    var volumeAvg15M: Double? {
        guard let avg = candleSticks.volumeAvg15M else { return nil }
        return avg
    }
    
    var volumeRatio1To15M: Double? {
        guard let pRatio = candleSticks.volumeRatio1To15M else { return nil }
        return pRatio
    }
    
    var tradesRatio1To15M: Double? {
        guard let tRatio = candleSticks.tradesRatio1To15M else { return nil }
        return tRatio
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
