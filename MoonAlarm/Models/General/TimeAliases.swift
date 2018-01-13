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
    
    var secondsToMilliseconds: Milliseconds {
        return Milliseconds(self * 1000)
    }
    
}

extension Date {
    
    var millisecondsSince1970: Milliseconds {
        return Milliseconds((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds: Milliseconds) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
