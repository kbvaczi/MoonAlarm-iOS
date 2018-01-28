//
//  Order.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/10/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class Order {
    
    let price: Price
    let quantity: Double
    
    init (price p: Double, quantity qty: Double ) {
        self.price = p
        self.quantity = qty
    }
    
}
