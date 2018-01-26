//
//  AndCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/26/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class AndCriterion: TradeExitCriterion {
    
    var andCriteria: [TradeExitCriterion]
    
    init(_ criteria: [TradeExitCriterion]) {
        self.andCriteria = criteria
    }
    
    override func passedFor(trade: Trade) -> Bool {
        
        var allCriteriaPassed = true
        for criterion in self.andCriteria {
            if criterion.passedFor(trade: trade) == false {
                allCriteriaPassed = false
            }
        }
        
        if allCriteriaPassed {
            print("\(trade.symbol): And Criterion Passed")
            return true
        }
        
        return false
    }
    
    override func copy() -> AndCriterion {
        return AndCriterion(andCriteria)
    }
    
}
