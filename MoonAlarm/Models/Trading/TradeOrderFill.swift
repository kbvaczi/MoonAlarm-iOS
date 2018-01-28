//
//  TradeOrderFill.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/28/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

/// Used to keep track of how much of an order was filled and at what price
struct TradeOrderFill {
    
    let price: Price            // Price at which this portion was filled
    let quantity: Double        // Amount filled
    let fee: Double             // Fee taken by exchange
    let feeAsset: Symbol        // What coin paid fee? Base asset or BNB?
    
    init(_ qty: Double, atPrice price: Price, fee: Double, feeAsset: Symbol) {
        self.price = price
        self.quantity = qty
        self.fee = fee
        self.feeAsset = feeAsset
    }
    
    /// Amount paid excluding fees
    var amountPaid: Double {
        return self.quantity * self.price
    }
    
}

//    Example JSON response from Binance:
//    "price": "3995.00000000",
//    "qty": "1.00000000",
//    "commission": "3.99500000",
//    "commissionAsset": "USDT"
