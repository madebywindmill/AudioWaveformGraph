//
//  DataProvider.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//
//  DataProvider: Centralized access for audio sample data.
//

import UIKit
import Accelerate

class DataProvider {
    var samples: [Float]?
    
    var sampleRate: Double = 0
    var summarySampleRate: Double? {
        guard let samples = samples, let summarySamples = summarySamples else { return 0 }
        let ratio = Double(samples.count) / Double(summarySamples.count)
        return sampleRate / ratio
    }
    
    // = `samples` with a moving window average to create a smaller set of displayable samples as a waveform.
    var summarySamples: [Float]?
    var summarySampleCnt: Int {
        get {
            return summarySamples?.count ?? 0
        }
    }
        
    var summarySampleMax: Float = 0
    var summarySampleMin: Float = 0
        
    private let windowSize = 128

    var duration: Double {
        guard let samples = samples else { return 0 }
        return Double(samples.count) / sampleRate
    }
    
    func summarize(targetSampleCnt: Int) {
        guard let samples = samples else { return }
        let startTime = CFAbsoluteTimeGetCurrent()
        var workingAvgSamples = [Float]()
                
        var hopSize = Int(CGFloat(samples.count) / CGFloat(targetSampleCnt))
        hopSize = max(hopSize, 1)
        
        var idx = 0
        while idx + windowSize < samples.count {
            let avg = fast_mean(samples, startIdx: idx, endIdx:idx+windowSize)
            workingAvgSamples.append(avg)
            idx += hopSize
        }
        
        if #available(iOS 13, *) {
            summarySampleMax = vDSP.maximum(workingAvgSamples)
            summarySampleMin = vDSP.minimum(workingAvgSamples)
        }
        else {
            vDSP_maxv(workingAvgSamples, 1, &summarySampleMax, vDSP_Length(workingAvgSamples.count))
            vDSP_minv(workingAvgSamples, 1, &summarySampleMin, vDSP_Length(workingAvgSamples.count))
        }
        
        summarySamples = workingAvgSamples
        
        let fps = Int(1.0 / (CFAbsoluteTimeGetCurrent() - startTime))
        if fps < 60 {
            Logger.log("*** bad performance: \(fps)fps")
        }
    }
    
    func sample(at time: Double) -> Float {
        guard let summarySamples = summarySamples else { return 0 }
        var summarySampleIdx = Int(time / duration * Double(summarySamples.count))
        
        // fail safe
        summarySampleIdx = min(summarySampleIdx, summarySamples.count - 1)
        
        return summarySamples[summarySampleIdx]
    }
}
