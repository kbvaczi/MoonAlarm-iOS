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
typealias Milliseconds = Int

extension Milliseconds {
    
    var msToSeconds: Seconds {
        return Double(self) / 1000.0
    }
    
}

extension Minutes {
    
    var minutesToSeconds: Seconds {
        return self * 60
    }
    
}

extension Seconds {
    
    var secondsToMinutes: Seconds {
        return self / 60
    }
    
}
