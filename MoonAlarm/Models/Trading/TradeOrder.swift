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
    let quantityOrdered: Double                     // How many are we trying to buy/sell?
    let quantityVisible: Double?                    // Used for iceburg orders
    let timeInForce: BinanceAPI.TimeInForce         // assume processed immediately
    let startTime: Milliseconds = Date.currentTimeInMS
    
    // Mutating Properties //

    var uid: String? = nil                          // Generated by binance, set after processing
    var status: BinanceAPI.OrderStatus = .new       // Updated after processing
    var quantityFilled: Double = 0                  // Updated after processing
    var fills: TradeOrderFills = []                 // Keep track of individual fills
    var endTime: Milliseconds? = nil                // Keep track of when orders are finished
    
    /// Used for status updates
    private var updateTimer = Timer()
    
    /// Average fill price for this trade order, excluding fees
    var avgfillPrice: Price? {
        
        // Server says we've filled orders
        guard self.quantityFilled > 0 else { return nil }
    
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
    
    init(pair: String, side: BinanceAPI.OrderSide, type: BinanceAPI.OrderType = .market,
         price: Price? = nil, timeInForce: BinanceAPI.TimeInForce = .ioc,
         quantity: Double, qtyVisible: Double, isTest: Bool = true) {
        self.symbolPair = pair
        self.side = side
        self.type = type
        self.orderPrice = price
        self.timeInForce = timeInForce
        self.quantityOrdered = quantity
        self.quantityVisible = qtyVisible
        self.isTestOrder = isTest
    }
    
    // Methods //
    
    /// Execute this order by sending it for processing
    ///
    /// - Parameter callback: do this after processing
    func execute(callback: @escaping (_ isSuccess: Bool) -> Void) {
        guard self.status == .new else { callback(false); return }
        BinanceAPI.instance.postNewOrder(for: self) { (isSuccess, processedOrder) in
            guard isSuccess, processedOrder != nil else {
                callback(false)
                return
            }
            self.startRegularUpdates()
            callback(true)
        }
    }
    
    /// Cancel this order
    ///
    /// - Parameter callback: do this after cancellation
    func cancel(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        // No need to cancel an order that's already finalized
        guard !self.isFinalized else { callback(false); return }
        
        BinanceAPI.instance.cancelOrder(self) { (isSuccess, processedOrder) in
            
            guard isSuccess, processedOrder != nil else { callback(false); return }
            
            self.stopRegularUpdates()
            self.endTime = Date.currentTimeInMS
            
            callback(true)
        }
    }
    
    /// Query server and update order
    @objc func update(callback: @escaping (_ isSuccess: Bool) -> Void) {
        
        // No need to update an order that's already final
        guard !self.isFinalized else { callback(false); return }
        
        BinanceAPI.instance.getOrderUpdate(for: self) {
            (isSuccess, processedOrder) in
            
            guard isSuccess, processedOrder != nil else { callback(false); return }
            
            if self.isFinalized {
                self.stopRegularUpdates()
                self.endTime = Date.currentTimeInMS
            }
            
            callback(true)
        }
    }
    
    /// Update this order repeatedly on a regular interval
    private func startRegularUpdates() {
        self.updateTimer = Timer.scheduledTimer(timeInterval: 10, target: self,
                                                selector: #selector(self.update),
                                                userInfo: nil, repeats: true)
    }
    
    /// Stop regular updates to this order
    private func stopRegularUpdates() {
        self.updateTimer.invalidate()
    }

}
