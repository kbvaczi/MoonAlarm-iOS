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
    
    func updateData(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeSession.instance.tradingPair
        BinanceAPI.instance.getOrderBook(symbolPair: symbolPair,
                                         limit: 30) {
            (isSuccess, oBook) in
            if isSuccess {
                self.asks = oBook.asks
                self.bids = oBook.bids
            }
            callback()
        }
    }

}
