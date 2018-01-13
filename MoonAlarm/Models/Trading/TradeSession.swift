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
    var tradeStrategy = TradeStrategy()
    private var updateTimer = Timer()
    
    var tradingPair = "BTC"
    var tradeAmountTarget: Double = 1
    var maxOpenTrades: Int = 3
    var trades = Trades()
    
    var status: Status = .running // TODO: implement toggle
    enum Status: String {
        case running = "Running"
        case stopped = "Stopped"
    }
    
    func start(callback: @escaping () -> Void) {
        self.status = .running
        TradeSession.instance.updateSymbols {
            self.startRepeatingSnapshotUpdates {
                callback()
            }
        }
    }
    
    func stop(callback: @escaping () -> Void) {
        self.status = .stopped
        self.stopRepeatingSnapshotUpdates()
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
            newSnapshot.updateData {
                self.marketSnapshots.append(newSnapshot)
                dpG.leave()
            }
        }
        
        // when all API calls are returned, run callback
        dpG.notify(queue: .main) {
            callback()
        }
    }
    
    func startRepeatingSnapshotUpdates(callback: @escaping () -> Void) {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.updateMarketSnapshots {
                callback()
            }
        }
    }
    
    func stopRepeatingSnapshotUpdates() {
        self.updateTimer.invalidate()
    }
    
    func investInWinners() {
        for snapshot in self.marketSnapshots {
            if  snapshot.volumeRatio1To15M! > 3 &&
                snapshot.tradesRatio1To15M! > 1.0 &&
                //snapshot.priceIncreasePercent3M > 0.1 &&
                snapshot.priceIsIncreasing! &&
                snapshot.volumeAvg15M! > (10 * self.tradeAmountTarget) &&
                !trades.openTradeFor(snapshot.symbol) &&
                trades.countOnly(status: .open) < self.maxOpenTrades {
                    let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot)
                    self.trades.append(newTrade)
                    newTrade.execute()
            }
        }
    }
    
}
