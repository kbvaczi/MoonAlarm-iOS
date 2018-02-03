//
//  BuyOrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/2/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class BuyOrderManager {
    
    /// Wrade we are managing orders for
    let parentTrade: Trade
    /// Target price for the asset we are trying to buy
    let targetPrice: Price
    /// Amount of asset we want to buy
    let targetAmount: Double
    
    ////////// SETTINGS //////////
    
    /// If market price moves more than this before target amount filled, stop issueing new orders
    let maxChangeToTargetPrice: Percent = 0.2
    /// We will share a spot on the order book with other orders up to this volume
    var maxCompetitionAtPrice: Double { return self.targetAmount }
    
    /// Orders we will be managing
    var orders: TradeOrders = []
    
    /// Used for status updates
    private var updateTimer = Timer()
    
    init(price: Price, amount: Double, forTrade trade: Trade) {
        self.targetPrice = price
        self.targetAmount = amount
        self.parentTrade = trade
    }
    
    /// Start managing buy orders
    func execute() {
        self.placeNewOrder() { isSuccess in
            if isSuccess { self.startRegularUpdates() }
        }
    }
    
    /// Place a new order
    ///
    /// - Parameter callback: do this after placing order
    func placeNewOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
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
                (\(amountToList.toDisplay)) less than min notional (\(minNotionalValue.toDisplay),
                stop new order
                """)
            callback(false); return
        }
        
        // If there much competition at current price point, let's buy a little higher
        if      topBidQty > self.maxCompetitionAtPrice,
                let priceIncrement = exchangeInfo.priceTick(for: symbolPair) {
            NSLog("""
                BuyOrderManager(\(self.parentTrade.symbol)): Too much competition at top bid
                (\(topBidQty.toDisplay) @ \(topBidPrice.toDisplay)), increasing buy price
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
        
        newOrder.execute(){ isSuccess in
            if isSuccess {
                NSLog("""
                    BuyOrderManager(\(self.parentTrade.symbol)): New buy order placed
                    @ \(priceToList.toDisplay)
                    """)
                self.orders.append(newOrder)
                callback(true)
            }
        }
        
    }
    
    private func replaceOrder(_ order: TradeOrder) {
        order.cancel() { isSuccess in
            // have we bought enough already?
            if isSuccess, self.orders.amountFilled < self.targetAmount {
                self.placeNewOrder() { isSuccess in
                    if isSuccess {
                        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Buy order replaced")
                    }
                }
            }
        }
    }
    
    private func cancelOrder(_ order: TradeOrder,
                             callback: @escaping (_ isSuccess: Bool) -> Void) {
        order.cancel() { isSuccess in
            NSLog("BuyOrderManager(\(self.parentTrade.symbol): Order cancelled")
            callback(isSuccess)
        }
    }
    
    private func manageOrder(_ order: TradeOrder) {
        
        // If order is finished, stop managing orders
        guard   !order.isFinalized else {
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
                \(orderPrice.toDisplay), replacing buy order
                """)
            self.replaceOrder(order)
        }
    }
    
    /// Update this order repeatedly on a regular interval
    private func startRegularUpdates() {
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Start regular updates")
        self.updateTimer.invalidate()
        self.updateTimer = Timer.scheduledTimer(timeInterval: 15, target: self,
                                                selector: #selector(self.updateAndManage),
                                                userInfo: nil, repeats: true)
    }
    
    @objc private func updateAndManage() {
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Updating")
        guard let lastOrder = self.orders.last else { return }
        lastOrder.update() { isSuccess in
            self.manageOrder(lastOrder)
        }
    }
    
    /// Stop regular updates to this order
    private func stopRegularUpdates() {
        NSLog("BuyOrderManager(\(self.parentTrade.symbol)): Stop regular updates")
        self.updateTimer.invalidate()
    }
    
    
    
}
