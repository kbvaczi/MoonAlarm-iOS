//
//  MarketSnapshot.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MarketSnapshot {
    
    let symbol: Symbol          // ticker symbol
    var candleSticks: CandleSticks
    var orderBook: OrderBook
    
    init(symbol sym: String, candleSticks cSticks: CandleSticks,
         orderBook oBook: OrderBook) {
        self.symbol = sym
        self.candleSticks = cSticks
        self.orderBook = oBook
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, candleSticks: CandleSticks(),
                  orderBook: OrderBook(symbol: sym))
    }
    
    var runwayPercent1Period: Double? {
        guard   let cVol = candleSticks.currentStickVolumeProrated,
                let rwPercent = orderBook.runwayPercent(forVolume: cVol)
                else { return nil }
        return  rwPercent
    }
    
    var fallwayPercent1Period: Double? {
        guard   let cVol = candleSticks.currentStickVolumeProrated,
                let fwPercent = orderBook.fallwayPercent(forVolume: cVol)
                else { return nil }
        return  fwPercent
    }
    
    var currentPrice: Price? {
        guard let lastStick = self.candleSticks.last else { return nil }
        return lastStick.closePrice
    }

    func updateData(callback: @escaping () -> Void) {
        
        // use a dispatch group to keep track of what's been updated
        let dpG = DispatchGroup()
        
        dpG.enter()
        self.updateCandleSticks {
            self.updateOrderBook {
                dpG.leave()
            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            callback()
        }
    }
    
    private func updateCandleSticks(callback: @escaping () -> Void) {
        let pair = self.symbol.symbolPair
        let stickInterval = TradeStrategy.instance.candleStickPeriod
        BinanceAPI.instance.getCandleSticks(symbolPair: pair,
                                            interval: stickInterval,
                                            limit: 100) {
            (isSuccess, cSticks) in
            if isSuccess, let cSticks = cSticks {
                cSticks.calculateMACD()
                cSticks.calculateRSI()
                self.candleSticks = cSticks
                callback()
            } else {
                callback()
            }
        }
    }
    
    private func updateOrderBook(callback: @escaping () -> Void) {
        self.orderBook.updateData {
            callback()
        }
    }
}
