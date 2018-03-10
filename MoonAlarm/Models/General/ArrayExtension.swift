//
//  ArrayExtension.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 2/25/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation

extension Array {
 
    mutating func remove(at indexes: [Int]) {
        for index in indexes.sorted(by: >) {
            remove(at: index)
        }
    }
    
}
