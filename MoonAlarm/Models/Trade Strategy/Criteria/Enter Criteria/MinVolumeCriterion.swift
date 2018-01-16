//
//  MinVolumeCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MinVolumeCriterion: TradeEnterCriterion {
    
    var minVolume: Double = TradeStrategy.instance.tradeAmountTarget * 10
    
    override init() { }
    
    init(minVolume mv: Double) {
        self.minVolume = mv
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard let avgVol = snapshot.candleSticks.volumeAvg15MPair else { return false }
        
        return avgVol > self.minVolume
    }
}
