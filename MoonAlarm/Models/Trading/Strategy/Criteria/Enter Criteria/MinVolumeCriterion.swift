//
//  MinVolumeCriterion.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class MinVolumeCriterion: TradeEnterCriterion {
    
    var minVolume: Double
    
    init(minVolume mv: Double) {
        self.minVolume = mv
    }
    
    override func passed(usingSnapshot mSnapshot: MarketSnapshot) -> Bool {
        guard let avgVol = mSnapshot.candleSticks.volumeAvg15M else { return false }
        
        return avgVol > minVolume
    }
}
