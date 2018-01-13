//
//  TradeEnterCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeEnterCriterion {

    // passed Method
    // to be overridden by child classes
    // does this criteria pass based on provided market data?
    func passedFor(snapshot: MarketSnapshot) -> Bool {
        return false
    }
    
}
