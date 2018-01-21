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
    
    var msToMinutes: Minutes {
        return self.msToSeconds.secondsToMinutes
    }
    
    var displayMsToHHMM: String {
        let hours = self / (60 as Minutes).minutesToMilliseconds
        let hoursFormatted = String(format: "%02d", arguments: [hours])
        let minutes = hours > 0 ? self.msToMinutes.truncatingRemainder(dividingBy: 60) : self.msToMinutes
        let minutesFormatted = String(format: "%02.0f", arguments: [minutes])
        return hoursFormatted + ":" + minutesFormatted
    }
    
}

extension Minutes {
    
    var minutesToSeconds: Seconds {
        return self * 60
    }
    
    var minutesToMilliseconds: Milliseconds {
        return Int(self * 60 * 1000)
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
