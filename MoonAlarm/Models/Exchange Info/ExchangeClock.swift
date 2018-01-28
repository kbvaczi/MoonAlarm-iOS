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
    
    static var instance = ExchangeClock() // singleton
    
    private var lastSyncLocalTime: Milliseconds
    private var lastSyncServerTime: Milliseconds
    
    private var syncTimer = Timer()
    
    var currentTime: Milliseconds {
        let currentLocalTime = Date().millisecondsSince1970
//        let timeSinceLastSync = currentLocalTime - self.lastSyncLocalTime
//        return timeSinceLastSync + self.lastSyncServerTime
        return currentLocalTime
    }
    
    private init(serverTime: Milliseconds, localTime: Milliseconds) {
        self.lastSyncServerTime = serverTime
        self.lastSyncLocalTime = localTime
        self.syncTimeWithServer()
    }
    
    private convenience init() {
        let currentTime = Date().millisecondsSince1970
        self.init(serverTime: currentTime, localTime: currentTime)
    }
    
    private func syncTimeWithServer() {
        self.lastSyncLocalTime = Date().millisecondsSince1970
        BinanceAPI.instance.getCurrentServerTime(callback: {
            isSuccess, serverTime in
            self.lastSyncServerTime = serverTime
        })
    }
}
