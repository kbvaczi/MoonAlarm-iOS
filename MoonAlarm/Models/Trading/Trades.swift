//
//  Trades.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias Trades = Array<Trade>

extension Array where Element : Trade {
    
    var successRate: Percent {
        let completedTrades = self.filter { $0.status == .complete }
        let sRate = completedTrades.map({ $0.wasProfitable ? 1 : 0 }).reduce(0) {$0 + $1 / Double(completedTrades.count)}
        return sRate.toPercent()
    }
    
    func countOnly(status: Trade.Status) -> Int {
        let count = self.filter { $0.status == status }.count
        return count
    }
    
    func openTradeFor(_ symbol: String) -> Bool {
        return self.filter({ $0.symbol == symbol && ($0.status == .open || $0.status == .draft) }).count > 0
    }
    
}
