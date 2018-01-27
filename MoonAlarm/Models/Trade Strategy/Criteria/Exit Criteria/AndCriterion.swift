//
//  AndCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/26/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class AndExit: TradeExitCriterion {
    
    var andCriteria: [TradeExitCriterion]
    
    override var logMessage: String {
        var logM = "And("
        for criterion in self.andCriteria {
            logM += criterion.logMessage + "; "
        }
        logM += ")"
        return logM
    }
    
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
            return true
        }
        
        return false
    }
    
    override func copy() -> AndExit {
        return AndExit(andCriteria)
    }
    
}
