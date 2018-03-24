//
//  SellOrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/3/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class SellOrderManager: OrderManager {
    
    /// Place a new limit sell order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewLimitOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("SellOrderManager(\(self.parentTrade.symbol)): Placing new limit order")
        
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
            callback(true); return
        }
        
        // If there much competition at current price point, let's sell a little lower
        if      let maxCompetition = self.minLimitOrderAmountAt(price: priceToList),
                firstAskQty > maxCompetition,
                let priceIncrement = exchangeInfo.priceTick(for: symbolPair) {
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Too much competition at first ask
                (\(firstAskQty.display8) @ \(firstAskPrice.display8)), decreasing sell price
                """)
            priceToList = firstAskPrice - priceIncrement
        }
        
        // Verify price hasn't gone down too far since initially trying to sell
        let percentBelowTargetPrice = (self.targetPrice / firstAskPrice - 1).doubleToPercent
        guard   percentBelowTargetPrice <= self.maxChangeToTargetPrice else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Price dropped too much
                (\(percentBelowTargetPrice)%%), force market sell
                """)
            self.placeNewMarketOrder() { isSuccess in
                callback(isSuccess)
            }
            return
        }
        
        // Try an iceburg limit order by hiding most of our order, leaving just min notional
        var amtVisible = self.minLimitOrderAmountAt(price: priceToList)
        if amtVisible ?? 0 >= amountToList { amtVisible = nil }
        
        let newOrder = TradeOrder(pair: symbolPair, side: .sell, type: .limit, price: priceToList,
                                  timeInForce: .gtc, amount: amountToList, amtVisible: amtVisible)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    SellOrderManager(\(self.parentTrade.symbol)): New sell order placed
                    @ \(priceToList.display8)
                    """)
                self.orders.append(newOrder)
            } else {
                NSLog("""
                    SellOrderManager(\(self.parentTrade.symbol)): New sell order FAILED
                    @ \(priceToList.display8)
                    """)
            }
            callback(isSuccess)
        }
    }
    
    /// Place a new market sell order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewMarketOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("SellOrderManager(\(self.parentTrade.symbol)): Placing new MARKET order")
        
        /// Symbol we will use to buy/sell
        let symbolPair = self.parentTrade.symbol.symbolPair
        /// Exchange info we will use for lot size and price filter
        let exchangeInfo = TradeSession.instance.exchangeInfo
        
        /// Amount we have left to sell, we will place sell order for all of the remaining amount
        let amountLeftToOrder = self.targetAmount - self.orders.amountFilled
        guard   let amountToList = exchangeInfo.nearestValidAmount(to: amountLeftToOrder,
                                                                   for: symbolPair)
                else { callback(false); return }

        let newOrder = TradeOrder(pair: symbolPair, side: .sell, type: .market,
                                  amount: amountToList)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    SellOrderManager(\(self.parentTrade.symbol)): New MARKET sell executed
                    at \((newOrder.avgfillPrice ?? 0.0).display8)
                    """)
                self.orders.append(newOrder)
                self.complete()
            } else {
                NSLog("""
                    SellOrderManager(\(self.parentTrade.symbol)): New MARKET sell FAILED
                    at \((newOrder.avgfillPrice ?? 0.0).display8)
                    """)
            }
            callback(isSuccess)
        }
    }
    
    override func manageOpenOrder() {
        
        // Skip update if there is no order
        guard   let order = self.orders.last else {
            NSLog("BuyOrderManager(\(self.parentTrade.symbol)): ERROR, No order to manage")
            return
        }
        
        // If order is finished, stop managing orders
        guard   !order.isFinalized else {
            NSLog("SellOrderManager(\(self.parentTrade.symbol)): Order Finalized, stop managing")
            self.complete()
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
        if      let maxCompetition = self.minLimitOrderAmountAt(price: orderPrice),
                competitionAmount > maxCompetition {
            
            NSLog("""
                SellOrderManager(\(self.parentTrade.symbol)): Too much competition @
                \(orderPrice.display8), replacing buy order
                """)
            self.replaceOrder(order)
        }
    }

}
