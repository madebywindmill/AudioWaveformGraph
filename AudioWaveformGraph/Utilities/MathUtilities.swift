//
//  MathUtilities.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//

import Foundation
import Accelerate

func fast_mean(_ a: [Float], startIdx: Int, endIdx: Int) -> Float {
    var mean: Float = 0
    // todo: dangling pointer warning is safe in this case since it's never accessed outside of scope, but should be fixed
    let ptr = UnsafePointer<Float>(a)
    vDSP_meanv(ptr + startIdx, 1, &mean, UInt(endIdx - startIdx))
    
    return mean
}

extension ClosedRange {
    func clamp(_ value: Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound :
            self.upperBound < value ? self.upperBound :
            value
    }
}

extension Range {
    func clamp(_ value: Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound :
            self.upperBound < value ? self.upperBound :
            value
    }
}
