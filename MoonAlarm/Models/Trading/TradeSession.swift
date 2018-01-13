//
//  TradeSession.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/9/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class TradeSession {
    
    static let instance = TradeSession() // singleton
    private init() { } // prohibit instances of this class from being declared
    
    // Market Data //
    var symbols = [String]()
    var marketSnapshots = MarketSnapshots()
    var exchangeClock = ExchangeClock()
    private var updateTimer = Timer() // Timer that periodically updates market data
    

    var trades = Trades()
    
    // Conditions //
    var status: Status = .running // TODO: implement toggle
    enum Status: String {
        case running = "Running"
        case stopped = "Stopped"
    }
    
    func start(callback: @escaping () -> Void) {
        self.status = .running
        exchangeClock.startRegularSync()
        TradeSession.instance.updateSymbols {
            self.startRegularSnapshotUpdates {
                callback()
            }
        }
    }
    
    func stop(callback: @escaping () -> Void) {
        self.status = .stopped
        self.stopRegularSnapshotUpdates()
        exchangeClock.stopRegularSync()
    }
    
    func updateSymbols(callback: @escaping () -> Void) {
        let tradingPairSymbol = TradeStrategy.instance.tradingPairSymbol
        BinanceAPI.instance.getAllSymbols(forTradingPair: tradingPairSymbol) { (isSuccess, newSymbols) in
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
    
    func startRegularSnapshotUpdates(callback: @escaping () -> Void) {
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
            guard self.trades.countOnly(status: .open) < maxOpenTrades else { return }
            self.updateMarketSnapshots {
                self.marketSnapshots.sort { $0.volumeRatio1To15M ?? 0 > $1.volumeRatio1To15M ?? 0 }
                callback()
            }
        }
    }
    
    func stopRegularSnapshotUpdates() {
        self.updateTimer.invalidate()
    }
    
    func investInWinners() {
        for snapshot in self.marketSnapshots {
            // don't start any more trades if we've maxed out
            let maxOpenTrades = TradeStrategy.instance.maxOpenTrades
            guard trades.countOnly(status: .open) < maxOpenTrades else { return }
            
            // only one trade open per symbol at a time
            if trades.openTradeFor(snapshot.symbol) { continue }
            
            // only trade if the market snapshot passes our trade enter criteria
            if TradeStrategy.instance.entranceCriteria.allPassedFor(snapshot) {
                let newTrade = Trade(symbol: snapshot.symbol, snapshot: snapshot)
                self.trades.append(newTrade)
                newTrade.execute()
            }
        }
    }
    
}
