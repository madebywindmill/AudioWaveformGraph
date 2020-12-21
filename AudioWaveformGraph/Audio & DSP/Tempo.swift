//
//  Tempo.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//

import Foundation

typealias Tempo = Double

extension Tempo {
    static func from(_ timeInterval: TimeInterval) -> Tempo {
        return 60.0 / Double(timeInterval)
    }
    
    var timeInterval: Double {
        return 60.0 / self
    }
}
