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
    
}
