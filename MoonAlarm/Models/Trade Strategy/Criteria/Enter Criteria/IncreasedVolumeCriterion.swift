//
//  IncreasedVolumeCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class IncreasedVolumeEnter: TradeEnterCriterion {
    
    var minVolRatio: Double = 2.0
    
    init(minVolRatio mvr: Double) {
        self.minVolRatio = mvr
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard let marketVolRatio = snapshot.candleSticks.volumeRatio1To15M else { return false }
        return marketVolRatio > minVolRatio
    }
    
}
