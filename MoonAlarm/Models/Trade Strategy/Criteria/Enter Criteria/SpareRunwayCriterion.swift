//
//  SpareRunway.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/12/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

class SpareRunwayEnter: TradeEnterCriterion {
    
    var minRunwayPercent: Percent = 1.0
    
    override init() { }
    
    init(percent mrp: Percent) {
        self.minRunwayPercent = mrp
    }
    
    override func passedFor(snapshot: MarketSnapshot) -> Bool {
        guard   let runwayPercent = snapshot.runwayPercent1Period else { return false }
        
        return runwayPercent > minRunwayPercent
    }
    
}

