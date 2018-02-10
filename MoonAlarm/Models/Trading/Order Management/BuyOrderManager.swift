//
//  BuyOrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/2/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class BuyOrderManager: OrderManager {
    
    /// Place a new order
    ///
    /// - Parameter callback: do this after placing order
    override func placeNewOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Placing new order")
        
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
            callback(false); return
        }
        
        // If there much competition at current price point, let's buy a little higher
        if      topBidQty > self.maxCompetitionAtPrice,
                let priceIncrement = exchangeInfo.priceTick(for: symbolPair) {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Too much competition at top bid
                (\(topBidQty.display8) @ \(topBidPrice.display8)), increasing buy price
                """)
            priceToList = topBidPrice + priceIncrement
        }
        
        // Verify price hasn't increased too much prior to filling our target amount
        let percentOverTarget = (priceToList / self.targetPrice - 1).doubleToPercent
        guard percentOverTarget <= self.maxChangeToTargetPrice else { callback(false); return }
        
        // Try an iceburg limit order by hiding most of our order, leaving just min notional
        let minAmountAtPrice = (minNotionalValue / priceToList) * 1.1 // Fudge factor
        var amtVisible = exchangeInfo.nearestValidAmount(to: minAmountAtPrice, for: symbolPair)
        if amtVisible != nil, amtVisible! >= amountToList { amtVisible = nil }
        
        let newOrder = TradeOrder(pair: symbolPair, side: .buy, type: .limit, price: priceToList,
                               timeInForce: .gtc, amount: amountToList, amtVisible: amtVisible)
        
        newOrder.execute() { isSuccess in
            if isSuccess {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New buy order placed
                    @ \(priceToList.display8)
                    """)
                self.orders.append(newOrder)
                callback(true)
            }
        }
    }
    
    /// Manage open order based on market conditions
    override func manageOpenOrder() {
        
        // If order is finished, stop managing orders
        guard   let order = self.orders.last,
                !order.isFinalized else {
            NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Order Finalized, stop managing")
            self.stopRegularUpdates()
            return
        }
        
        /// Use orderbook to track other orders on this market
        let orderBook = self.parentTrade.marketSnapshot.orderBook
        guard   let orderPrice = order.orderPrice,
                let topBid = orderBook.topBidPrice,
                let competitionAmount = orderBook.amountAtOrAboveBid(price: orderPrice)
                else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Error, no orderbook info,
                unable to manage order
                """)
            return
        }
        
        // Verify price hasn't gone up too far since initially trying to purchase
        let percentAboveTargetPrice = (topBid / self.targetPrice - 1).doubleToPercent
        guard   percentAboveTargetPrice <= self.maxChangeToTargetPrice else {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Price got too expensive
                (\(percentAboveTargetPrice)%), stop placing new buy orders
                """)
            cancelOrder(order) { isSuccess in
                if isSuccess { self.stopRegularUpdates() }
            }
            return
        }
        
        // do we need to increase bid price to be competetive?
        if competitionAmount > self.maxCompetitionAtPrice {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Too much competition @
                \(orderPrice.display8), replacing buy order
                """)
            self.replaceOrder(order)
        }
    }
    
    /// Cancel last order if it is open
    ///
    /// - Parameter callback: do this after cancelling order
    func cancelOpenOrder(callback: @escaping (_ isSuccess: Bool) -> Void ) {
        
        // Verify order needs to be canceled
        guard   let orderToCancel = self.orders.last,
                !orderToCancel.isFinalized
                else { callback(true); return }
        
        self.cancelOrder(orderToCancel) { isSuccess in
            if isSuccess { self.stopRegularUpdates() }
            callback(isSuccess)
        }
    }
    
}
