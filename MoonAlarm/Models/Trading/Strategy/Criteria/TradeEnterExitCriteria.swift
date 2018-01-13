//
//  TradeEnterExitCriteria.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias TradeEnterCriteria = Array<TradeEnterCriterion>

extension Array where Element : TradeEnterCriterion {
    
    // allPassed
    // using all criterion, should we enter/exit this trade?
    func allPassed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        // If there are no criterion, criteria does not pass
        guard self.count > 0 else { return false }
        
        // All criterion must pass to enter a trade (conservative)
        let answers = self.map() { $0.passed(usingSnapshot: mSnapshot) }
        return answers.reduce(true, { $0 && $1 })
    }
    
}

typealias TradeExitCriteria = Array<TradeExitCriterion>

extension Array where Element : TradeExitCriterion {
    
    // allPassed
    // using all criterion, should we enter/exit this trade?
    func onePassed(usingTrade trade: Trade) -> Bool {
        // If there are no criterion, criteria does not pass
        guard self.count > 0 else { return false }

        // only one criterion must pass to exit a trade (conservative)
        let answers = self.map() { $0.passed(usingTrade: trade) }
        return answers.reduce(true, { $0 || $1 })
    }
    
}
