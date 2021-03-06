//
//  TradeOrder.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/21/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeOrder {
    
    // Fixed Properties //
    
    let symbolPair: String                          // What coin are we trading?
    let side: BinanceAPI.OrderSide                  // BUY or SELL
    let type: BinanceAPI.OrderType                  // LIMIT, MARKET currently supported
    let isTestOrder: Bool                           // Query test URL?
    let orderPrice: Price?                          // Not necessary for market orders
    let amountOrdered: Double                     // How many are we trying to buy/sell?
    let amountVisible: Double?                    // Used for iceburg orders
    let timeInForce: BinanceAPI.TimeInForce         // assume processed immediately
    let startTime: Milliseconds = Date.currentTimeInMS
    
    // Mutating Properties //

    var uid: String? = nil                          // Generated by binance, set after processing
    var status: BinanceAPI.OrderStatus = .new       // Updated after processing
    var amountFilled: Double = 0                  // Updated after processing
    var fills: TradeOrderFills = []                 // Keep track of individual fills
    var endTime: Milliseconds? = nil                // Keep track of when orders are finished
    
    /// Average fill price for this trade order, excluding fees
    var avgfillPrice: Price? {
        
        // Server says we've filled orders
        guard self.amountFilled > 0 else { return nil }
    
        // Limit order may not have fills, price is at limit price
        if  self.type == .limit,
            let price = self.orderPrice {
            return price
        }
        
        // Market order will have fills
        if self.type == .market {
            guard self.fills.count > 0 else { return nil }
            return fills.avgFillPrice
        }
        
        return nil  // Not sure
    }
    
    /// Determine if trade needs to be watched, or if it's finished
    var isFinalized: Bool {
        switch  self.status {
        case .filled, .cancelled, .rejected, .expired:
            return true
        default:
            return false
        }
    }
    
    // Initializers //
    
    /// Create a new order
    ///
    /// - Parameters:
    ///   - pair: trading pair to place order for
    ///   - side: buy or sell
    ///   - type: MARKET or LIMIT
    ///   - price: Buy/Sell price, only needed for limit orders
    ///   - timeInForce: execute immediately, or wait until filled
    ///   - amount: amount to buy/sell
    ///   - amtVisible: visible amount in orderbook, only for limit orders
    ///   - isTest: send to test URL, doesn't execute an order
    init(pair: String, side: BinanceAPI.OrderSide, type: BinanceAPI.OrderType = .market,
         price: Price? = nil, timeInForce: BinanceAPI.TimeInForce = .ioc,
         amount: Double, amtVisible: Double? = nil, isTest: Bool = false) {
        self.symbolPair = pair
        self.side = side
        self.type = type
        self.orderPrice = price
        self.timeInForce = timeInForce
        self.amountOrdered = amount
        self.amountVisible = amtVisible
        self.isTestOrder = isTest
    }
    
    // Methods //
    
    /// Execute this order by sending it for processing
    ///
    /// - Parameter callback: do this after processing
    func execute(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        // Cannot execute an order that's already been executed
        guard self.status == .new else { callback(true); return }
        
        BinanceAPI.instance.postNewOrder(for: self) { (isSuccess, processedOrder) in
            guard isSuccess, processedOrder != nil else {
                callback(false)
                return
            }
            callback(true)
        }
    }
    
    /// Cancel this order
    ///
    /// - Parameter callback: do this after cancellation
    func cancel(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        // No need to cancel an order that's already finalized
        guard !self.isFinalized else { callback(true); return }
        
        BinanceAPI.instance.cancelOrder(self) { (isSuccess, processedOrder) in
            
            guard isSuccess, processedOrder != nil else { callback(false); return }
            
            self.endTime = Date.currentTimeInMS
            
            callback(true)
        }
    }
    
    /// Query server and update order
    func update(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        // No need to update an order that's already final
        guard !self.isFinalized else { callback(true); return }
        
        BinanceAPI.instance.getOrderUpdate(for: self) {
            (isSuccess, processedOrder) in
            
            guard isSuccess, processedOrder != nil else { callback(false); return }
            
            if self.isFinalized {
                self.endTime = Date.currentTimeInMS
            }
            
            callback(true)
        }
    }
    


}
