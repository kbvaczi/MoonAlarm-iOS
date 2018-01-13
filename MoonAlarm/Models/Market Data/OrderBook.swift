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
    
    var topBid: Double? {
        guard bids.count > 0 else { return nil }
        return bids.first?.price
    }
    
    var firstAsk: Double? {
        guard asks.count > 0 else { return nil }
        return asks.first?.price
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
    
    func fallwayPrice(forVolume volume: Double) -> Double? {
        var fallwayVolume = volume
        var index = 0
        while fallwayVolume > 0 && index < bids.count {
            fallwayVolume -= bids[index].quantity
            index += 1
        }
        return index > 0 ? bids[index - 1].price : nil
    }
    
    func updateData(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeStrategy.instance.tradingPair
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
