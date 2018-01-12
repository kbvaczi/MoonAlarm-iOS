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
        guard   let cVolNorm = candleSticks.currentVolNormalized else { return nil }
        guard   let runwayPrice = orderBook.runwayPrice(forVolume: cVolNorm),
                let firstAsk = orderBook.firstAsk else { return nil }
        return  ((runwayPrice / firstAsk) - 1).toPercent()
    }
    
    var fallwayPercent1M: Double? {
        guard   let cVolNorm = candleSticks.currentVolNormalized else { return nil }
        guard   let fallwayPrice = orderBook.fallwayPrice(forVolume: cVolNorm),
                let firstAsk = orderBook.firstAsk else { return nil }
        return  ((firstAsk / fallwayPrice) - 1).toPercent()
    }
    
    var priceIncreasePercent3M: Double {
        guard   let pRatio = candleSticks.priceRatio1To3M else { return 0 }
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

    func updateData(callback: @escaping () -> Void) {
        updateCandleSticks {
            self.updateOrderBook {
                callback()
            }
        }
    }
    
    private func updateCandleSticks(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeSession.instance.tradingPair
        BinanceAPI.instance.getKLineData(symbolPair: symbolPair, interval: .m1, limit: 15) {
            (isSuccess, cSticks) in
            if isSuccess {
                self.candleSticks = cSticks
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
