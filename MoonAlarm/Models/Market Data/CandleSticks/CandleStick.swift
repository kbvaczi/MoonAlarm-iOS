//
//  CandleStick.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class CandleStick {
    
    ////////// Time //////////
    
    let openTime: Milliseconds
    let closeTime: Milliseconds
    
    var duration: Seconds {
        // candlesticks are 1ms less than standard size to prevent overlap (e.g. 1m stick is 999ms)
        return (self.closeTime - self.openTime + 1 as Milliseconds).msToSeconds
    }
    
    ////////// Price //////////
    
    let openPrice: Price
    let closePrice: Price
    
    let highPrice: Price
    let lowPrice: Price
    
    ////////// Volume & Count //////////
    
    let volume: Double
    let pairVolume: Double
    
    let tradesCount: Int
    
    ////////// Initializer //////////
    
    init(openTime: Milliseconds, closeTime: Milliseconds, openPrice: Price, closePrice: Price,
         highPrice: Price, lowPrice: Price, volume: Double, pairVolume: Double, tradesCount: Int) {
        
        self.openTime = openTime
        self.closeTime = closeTime
        
        self.openPrice = openPrice
        self.closePrice = closePrice
        
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        
        self.volume = volume
        self.pairVolume = pairVolume
        
        self.tradesCount = tradesCount
    }
    
    ////////// Stochstic Price Oscillator //////////
    
    /// Stochastic Price indicator
    var stoch: Double? = nil
    /// Smoothed signal of stochastic price indicator
    var stochK: Double? = nil
    /// Smoothed smoothed signal of stochastic price indicator
    var stochD: Double? = nil
    /// stochK - stochD
    var stochSignalDelta: Double? {
        guard   let k = self.stochK,
                let d = self.stochD else { return nil }
        return k - d
    }
    
    ////////// MACD Indicator //////////
    
    var macd: Double? = nil
    var macdSignal: Double? = nil
    
    var macdHistogram: Double? {
        guard   let macd = self.macd,
                let macdSignal = self.macdSignal else { return nil }
        return macd - macdSignal
    }
    
    ////////// RSI Indicator //////////
    
    var rsi: Double? = nil
    
    ////////// Stochastic RSI Oscilator //////////
    
    /// Stochastic RSI
    var stochRSI: Double? = nil
    /// Smoothed signal of stochastic RSI
    var stochRSIK: Double? = nil
    /// Smoothed smoothed signal of stochastic RSI
    var stochRSID: Double? = nil
    /// stochRSIK - stochRSID
    var stochRSISignalDelta: Double? {
        guard   let k = self.stochRSIK,
                let d = self.stochRSID else { return nil }
        return k - d
    }
}
