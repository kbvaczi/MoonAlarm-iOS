//
//  OrderBook.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/10/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class OrderBook {

    let symbol: String
    var asks: [Order]
    var bids: [Order]
    
    init(symbol sym: String, asks a: [Order], bids b: [Order]) {
        self.symbol = sym
        self.asks = a
        self.bids = b
    }
    
    convenience init(symbol sym: String) {
        self.init(symbol: sym, asks: [Order](), bids: [Order]())
    }
    
    var topBidPrice: Double? {
        guard bids.count > 0 else { return nil }
        return bids.first?.price
    }
    
    var firstAskPrice: Double? {
        guard asks.count > 0 else { return nil }
        return asks.first?.price
    }
    
    var bidAskGapPercent: Percent? {
        guard   let topBid = self.topBidPrice,
                let firstAsk = self.firstAskPrice else { return nil }
        let gap = firstAsk - topBid
        return (gap / firstAsk - 1).doubleToPercent
    }
    
    func runwayPrice(forVolume volume: Double) -> Double? {
        var runwayVolume = volume
        var index = 0
        while runwayVolume > 0 && index < asks.count {
            runwayVolume -= asks[index].quantity
            index += 1
        }
        return index > 0 ? asks[index - 1].price : nil
    }
    
    func runwayPercent(forVolume volume: Double) -> Percent? {
        guard   let runwayPrice = self.runwayPrice(forVolume: volume),
                let firstAskPrice = self.firstAskPrice else { return nil }
            return (runwayPrice / firstAskPrice - 1).doubleToPercent
    }
    
    func fallwayPrice(forVolume volume: Double) -> Double? {
        var fallwayVolume = volume
        var index = 0
        while fallwayVolume > 0 && index < bids.count {
            fallwayVolume -= bids[index].quantity
            index += 1
        }
        return index > 0 ? bids[index - 1].price : nil
    }
    
    func fallwayPercent(forVolume volume: Double) -> Percent? {
        guard   let fallwayPrice = self.fallwayPrice(forVolume: volume),
                let firstAskPrice = self.firstAskPrice else { return nil }
        return (firstAskPrice / fallwayPrice - 1).doubleToPercent
    }
    
    func updateData(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeStrategy.instance.tradingPairSymbol
        BinanceAPI.instance.getOrderBook(symbolPair: symbolPair,
                                         limit: 50) {
            (isSuccess, oBook) in
            if isSuccess {
                self.asks = oBook.asks
                self.bids = oBook.bids
            }
            callback()
        }
    }

}
