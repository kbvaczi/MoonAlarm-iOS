//
//  OrderManager.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/3/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class OrderManager {
    
    /// Trade we are managing orders for
    let parentTrade: Trade
    /// Target price for the asset we are trying to buy/sell
    let targetPrice: Price
    /// Amount of asset we want to buy/sell
    let targetAmount: Double
    
    ////////// SETTINGS //////////
    
    /// If market price moves more than this before target amount filled, stop issueing new orders
    let maxChangeToTargetPrice: Percent = 0.2
    /// We will share a spot on the order book with other orders up to this volume
    var maxCompetitionAtPrice: Double { return self.targetAmount }
    
    /// Orders we will be managing
    var orders: TradeOrders = []
    
    /// Used for status updates
    var updateTimer = Timer()
    
    /// Create a new OrderManager to manage orders for a trade
    ///
    /// - Parameters:
    ///   - price: Target price to buy/sell at
    ///   - amount: Target amount to buy/sell
    ///   - trade: Parent trade we're managing orders for
    init(price: Price, amount: Double, forTrade trade: Trade) {
        self.targetPrice = price
        self.targetAmount = amount
        self.parentTrade = trade
    }
    
    /// Place new order
    ///
    /// - Parameter callback: do this after order placed
    func placeNewOrder(callback: @escaping (_ isSuccess: Bool) -> Void) {
        NSLog("OrderManager(\(self.parentTrade.symbol): Error, placeNewOrder not overridden")
    }
    
    /// Manage order based on market conditions
    ///
    /// - Parameter order: order to manage
    func manageOrder(_ order: TradeOrder) {
        NSLog("OrderManager(\(self.parentTrade.symbol): Error, manageOrder not overridden")
    }
    
    /// Place an order and start managing
    func start() {
        self.placeNewOrder() { isSuccess in
            if isSuccess { self.startRegularUpdates() }
        }
    }
    
    /// Replace an order with a similar one at different price
    ///
    /// - Parameter order: order to replace
    func replaceOrder(_ order: TradeOrder) {
        order.cancel() { isSuccess in
            // have we bought/sold enough already?
            if isSuccess, self.orders.amountFilled < self.targetAmount {
                self.placeNewOrder() { isSuccess in
                    if isSuccess {
                        NSLog("OrderManager(\(self.parentTrade.symbol)): Order replaced")
                    }
                }
            }
        }
    }
    
    /// Cancel an order
    ///
    /// - Parameters:
    ///   - order: order to cancel
    ///   - callback: do this after order cancelled
    func cancelOrder(_ order: TradeOrder,
                     callback: @escaping (_ isSuccess: Bool) -> Void) {
        order.cancel() { isSuccess in
            NSLog("OrderManager(\(self.parentTrade.symbol): Order cancelled")
            callback(isSuccess)
        }
    }
    
    /// Update this order repeatedly on a regular interval
    func startRegularUpdates() {
        NSLog("OrderManager(\(self.parentTrade.symbol)): Start regular updates")
        self.updateTimer.invalidate()
        self.updateTimer = Timer.scheduledTimer(timeInterval: 15, target: self,
                                                selector: #selector(self.updateAndManageLastOrder),
                                                userInfo: nil, repeats: true)
    }
    
    /// Update last order and manage based on market conditions
    @objc private func updateAndManageLastOrder() {
        NSLog("OrderManager(\(self.parentTrade.symbol)): Updating")
        guard let lastOrder = self.orders.last else { return }
        lastOrder.update() { isSuccess in
            self.manageOrder(lastOrder)
        }
    }
    
    /// Stop regular updates to this order
    func stopRegularUpdates() {
        NSLog("OrderManager(\(self.parentTrade.symbol)): Stop regular updates")
        self.updateTimer.invalidate()
    }
    
}