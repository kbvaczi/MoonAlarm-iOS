//
//  SellOrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/3/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class SellOrderManager: OrderManager {
    
    /// Place a new order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("SellOrderManager(\(self.parentTrade.symbol)): Placing new order")
        
        /// Use orderbook to track other orders on this market
        let orderBook = self.parentTrade.marketSnapshot.orderBook
        /// Symbol we will use to buy/sell
        let symbolPair = self.parentTrade.symbol.symbolPair
        /// Exchange info we will use for lot size and price filter
        let exchangeInfo = TradeSession.instance.exchangeInfo
        
        // Verify we have orderbook data
        guard   let firstAskPrice = orderBook.firstAskPrice,
                let firstAskQty = orderBook.asks.first?.quantity
                else { callback(false); return }
        
        // Verify we have exchange information on this symbolpair
        let amountLeftToOrder = self.targetAmount - self.orders.amountFilled
        guard   var priceToList = exchangeInfo.nearestValidPrice(to: firstAskPrice,
                                                                 for: symbolPair),
            
                let amountToList = exchangeInfo.nearestValidAmount(to: amountLeftToOrder,
                                                                   for: symbolPair),
                let minNotionalValue = exchangeInfo.minNotionalValue(for: symbolPair)
                else { callback(false); return }
        
        // Verify amount left to order is not below min notional filter
        let tradeValue = amountToList * priceToList
        guard tradeValue > minNotionalValue else {
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Amount to list
                (\(amountToList.display8) @ \(priceToList.display8) less than min notional value
                (\(minNotionalValue.display8), stop new order
                """)
            callback(false); return
        }
        
        // If there much competition at current price point, let's buy a little higher
        if      firstAskQty > self.maxCompetitionAtPrice,
                let priceIncrement = exchangeInfo.priceTick(for: symbolPair) {
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Too much competition at first ask
                (\(firstAskQty.display8) @ \(firstAskPrice.display8)), decreasing sell price
                """)
            priceToList = firstAskPrice - priceIncrement
        }

        // Try an iceburg limit order by hiding most of our order, leaving just min notional
        let minAmountAtPrice = (minNotionalValue / priceToList) * 1.1 // Fudge factor
        var amtVisible = exchangeInfo.nearestValidAmount(to: minAmountAtPrice, for: symbolPair)
        if amtVisible != nil, amtVisible! >= amountToList { amtVisible = nil }
        
        let newOrder = TradeOrder(pair: symbolPair, side: .sell, type: .limit, price: priceToList,
                                  timeInForce: .gtc, amount: amountToList, amtVisible: amtVisible)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    SellOrderManager(\(self.parentTrade.symbol)): New sell order placed
                    @ \(priceToList.display8)
                    """)
                self.orders.append(newOrder)
                callback(true)
            }
        }
        
    }
    
    override func manageOrder(_ order: TradeOrder) {
        
        // If order is finished, stop managing orders
        guard   !order.isFinalized
                else {
            NSLog("SellOrderManager(\(self.parentTrade.symbol)): Order Finalized, stop managing")
            self.stopRegularUpdates()
            return
        }
        
        /// Use orderbook to track other orders on this market
        let orderBook = self.parentTrade.marketSnapshot.orderBook
        guard   let orderPrice = order.orderPrice,
                let competitionAmount = orderBook.amountAtOrBelowAsk(price: orderPrice)
                else {
                
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Error, no orderbook info,
                unable to manage order
                """)
            return
        }
        
        // do we need to decrease sell price to be competetive?
        if competitionAmount > self.maxCompetitionAtPrice {
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Too much competition @
                \(orderPrice.display8), replacing buy order
                """)
            self.replaceOrder(order)
        }
    }

}
