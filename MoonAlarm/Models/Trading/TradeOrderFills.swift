//
//  TradeOrderFills.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/28/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias TradeOrderFills = Array<TradeOrderFill>

// MARK: - Extend Array so we can do calculations on groups of elements
extension Array where Iterator.Element == TradeOrderFill {
    
    /// Average fill price for multiple fills excluding fees
    var avgFillPrice: Price {
        return self.totalAmountPaid / self.totalFillQuantity
    }
    
    /// Quantity that has been filled at this time
    var totalFillQuantity: Double {
        return self.map({$0.quantity}).reduce(0, +)
    }
    
    /// Total amount paid in all fills excluding fees
    private var totalAmountPaid: Double {
        return self.map({$0.amountPaid}).reduce(0, +)
    }
    
}
