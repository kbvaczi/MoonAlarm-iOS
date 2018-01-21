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
        let sRate = completedTrades.map({ ($0.wasProfitable ?? false) ? 1 : 0 }).reduce(0) {$0 + $1 / Double(completedTrades.count)}
        return sRate.doubleToPercent
    }
    
    var totalProfitPercent: Percent {
        let completedTrades = self.filter { $0.status == .complete }
        let tPP = completedTrades.map({ $0.profitPercent ?? 0 }).reduce(0) { $0 + $1 }
        return tPP
    }
    
    func selectOnly(status: Trade.Status) -> Trades {
        let selection = self.filter { $0.status == status }
        return selection
    }
    
    func countOnly(status: Trade.Status) -> Int {
        let count = self.selectOnly(status: status).count
        return count
    }
    
    func openTradeFor(_ symbol: String) -> Bool {
        return self.filter({ $0.symbol == symbol && ($0.status == .open || $0.status == .draft) }).count > 0
    }
    
}
