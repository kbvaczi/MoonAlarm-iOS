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
    
    // allPassedFor
    // using all criterion, should we enter this trade?
    func allPassedFor(_ snapshot: MarketSnapshot) -> Bool {
        // If there are no criterion, criteria does not pass
        guard self.count > 0 else { return false }
        
        // All criterion must pass to enter a trade (conservative)
        let answers = self.map() { $0.passedFor(snapshot: snapshot) }
        return answers.reduce(true, { $0 && $1 })
    }
    
}

typealias TradeExitCriteria = Array<TradeExitCriterion>

extension Array where Element : TradeExitCriterion {
    
    // onePassedFor
    // using all criterion, should we exit this trade?
    func onePassedFor(_ trade: Trade) -> Bool {
        // If there are no criterion, criteria does not pass
        guard self.count > 0 else { return false }

        // only one criterion must pass to exit a trade (conservative)
        let answers = self.map() { $0.passedFor(trade: trade) }
        let onePassed = answers.reduce(false, { $0 || $1 })
        if onePassed {
            logPassedFor(trade)
            return true
        }
        return false
    }
    
    private func logPassedFor(_ trade: Trade) {
        var logMessage = "\(trade.symbol) Exit Criteria: "
        for criterion in self {
            if criterion.passedFor(trade: trade) {
                logMessage += "\(criterion.logMessage); "
            }
        }
        print(logMessage)
    }
    
    func copy() -> TradeExitCriteria {
        var copy = TradeExitCriteria()
        for criterion in self {
            copy.append(criterion.copy())
        }
        return copy        
    }
    
}
