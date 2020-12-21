//
//  Logger.swift
//  AudioWaveformGraph

//  Created by John Scalo on 12/11/20.
//

import Foundation

class Logger {
    class func log(_ str: String, file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        let shortenedFile = file.components(separatedBy: "/").last ?? ""
        let s = "[\(shortenedFile):\(function):\(line)] \(str)"
        NSLog(s)
        #endif
    }
}
