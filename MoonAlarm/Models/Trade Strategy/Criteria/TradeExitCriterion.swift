//
//  TradeExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeExitCriterion {
    
    // to be overridden by child classes
    var logMessage: String {
        return "Log Message Not Overridden"
    }
    
    // to be overridden by child classes
    // does this criteria pass based on provided market data?
    func passedFor(trade: Trade) -> Bool {
        print("passedFor method in TradeExitCriterion not overridden")
        return false
    }
    
    // to be overridden by child classes
    func copy() -> TradeExitCriterion {
        print("copy method in TradeExitCriterion not overridden")
        return TradeExitCriterion()
    }
    
}
