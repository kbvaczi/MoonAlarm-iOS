//
//  CandleSticks.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias CandleSticks = Array<CandleStick>

extension Array where Element : CandleStick {
    
    var startTime: Seconds? {
        return self.first?.openTime
    }
    
    var currentTime: Seconds? {
        return self.last?.closeTime
    }
    
    var stickDuration: Seconds? {
        guard   let oT = self.first?.openTime,
                let cT = self.first?.closeTime else { return nil }
        
        return Seconds(cT - oT)
    }
    
    var currentStickDuration: Seconds? {
        guard   let oT = self.last?.openTime,
                let cT = self.last?.closeTime else { return nil }
        
        return Seconds(cT - oT)
    }
    
    var priceIsIncreasing: Bool {
        guard   let currentStick = self.last,
                let prevStick = self.suffix(2).first else { return false }
        
        return currentStick.closePrice > prevStick.closePrice
    }

    // last candlestick volume normalized to 1-minute over average 15-minute volume
    var volumeRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
                let currentStick = self.last,
                let currentStickDuration = self.currentStickDuration else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds()
        let sticks15MCount = Int(M15 / round(stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let volume15MTotal = sticks15M.map({ $0.volume }).reduce(0, +)
        let volume15MAvg = volume15MTotal / Double(sticks15MCount)
        
        let volumeCurrent = currentStick.volume
        let volumeCurrentNormalized = volumeCurrent * 60 / currentStickDuration
        
        let volRatio = volumeCurrent / volume15MAvg
        let roundedVolRatio = round(volRatio * 100) / 100
        
        return roundedVolRatio
    }
    
    // last candlestick volume normalized to 1-minute over average 15-minute volume
    var tradesRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
            let currentStick = self.last,
            let currentStickDuration = self.currentStickDuration else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds()
        let sticks15MCount = Int(M15 / round(stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let trades15MTotal = sticks15M.map({ $0.tradesCount }).reduce(0, +)
        let trades15MAvg = Double(trades15MTotal) / Double(sticks15MCount)
        
        let tradesCurrent = currentStick.tradesCount
        let tradesCurrentNormalized = Double(tradesCurrent) * 60 / currentStickDuration
        
        let tradesRatio = Double(tradesCurrent) / trades15MAvg
        let roundedTradesRatio = round(tradesRatio * 100) / 100
        
        return roundedTradesRatio
    }
    
    // last candlestick volume normalized to 1-minute over average 15-minute volume
    var priceRatio1To3M: Double? {
        guard   let stickDuration = self.stickDuration,
                let currentStick = self.last else { return nil }
        
        let M3 = (3 as Minutes).minutesToSeconds()
        let sticks3MCount = Int(M3 / round(stickDuration))
        let sticks3M = self.suffix(sticks3MCount)
        let price3MTotal = sticks3M.map({ $0.closePrice }).reduce(0, +)
        let price3MAvg = price3MTotal / Double(sticks3MCount)
        
        let priceCurrent = currentStick.closePrice
        
        let priceRatio = priceCurrent / price3MAvg
        let roundedPriceRatio = round(priceRatio * 1000) / 1000
        
        return roundedPriceRatio
    }

}

