//
//  BuyOrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/2/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class BuyOrderManager: OrderManager {
    
    /// Place a new limit buy order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewLimitOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Placing new limit order")
        
        /// Use orderbook to track other orders on this market
        let orderBook = self.parentTrade.marketSnapshot.orderBook
        /// Symbol we will use to buy/sell
        let symbolPair = self.parentTrade.symbol.symbolPair
        /// Exchange info we will use for lot size and price filter
        let exchangeInfo = TradeSession.instance.exchangeInfo

        // Verify we have orderbook data
        guard   let topBidPrice = orderBook.topBidPrice,
                let topBidQty = orderBook.bids.first?.quantity
                else { callback(false); return }
        
        // Verify we have exchange information on this symbolpair
        let amountLeftToOrder = self.targetAmount - self.orders.amountFilled
        guard   var priceToList = exchangeInfo.nearestValidPrice(to: topBidPrice,
                                                                 for: symbolPair),
            
                let amountToList = exchangeInfo.nearestValidAmount(to: amountLeftToOrder,
                                                                   for: symbolPair),
                let minNotionalValue = exchangeInfo.minNotionalValue(for: symbolPair)
                else { callback(false); return }
        
        // Verify amount left to order is not below min notional filter
        let tradeValue = amountToList * priceToList
        guard tradeValue > minNotionalValue else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Amount to list
                (\(amountToList.display8)) less than min notional (\(minNotionalValue.display8),
                stop new order
                """)
            callback(true); return
        }
        
        // If there much competition at current price point, let's buy a little higher
        if      let maxCompetition = self.minLimitOrderAmountAt(price: priceToList),
                topBidQty > maxCompetition,
                let priceIncrement = exchangeInfo.priceTick(for: symbolPair) {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Too much competition at top bid
                (\(topBidQty.display8) @ \(topBidPrice.display8)), increasing buy price
                """)
            priceToList = topBidPrice + priceIncrement
        }
        
        // Verify price hasn't increased too much prior to filling our target amount
        // Execute market order if price continues to increase
        let percentOverTarget = (priceToList / self.targetPrice - 1).doubleToPercent
        guard percentOverTarget <= self.maxChangeToTargetPrice else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Price got too expensive
                (\(percentOverTarget)%%), execute market order
                """)
            self.placeNewMarketOrder() { isSuccess in
                callback(isSuccess)
            }
            return
        }
        
        // Try an iceburg limit order by hiding most of our order, leaving just min notional
        var amtVisible = self.minLimitOrderAmountAt(price: priceToList)
        if amtVisible ?? 0 >= amountToList { amtVisible = nil }
        
        let newOrder = TradeOrder(pair: symbolPair, side: .buy, type: .limit, price: priceToList,
                               timeInForce: .gtc, amount: amountToList, amtVisible: amtVisible)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New buy order placed
                    @ \(priceToList.display8)
                    """)
                self.orders.append(newOrder)
            } else {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New buy order FAILED
                    @ \(priceToList.display8)
                    """)
            }
            callback(isSuccess)
        }
    }
    
    /// Place a new market buy order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewMarketOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Placing new MARKET order")
        
        /// Symbol we will use to buy/sell
        let symbolPair = self.parentTrade.symbol.symbolPair
        /// Exchange info we will use for lot size and price filter
        let exchangeInfo = TradeSession.instance.exchangeInfo
        
        /// Amount we have left to buy, we will place buy order for all of the remaining amount
        let amountLeftToOrder = self.targetAmount - self.orders.amountFilled
        guard   let amountToBuy = exchangeInfo.nearestValidAmount(to: amountLeftToOrder,
                                                                  for: symbolPair)
                else { callback(false); return }
        
        let newOrder = TradeOrder(pair: symbolPair, side: .buy, type: .market, amount: amountToBuy)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New MARKET buy executed
                    at \((newOrder.avgfillPrice ?? 0.0).display8)
                    """)
                self.orders.append(newOrder)
                self.complete()
            } else {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New MARKET buy FAILED
                    at \((newOrder.avgfillPrice ?? 0.0).display8)
                    """)
            }
            callback(isSuccess)
        }
    }
    
    /// Manage open order based on market conditions
    override func manageOpenOrder() {
        
        // Skip update if there is no order
        guard   let order = self.orders.last else {
            NSLog("BuyOrderManager(\(self.parentTrade.symbol)): ERROR, No order to manage")
            return
        }
        
        // If order is finished, stop managing orders
        guard   !order.isFinalized else {
            NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Order Finalized, stop managing")
            self.complete()
            return
        }
        
        /// Use orderbook to track other orders on this market
        let orderBook = self.parentTrade.marketSnapshot.orderBook
        guard   let orderPrice = order.orderPrice,
                let competitionAmount = orderBook.amountAtOrAboveBid(price: orderPrice)
                else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Error, no orderbook info,
                unable to manage order
                """)
            return
        }
        
        // do we need to increase bid price to be competetive?
        if      let maxCompetition = self.minLimitOrderAmountAt(price: orderPrice),
                competitionAmount > maxCompetition {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Too much competition @
                \(orderPrice.display8), replacing buy order
                """)
            self.replaceOrder(order)
        }
    }
    
    /// Cancel last order if it is open, stop order management
    ///
    /// - Parameter callback: do this after
    func cancelOpenOrderAndStopBuying(callback: @escaping (_ isSuccess: Bool) -> Void ) {
        
        // Verify order needs to be cancelled
        guard   let orderToCancel = self.orders.last else {
            NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Error, no order to cancel")
            callback(false)
            return
        }
        
        guard   !orderToCancel.isFinalized else { callback(true); return }
        
        self.cancelOrder(orderToCancel) { isSuccess in
            if isSuccess { self.complete() }
            callback(isSuccess)
        }
    }
    
}
