//
//  CandleStick.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class CandleStick {
    
    let openTime: Milliseconds
    let closeTime: Milliseconds
    
    let openPrice: Double
    let closePrice: Double
    
    let highPrice: Double
    let lowPrice: Double
    
    let volume: Double
    let pairVolume: Double
    
    let tradesCount: Int
    
    var duration: Seconds {
        // candlesticks are 1ms less than standard size to prevent overlap (e.g. 1m stick is 999ms)
        return (self.closeTime - self.openTime + 1 as Milliseconds).msToSeconds
    }
    
    init(openTime: Milliseconds, closeTime: Milliseconds, openPrice: Double, closePrice: Double,
         highPrice: Double, lowPrice: Double, volume: Double, pairVolume: Double, tradesCount: Int) {
        
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

}
