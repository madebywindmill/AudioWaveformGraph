//
//  RulerLayer.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//
//  RulerLayer: Draw major (1 second) and minor (1/10 second) ticks in a ruler using CALayers.
//

import UIKit
import Accelerate

class RulerLayer: CALayer {
    
    // weak so as not to create circular refs
    weak var dataProvider: DataProvider!
    weak var viewPort: ViewPort!

    private var majorTickLayers = [CALayer]()
    private var minorTickLayers = [CALayer]()

    func update() {
        prepare()
        updateMinorTicks()
        updateMajorTicks()
    }

    func prepare() {
        let totalDur = dataProvider.duration
        let visibleDur = totalDur / Double(viewPort.zoom)
        let oneSecWidth = CGFloat(1.0 / visibleDur) * viewPort.visibleWidth
        let numSecs = Int(viewPort.visibleWidth / oneSecWidth) + 1
        let numTenths = numSecs * 10 + 1
        
        if canDrawMinor() {
            let cnt = minorTickLayers.count
            if cnt < numTenths {
                for _ in 0..<numTenths - cnt {
                    let layer = CALayer()
                    layer.backgroundColor = UIColor.gray.cgColor
                    minorTickLayers.append(layer)
                    addSublayer(layer)
                }
            }
        }

        let majorCnt = majorTickLayers.count
        if majorCnt < numSecs {
            for _ in 0..<numSecs - majorCnt {
                let layer = CALayer()
                layer.backgroundColor = UIColor.white.cgColor
                majorTickLayers.append(layer)
                addSublayer(layer)
            }
        }
        
    }
    
    private func updateMajorTicks() {
        majorTickLayers.forEach() {
            $0.isHidden = true
        }

        let totalDur = dataProvider.duration
        let visibleDur = totalDur / Double(viewPort.zoom)
        let startTime = (Double(viewPort.startingXUnit) / Double(viewPort.xAxisUnits)) * totalDur
        let diffFromLastSec = ceil(startTime) - startTime
        let oneSecWidth = CGFloat(1.0 / visibleDur) * viewPort.visibleWidth
        var x = CGFloat(diffFromLastSec / visibleDur) * viewPort.visibleWidth
        
        var idx = 0
        while x < bounds.width {
            
            let layer = majorTickLayers[idx]
            layer.frame = CGRect(x: x, y: 0, width: 2, height: 30)
            layer.isHidden = false
            x += oneSecWidth
            idx += 1
        }
    }
    
    private func updateMinorTicks() {
        minorTickLayers.forEach() {
            $0.isHidden = true
        }

        if !canDrawMinor() {
            return
        }
        
        let totalDur = dataProvider.duration
        let visibleDur = totalDur / Double(viewPort.zoom)
        let startTime = (Double(viewPort.startingXUnit) / Double(viewPort.xAxisUnits)) * totalDur
        let diffFromLastTick = (ceil(startTime * 10) - (startTime * 10))/10
        let oneTickWidth = CGFloat(1.0 / visibleDur) * viewPort.visibleWidth / 10
        var x = CGFloat(diffFromLastTick / visibleDur) * viewPort.visibleWidth

        var idx = 0
        while x < bounds.width {
            
            let layer = minorTickLayers[idx]
            layer.frame = CGRect(x: x, y: 0, width: 1, height: 15)
            layer.isHidden = false
            x += oneTickWidth
            idx += 1
        }
    }
    
    private func canDrawMinor() -> Bool {
        let totalDur = dataProvider.duration
        let visibleDur = totalDur / Double(viewPort.zoom)
        let minorCnt = ceil(Double(viewPort.visibleWidth) / visibleDur * 10.0)
        
        return minorCnt / visibleDur > 3
    }
    
}
