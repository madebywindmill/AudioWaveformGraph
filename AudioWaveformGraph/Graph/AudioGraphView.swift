//
//  AudioGraphView.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//
//  AudioGraphView: top-level view that manages interior layers and controls all aspects of the graph.
//

import UIKit

class AudioGraphView: UIView {

    var zoom: CGFloat {
        set (v) {
            viewPort.zoom = v
        }
        get {
            return viewPort.zoom
        }
    }
    
    var waveformColor: UIColor = #colorLiteral(red: 0, green: 0.8695636392, blue: 0.5598542094, alpha: 1) {
        didSet {
            waveformLayer.color = waveformColor
        }
    }
    
    var rulerHeight: CGFloat = 30 {
        didSet {
            update()
        }
    }
    
    var scrollView: UIScrollView!

    // MARK: - Private Vars
    
    private var viewPort: ViewPort! {
        didSet {
            scrollView.delegate = viewPort

            viewPort.screenScale = self.contentScaleFactor
            viewPort.onZoom { [weak self] in
                guard let self = self else { return }
                self.viewPortZoomed()
            }
            viewPort.onTranslate { [weak self] in
                guard let self = self else { return }
                self.viewPortTranslated()
            }
            // Now's a good time to do this since viewPort has `zoom` needed for sizing the scroll view
            updateScrollViewSize()
        }
    }
    private var dataProvider: DataProvider! {
        didSet {
            waveformLayer.dataProvider = dataProvider
            rulerLayer.dataProvider = dataProvider
            viewPort.dataProvider = dataProvider
        }
    }
    
    private var waveformLayer: WaveformLayer!
    private var rulerLayer: RulerLayer!
    private let logFPS = true
    private var lastBounds = CGRect.zero
    private var pauseUpdates = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        lastBounds = bounds
        
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)).forAutoLayout()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.bounces = true
        scrollView.contentSize = bounds.size
        scrollView.backgroundColor = UIColor.clear
        addSubview(scrollView)
        scrollView.constrainToSuperviewEdges()
        
        viewPort = ViewPort()
        viewPort.graphView = self
        viewPort.zoom = 10.0
        
        waveformLayer = WaveformLayer()
        waveformLayer.viewPort = viewPort
                
        rulerLayer = RulerLayer()
        rulerLayer.viewPort = viewPort
        
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(_:)))
        self.addGestureRecognizer(pinchGR)
                
        dataProvider = DataProvider()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scale = bounds.width / lastBounds.width
        scrollView.recenterForScale(scale)
        lastBounds = bounds
        
        updateScrollViewSize()
        
        update()
    }

    func update() {
        
        if pauseUpdates {
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        if dataProvider == nil { return }
        
        if dataProvider.summarySamples == nil {
            dataProvider.summarize(targetSampleCnt: viewPort.xAxisUnits)
        }
                
        if dataProvider.samples == nil || dataProvider.samples!.count == 0 {
            return
        }
        
        updateWaveformLayer()
        updateRulerLayer()
        
        if logFPS {
            let fps = 1.0/(CFAbsoluteTimeGetCurrent() - startTime)
            Logger.log("fps: \(Int(fps))")
        }
    }
    
    func setSamples(_ samples: [Float], sampleRate: Double) {
        dataProvider.samples = samples
        dataProvider.sampleRate = sampleRate
    }
        
    private func updateScrollViewSize() {
        scrollView.contentSize = CGSize(width: bounds.width * viewPort.zoom, height: bounds.height)
    }
    
    private func updateWaveformLayer() {
        if let waveformLayer = waveformLayer {
            if waveformLayer.superlayer == nil {
                layer.addSublayer(waveformLayer)
            }
            waveformLayer.frame = CGRect(x: 0, y: rulerHeight, width: bounds.width, height: bounds.height - rulerHeight)
            waveformLayer.update()
        }
    }
    
    private func updateRulerLayer() {
        if let rulerLayer = rulerLayer {
            if rulerLayer.superlayer == nil {
                layer.addSublayer(rulerLayer)
            }
            rulerLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: rulerHeight)
            rulerLayer.backgroundColor = UIColor(white: 0.1, alpha: 1.0).cgColor
            rulerLayer.update()
        }
    }
    
    // MARK: - Zoom Gesture
    
    @objc func pinchGesture(_ gc: UIPinchGestureRecognizer) {
        switch gc.state {
            case .changed:
                // Recentering the scroll view and changing the zoom are both going to end up calling update(), so suppress the first one with pauseUpdates.
                pauseUpdates = true
                scrollView.recenterForScale(gc.scale)
                pauseUpdates = false
                let newScale = viewPort.zoom * gc.scale
                viewPort.zoom = max(newScale, 1.0)
                gc.scale = 1.0
            case .ended, .cancelled, .failed:
                break
            default: break
        }
    }
    
    // MARK: - ViewPort Callbacks
    
    private func viewPortZoomed() {
        // nil out dataProvider's summarySamples so it can create them at the new scale
        dataProvider?.summarySamples = nil
        updateScrollViewSize()

        // Since CALayer's implicit animation duration is 0.25s, turn it off for this update to avoid chunkiness while zooming.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        update()
        CATransaction.commit()
    }
    
    private func viewPortTranslated() {
        // Since CALayer's implicit animation duration is 0.25s, turn it off for this update to avoid chunkiness while scrolling.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        update()
        CATransaction.commit()
    }
        
}
