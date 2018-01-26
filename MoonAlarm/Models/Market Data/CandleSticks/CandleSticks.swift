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
    
    var startTime: Milliseconds? {
        return self.first?.openTime
    }
    
    var currentTime: Milliseconds? {
        return self.last?.closeTime
    }
    
    var stickDuration: Seconds? {
        guard  let stick = self.first else { return nil }
        return stick.duration
    }
    
    var currentStickDuration: Seconds? {
        guard let currentStick = self.last else { return nil }
        let openT = currentStick.openTime
        let currentT = ExchangeClock.instance.currentTime
        return (currentT - openT).msToSeconds
    }
    
    var currentStickVolume: Double? {
        return self.last?.volume
    }
    
    var currentStickVolumeProrated: Double? {
        guard   let stickDur = self.stickDuration,
                let currentStickDur = self.currentStickDuration,
                let currentStickVol = self.currentStickVolume,
                let prevVol = self.volumeAvg15M else { return nil }
        
        let portionCompleteCurrentStick = currentStickDur / stickDur
        let portionPrevStickUsed = 1 - portionCompleteCurrentStick
        let proratedVol = currentStickVol + (prevVol * portionPrevStickUsed)
        
        return proratedVol
    }
    
    var currentStickTradesCount: Int? {
        return self.last?.tradesCount
    }
    
    var currentStickTradesCountProrated: Int? {
        guard   let stickDur = self.stickDuration,
                let currentStickDur = self.currentStickDuration,
                let currentStickTrades = self.currentStickTradesCount,
                let prevTrades = self.tradesAvg15M else { return nil }
     
        let portionCompleteCurrentStick = currentStickDur / stickDur
        let portionPrevStickUsed = 1 - portionCompleteCurrentStick
        let proratedTrades = Double(currentStickTrades) +
                            (Double(prevTrades) * portionPrevStickUsed)
     
        return Int(proratedTrades)
    }
    
    // Price of current stick is higher than previous stick
    var priceHasIncreased: Bool? {
        guard   let currentStick = self.last,
                let prevStick = self.suffix(2).first else { return nil }
        return currentStick.closePrice > prevStick.closePrice
    }

    // last candlestick volume normalized to 1-minute over average 15-minute volume
    var volumeRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
                let volumeAvg15M = self.volumeAvg15M,
                let currentStickVolume = self.currentStickVolumeProrated else { return nil }
        
        guard   stickDuration > 0 else { return nil } // prevent divide by zero error
        
        let volRatio = currentStickVolume / volumeAvg15M
        let roundedVolRatio = round(volRatio * 100) / 100
        
        return roundedVolRatio
    }
    
    // average volume over 15 minutes
    var volumeAvg15M: Double? {
        guard   let stickDuration = self.stickDuration else { return nil }
        guard   stickDuration > 0 else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds
        let sticks15MCount = Int(round(M15 / stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let volume15MAvg = sticks15M.map({ $0.volume }).reduce(0, { $0 + $1 / Double(sticks15MCount) })
        
        return volume15MAvg
    }
    
    // pair asset average volume over 15 minutes
    var volumeAvg15MPair: Double? {
        guard   let stickDuration = self.stickDuration else { return nil }
        guard   stickDuration > 0 else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds
        let sticks15MCount = Int(round(M15 / stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let volume15MAvgPair = sticks15M.map({ $0.pairVolume }).reduce(0, { $0 + $1 / Double(sticks15MCount) })
        
        return volume15MAvgPair
    }
    
    // average trades per stick over 15 minutes
    var tradesAvg15M: Int? {
        guard   let stickDuration = self.stickDuration else { return nil }
        guard   stickDuration > 0 else { return nil }
        
        let M15 = (15 as Minutes).minutesToSeconds
        let sticks15MCount = Int(round(M15 / stickDuration))
        let sticks15M = self.suffix(sticks15MCount)
        let trades15MAvg = sticks15M.map({ Double($0.tradesCount) })
                                    .reduce(0, { $0 + $1 / Double(sticks15MCount) })
        
        return Int(trades15MAvg)
    }
    
    // number of trades conducted within last minute vs 15-minute running average
    var tradesRatio1To15M: Double? {
        guard   let stickDuration = self.stickDuration,
                let tradesCurrent = self.currentStickTradesCount else { return nil }
        
        guard   stickDuration > 0 else { return nil } // prevent divide by zero error
        
        let M15 = (15 as Minutes).minutesToSeconds
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
        
        let M3 = (3 as Minutes).minutesToSeconds
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

