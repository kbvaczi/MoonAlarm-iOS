//
//  TimeAliases.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/8/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

typealias Minutes = Double
typealias Seconds = Double
typealias Milliseconds = Double

extension Milliseconds {
    
    func msToSeconds() -> Seconds {
        return self / 1000
    }
    
}

extension Minutes {
    
    func minutesToSeconds() -> Seconds {
        return self * 60
    }
    
}
