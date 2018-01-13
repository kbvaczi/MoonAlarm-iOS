//
//  IncreasedVolumeCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class IncreaseVolumeCriterion: TradeEnterCriterion {
    
    var minVolRatio: Double
    
    init(minVolRatio mvr: Double) {
        self.minVolRatio = mvr
    }
    
    override func passed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        guard let marketVolRatio = mSnapshot.candleSticks.volumeRatio1To15M else { return false }
        return marketVolRatio > minVolRatio
    }
    
}
