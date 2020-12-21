//
//  WaveformLayer.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//
//  WaveformLayer: Plot a waveform using CALayers.
//

import UIKit
import Accelerate

class WaveformLayer: CALayer {
    
    var color = #colorLiteral(red: 0, green: 0.8695636392, blue: 0.5598542094, alpha: 1)
    
    // weak so as not to create circular refs
    weak var dataProvider: DataProvider!
    weak var viewPort: ViewPort!
    
    private var xAxisUnits: Int = 0
    private var layers = [CALayer]()
    private let midlineLayer = CALayer()

    private var firstSampleToPlotIdx: Int {
        get {
            let idx = Int(-viewPort.xTrans * viewPort.screenScale)
            return (0..<dataProvider.summarySampleCnt).clamp(idx)
        }
    }

    private var samplesToPlotInVisibleCnt: Int {
        get {
            return viewPort.visibleXAxisUnits
        }
    }

    func update() {
        guard viewPort != nil else { return }
        guard dataProvider != nil else { return }
        prepare()
        updateMidline()
        updatePlot()
    }
    
    private func prepare() {
        if xAxisUnits != viewPort.visibleXAxisUnits {
            xAxisUnits = viewPort.visibleXAxisUnits
            createLayers()
        }
        if midlineLayer.superlayer == nil {
            self.addSublayer(midlineLayer)
            midlineLayer.backgroundColor = color.cgColor
        }
    }

    private func updateMidline() {
        midlineLayer.frame = CGRect(x: 0, y: frame.height / 2, width: frame.width, height: 1 / viewPort.screenScale)
    }
    
    private func updatePlot() {
        guard let samples = dataProvider.summarySamples else {
            return
        }
        
        let endIdx = (0..<samples.count).clamp(firstSampleToPlotIdx+samplesToPlotInVisibleCnt)
        let samplesToPlot = Array(samples[firstSampleToPlotIdx..<endIdx])

        layers.forEach() {
            $0.isHidden = true
        }

        updateLines(samples: samplesToPlot, yMidline: bounds.height / 2)
    }
    
    private func updateLines(samples: [Float], yMidline: CGFloat) {
                
        let maxSampleMagnitude = max(dataProvider.summarySampleMax, -(dataProvider.summarySampleMin), Float.leastNonzeroMagnitude)
        let yScalingFactor = bounds.height / 2 / CGFloat(maxSampleMagnitude)
        var xPos: CGFloat = 0
        let cnt = samples.count
        var idx = 0
        let visibleDur = dataProvider.duration / Double(viewPort.zoom)
        let startTime = (Double(viewPort.startingXUnit) / Double(viewPort.xAxisUnits)) * dataProvider.duration

        if viewPort.xTrans > 0 {
            // Special case: the user is rubberbanding while scrolling.
            xPos = viewPort.xTrans
        }
        
        while idx < cnt && xPos < bounds.maxX && idx < layers.count {
            let time = startTime + Double(xPos) / Double(viewPort.visibleWidth) * visibleDur
            let sample = dataProvider.sample(at: time)
            let layer = layers[idx]
            layer.isHidden = false
            
            let y = CGFloat(sample) * yScalingFactor
            layer.frame = CGRect(x: xPos, y: yMidline - y, width: 1, height: 2 * y)
            
            xPos += 1.0 / viewPort.screenScale
            idx += 1
        }
    }
    
    
    private func createLayers() {
        // Creating new layers and adding them is expensive so only ever make new ones, don't destroy unneeded ones. (Unused layers will be hidden.)
        let lineCnt = samplesToPlotInVisibleCnt
        let currentCnt = layers.count
        if currentCnt < lineCnt {
            for _ in 0..<lineCnt - currentCnt {
                let layer = CALayer()
                layer.backgroundColor = color.cgColor
                layers.append(layer)
                addSublayer(layer)
            }
        }
    }
}
