//
//  TradeSession.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeSession {
    
    // singleton
    static let instance = TradeSession()
    
    // prohibit instances of this class from being declared
    private init() { }
    
    var symbols = [String]()
    var marketSnapshots = MarketSnapshots()
    var updateTimer = Timer()
    
    var tradingPair = "ETH"
    var tradeAmountTarget: Double = 1
    var maxOpenTrades: Int = 8
    var status: Status = .running // TODO: implement toggle
    
    var trades = Trades()
    
    enum Status: String {
        case running = "Running"
        case stopped = "Stopped"
    }
    
    func updateSymbols(callback: @escaping () -> Void) {
        BinanceAPI.instance.getAllSymbols() { (isSuccess, newSymbols) in
            if isSuccess {
                self.symbols = newSymbols
                callback()
            }
        }
    }
    
    func updateMarketSnapshots(callback: @escaping () -> Void) {
        print("updating market snapshots")
        
        // remove outdated information
        TradeSession.instance.marketSnapshots.removeAll()
        
        // use a dispatch group to keep track of how many symbols we've updated
        let dpG = DispatchGroup()
        
        for symbol in symbols {
            dpG.enter() // enter dispatch queue
            let newSnapshot = MarketSnapshot(symbol: symbol)
            newSnapshot.update {
                self.marketSnapshots.append(newSnapshot)
                dpG.leave()
            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            self.marketSnapshots.sort(by: { $0.volumeRatio1To15M > $1.volumeRatio1To15M })
            callback()
        }
    }
    
    func investInWinners() {
        for snapshot in self.marketSnapshots {
            if  snapshot.volumeRatio1To15M > 3 &&
                snapshot.tradesRatio1To15M > 1.5 &&
                snapshot.priceIncreasePercent3M > 0.01 &&
                snapshot.priceIsIncreasing &&
                snapshot.volumeAvg15M > (25 * self.tradeAmountTarget) &&
                !trades.openTradeFor(snapshot.symbol) &&
                trades.countOnly(status: .open) < self.maxOpenTrades {
                    let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot)
                    self.trades.append(newTrade)
                    newTrade.execute()
            }
        }
    }
    
}
