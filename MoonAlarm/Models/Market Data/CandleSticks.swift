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
        print(cT - oT)
        return Seconds(cT - oT)
    }
    
    var currentStickVolume: Double? {
        return self.last?.volume
    }
    
    var currentVolNormalized: Double? {
        guard   let vol = self.currentStickVolume,
                let cStickDur = self.currentStickDuration,
                let stickDur = self.stickDuration else { return nil }
        print(cStickDur)
        return vol * stickDur / cStickDur
    }
    
    var currentTradesCountNormalized: Int? {
        guard   let trades = self.last?.tradesCount,
                let cStickDur = self.currentStickDuration,
                let stickDur = self.stickDuration else { return nil }
        return Int(Double(trades) * stickDur / cStickDur)
    }
    
    var priceIsIncreasing: Bool {
        guard   let currentStick = self.last,
                let prevStick = self.suffix(2).first else { return false }
        
        return currentStick.closePrice > prevStick.closePrice
    }

    // last candlestick volume normalized to 1-minute over average 15-minute volume
    var volumeRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
                let volumeAvg15M = self.volumeAvg15M,
                let currentVolNorm = self.currentVolNormalized else { return nil }
        
        guard   stickDuration > 0 else { return nil }
        
        let volRatio = currentVolNorm / volumeAvg15M
        let roundedVolRatio = round(volRatio * 100) / 100
        
        return roundedVolRatio
    }
    
    // average volume over 15 minutes
    var volumeAvg15M: Double? {
        guard   let stickDuration = self.stickDuration else { return nil }
        guard   stickDuration > 0 else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds()
        let sticks15MCount = Int(M15 / round(stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let volume15MAvg = sticks15M.map({ $0.volume }).reduce(0, { $0 + $1 / Double(sticks15MCount) })
        
        return volume15MAvg
    }
    
    // number of trades conducted within last minute vs 15-minute running average
    var tradesRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
                let tradesCurrent = currentTradesCountNormalized else { return nil }
        
        guard   stickDuration > 0 else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds()
        let sticks15MCount = Int(M15 / round(stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let trades15MAvg = sticks15M.map({ Double($0.tradesCount) }).reduce(0, { $0 + $1 / Double(sticks15MCount) })
        
        let tradesRatio = Double(tradesCurrent) / trades15MAvg
        let roundedTradesRatio = round(tradesRatio * 100) / 100
        
        return roundedTradesRatio
    }
    
    // current price vs 3-minute running average
    var priceRatio1To3M: Double? {
        guard   let stickDuration = self.stickDuration,
                let currentStick = self.last else { return nil }

        guard stickDuration > 0 else { return nil }
        
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

