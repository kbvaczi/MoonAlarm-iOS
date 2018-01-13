//
//  TradeStrategy.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeStrategy {
    
    var entranceCriteria = TradeEnterCriteria()
    var exitCriteria = TradeExitCriteria()
    
    init() { }
    
    func entranceCriteriaPassed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        return entranceCriteria.passed(usingSnapshot: mSnapshot)
    }
    
    func exitCriteriaPassed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        return exitCriteria.passed(usingSnapshot: mSnapshot)
    }
}
