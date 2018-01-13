//
//  ExchangeClock.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/13/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation
import QuartzCore

class ExchangeClock {
    
    private var lastSyncLocalTime: Milliseconds
    private var lastSyncServerTime: Milliseconds
    
    private var syncTimer = Timer()
    
    var currentTime: Milliseconds {
        let currentLocalTime = Date().millisecondsSince1970
        let timeSinceLastSync = currentLocalTime - self.lastSyncLocalTime
        return timeSinceLastSync + lastSyncServerTime
    }
    
    private init(serverTime: Milliseconds, localTime: Milliseconds) {
        self.lastSyncServerTime = serverTime
        self.lastSyncLocalTime = localTime
    }
    
    convenience init() {
        self.init(serverTime: 0, localTime: 0)
        syncTimeWithServer()
        startRegularSync()
    }
    
    private func syncTimeWithServer() {
        self.lastSyncLocalTime = Date().millisecondsSince1970
        BinanceAPI.instance.getCurrentServerTime(callback: { isSuccess, serverTime in
            self.lastSyncServerTime = serverTime
        })
    }
    
    func startRegularSync() {
        syncTimer = Timer.init(timeInterval: 60, repeats: true) { _ in
            self.syncTimeWithServer()
        }
    }
    
    func stopRegularSync() {
        syncTimer.invalidate()
    }
    
}
