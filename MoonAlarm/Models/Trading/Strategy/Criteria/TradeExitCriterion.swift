//
//  TradeExitCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeExitCriterion {
    
    // passed Method
    // to be overridden by child classes
    // does this criteria pass based on provided market data?
    func passed(usingTrade trade: Trade) -> Bool {
        return false
    }
    
}
