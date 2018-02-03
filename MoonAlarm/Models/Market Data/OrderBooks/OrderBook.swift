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
    
    ////////// PRICING //////////
    
    var topBidPrice: Price? {
        guard bids.count > 0 else { return nil }
        return bids.first?.price
    }
    
    var firstAskPrice: Price? {
        guard asks.count > 0 else { return nil }
        return asks.first?.price
    }
    
    var bidAskGapPercent: Percent? {
        guard   let topBid = self.topBidPrice,
                let firstAsk = self.firstAskPrice else { return nil }
        let gap = firstAsk - topBid
        return (gap / firstAsk - 1).doubleToPercent
    }
    
    /// Returns amount of coins listed for purchase at or above given price
    ///
    /// - Parameter price: given price
    /// - Returns: amount for purchase at or above given price
    func amountAtOrAboveBid(price: Price) -> Double? {
        return self.bids.filter({ $0.price >= price }).map({ $0.quantity }).reduce(0, +)
    }
    
    /// Returns amount of coins listed for sale at or below given price
    ///
    /// - Parameter price: given price
    /// - Returns: amount for sale at or below given price
    func amountAtOrBelowAsk(price: Price) -> Double? {
        return self.asks.filter({ $0.price <= price }).map({ $0.quantity }).reduce(0, +)
    }
    
    ////////// RUNWAY / FALLWAY PRICING //////////
    
    func runwayPrice(forVolume volume: Double) -> Double? {
        return  self.edgePrice(forVolume: volume, orders: asks)
    }
    
    func fallwayPrice(forVolume volume: Double) -> Double? {
        return  self.edgePrice(forVolume: volume, orders: bids)
    }
    
    private func edgePrice(forVolume volume: Double, orders: [Order]) -> Double? {
        var volumeCounter = volume
        var index = 0
        while volumeCounter > 0 && index < orders.count {
            volumeCounter -= orders[index].quantity
            index += 1
        }
        return index > 0 ? orders[index - 1].price : nil
    }
    
    func runwayPercent(forVolume volume: Double) -> Percent? {
        guard   let runwayPrice = self.runwayPrice(forVolume: volume),
                let firstAskPrice = self.firstAskPrice else { return nil }
        
        return (runwayPrice / firstAskPrice - 1).doubleToPercent
    }
    
    func fallwayPercent(forVolume volume: Double) -> Percent? {
        guard   let fallwayPrice = self.fallwayPrice(forVolume: volume),
                let topBidPrice = self.topBidPrice else { return nil }
        
        return (topBidPrice / fallwayPrice - 1).doubleToPercent
    }
    
    ////////// MARKET BUY/SELL AVERAGE PRICING //////////
    
    func marketBuyPrice(forPairVolume volume: Double) -> Double? {
        return self.marketPriceAvg(forPairVolume: volume, orders: self.asks)
    }
    
    func marketSellPrice(forPairVolume volume: Double) -> Double? {
        return self.marketPriceAvg(forPairVolume: volume, orders: self.bids)
    }
    
    private func marketPriceAvg(forPairVolume volume: Double, orders: [Order]) -> Double? {
        var pairVolumeCounter = volume
        var marketOrders = [Order]()
        var index = 0
        while pairVolumeCounter > 0 && index < orders.count {
            let currentOrder = orders[index]
            let pairQuantity = currentOrder.price * currentOrder.quantity
            if pairVolumeCounter > pairQuantity {
                marketOrders.append(Order(price: currentOrder.price,
                                          quantity: currentOrder.quantity))
            } else {
                let quantityLeft = pairVolumeCounter / currentOrder.price
                marketOrders.append(Order(price: currentOrder.price,
                                          quantity: quantityLeft))
            }
            pairVolumeCounter -= pairQuantity
            index += 1
        }
        // Able to statisfuly entire order using orderbook
        guard pairVolumeCounter <= 0 else { return nil }
        
        let totalOrdersQuantity = marketOrders.map({$0.quantity}).reduce(0, +)
        let orderAvgPrice = marketOrders.map({ $0.price * $0.quantity }).reduce(0, +) / totalOrdersQuantity
        return orderAvgPrice
    }
    
    ////////// UPDATING DATA //////////
    
    func updateData(callback: @escaping () -> Void) {
        let symbolPair = self.symbol + TradeStrategy.instance.tradingPairSymbol
        BinanceAPI.instance.getOrderBook(symbolPair: symbolPair,
                                         limit: 50) {
            (isSuccess, oBook) in
            if isSuccess, let oBook = oBook {
                self.asks = oBook.asks
                self.bids = oBook.bids
            }
            callback()
        }
    }

}
