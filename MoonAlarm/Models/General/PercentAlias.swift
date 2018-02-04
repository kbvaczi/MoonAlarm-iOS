//
//  PercentAlias.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias Percent = Double

extension Double {
    
    var doubleToPercent: Percent {
        let percent = Darwin.round(self * 1000) / 10
        return percent
    }
    
}

extension Percent {
    
    var percentToDouble: Double {
        return self / 100
    }
    
    /// Display as a string with 1 decimal place
    var display1: String {
        return String(format: "%0.1f", arguments: [self.roundTo(1)])
    }
    
}
