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
    
    mutating func toPercent() -> Percent {
        let percent = Darwin.round(self * 1000) / 10
        return percent
    }
    
}
