//
//  CandleStick.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class CandleStick {
    
    let openTime: Seconds
    let closeTime: Seconds
    
    let openPrice: Double
    let closePrice: Double
    
    let highPrice: Double
    let lowPrice: Double
    
    let volume: Double
    let pairVolume: Double
    
    let tradesCount: Int
    
    var duration: Seconds {
        return Seconds(self.closeTime - self.openTime) / 1000
    }
    
    init(openTime: Seconds, closeTime: Seconds, openPrice: Double, closePrice: Double,
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
