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
    
    /// Overall success rate of trades, success = profitable
    var successRate: Percent {
        let completedTrades = self.filter { $0.status == .complete }
        let sRate = completedTrades.map({ ($0.wasProfitable ?? false) ? 1 : 0 })
                                   .reduce(0) {$0 + $1 / Double(completedTrades.count)}
        return sRate.doubleToPercent
    }
    
    /// Total percent profit of trades
    var totalProfitPercent: Percent {
        let completedTrades = self.filter { $0.status == .complete }
        let tPP = completedTrades.map({ $0.profitPercent ?? 0 }).reduce(0) { $0 + $1 }
        return tPP
    }
    
    /// Returns a filtered list of trades by status
    ///
    /// - Parameter status: status to filter for
    /// - Returns: trades that have this status currently
    func filterOnly(status: Trade.Status) -> Trades {
        let selection = self.filter { $0.status == status }
        return selection
    }
    
    /// Filters trades, showing only open trades
    ///
    /// - Returns: open trades
    func filterOnlyOpen() -> Trades {
        let selection = self.filter { trade in
            trade.status.isOpen
        }
        return selection
    }
    
    /// Filters trades, showing only complete trades
    ///
    /// - Returns: complete trades
    func filterOnlyComplete() -> Trades {
        let selection = self.filter { trade in
            !trade.status.isOpen
        }
        return selection
    }
    
    /// Counts the number of trades with a given status
    ///
    /// - Parameter status: status to look for
    /// - Returns: number of trades of given status
    func countOnly(status: Trade.Status) -> Int {
        let count = self.filterOnly(status: status).count
        return count
    }
    
    /// Counts the number of trades that are open
    ///
    /// - Returns: number of open trades
    func countOpen() -> Int {
        let count = self.filterOnlyOpen().count
        return count
    }
    
    /// Counts the number of trades that are complete
    ///
    /// - Returns: number of complete trades
    func countComplete() -> Int {
        let count = self.filterOnlyComplete().count
        return count
    }
    
    /// Determines if there is an open trade for a given symbol
    ///
    /// - Parameter symbol: symbol to search for
    /// - Returns: true if there is an open trade for symbol, false otherwise
    func openTradeFor(_ symbol: String) -> Bool {
        return self.filter({ $0.symbol == symbol && $0.status.isOpen }).count > 0
    }
    
}
