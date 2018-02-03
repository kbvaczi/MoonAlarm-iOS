//
//  TradeOrders.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/21/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias TradeOrders = Array<TradeOrder>

extension Array where Element : TradeOrder {
    
    /// Amount of coins purchased/sold across all trade orders
    var amountFilled: Double {
        return self.map({ order in order.amountFilled }).reduce(0, +)
    }
    
    /// Total amount of tradingPair coins paid across all trade orders
    var totalPaid: Double {
        return self.map({ order in
            if let fillPrice = order.avgfillPrice {
                return fillPrice * order.amountFilled
            } else {
                return 0
            }
        }).reduce(0, +)
    }
    
    /// Average fill price for all orders
    var avgfillPrice: Price? {
        
        // Verify we have filled orders
        let amountFilled = self.amountFilled
        guard  amountFilled > 0 else { return nil }
        
        return self.totalPaid / amountFilled
    }
    
    /// Determine if all orders are finalized
    var allFinalized: Bool {
        return self.map({ order in
            order.isFinalized
        }).reduce(true, { $0 && $1 })
    }
    
}

