//
//  CandleStick.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/7/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class CandleStick {
    
    let openTime: Int
    let closeTime: Int
    let openPrice: Double
    let closePrice: Double
    let highPrice: Double
    let lowPrice: Double
    let volume: Double
    
    init(openTime: Int, closeTime: Int, openPrice: Double, closePrice: Double,
         highPrice: Double, lowPrice: Double, volume: Double) {
        
        self.openTime = openTime
        self.closeTime = closeTime
        self.openPrice = openPrice
        self.closePrice = closePrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.volume = volume
    }

}
