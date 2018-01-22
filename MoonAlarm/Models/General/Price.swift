//
//  Price.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/21/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias Price = Double

extension Double {
    
    func roundTo(_ decimalPlaces: Int) -> Double {
        let doubDec = Double(decimalPlaces)
        return (self * pow(10.0,doubDec)).rounded(.toNearestOrAwayFromZero) / pow(10.0,doubDec)
    }
    
}

extension Price {
    
    var rounded: Price {
        return self.roundTo(8)
    }
    
}

