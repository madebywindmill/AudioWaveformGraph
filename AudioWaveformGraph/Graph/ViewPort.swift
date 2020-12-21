//
//  ViewPort.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/11/20.
//
//  ViewPort: manages the view's basic geometry, translation, and scale.
//

import UIKit

class ViewPort: NSObject, UIScrollViewDelegate {
    
    typealias ZoomNotifyBlock = ()->()
    typealias TranslateNotifyBlock = ()->()

    // weak so as not to create circular refs
    weak var graphView: AudioGraphView!
    weak var dataProvider: DataProvider!
    
    var xTrans: CGFloat = 0 {
        didSet {
            translateObserverBlocks.forEach { $0() }
        }
    }

    var startingXUnit: Int {
        return Int(-xTrans * screenScale)
    }
    
    var zoom: CGFloat = 1 {
        didSet {
            zoomObserverBlocks.forEach { $0() }
        }
    }

    var visibleWidth: CGFloat {
        return graphView.bounds.width
    }
    var visibleHeight: CGFloat {
        return graphView.bounds.height
    }

    var screenScale: CGFloat = 1
    
    var visibleXAxisUnits: Int {
        guard let samples = dataProvider.samples else { return 0 }
        return min(
            Int(graphView.bounds.width * screenScale),
            samples.count)
    }
    
    // The total x plot points across the entire view port (visible and non-visible).
    // Since we plot one sample per pixel, this is basically just boundsWidth * zoom.
    var xAxisUnits: Int {
        guard let samples = dataProvider.samples else { return 0 }
        return min(
            Int(CGFloat(visibleXAxisUnits) * zoom),
            samples.count)
    }
    
    private var zoomObserverBlocks = [ZoomNotifyBlock]()
    private var translateObserverBlocks = [TranslateNotifyBlock]()
    
    // MARK: -
    
    func onZoom(_ block: @escaping ZoomNotifyBlock) {
        zoomObserverBlocks.append(block)
    }

    func onTranslate(_ block: @escaping TranslateNotifyBlock) {
        translateObserverBlocks.append(block)
    }

    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        xTrans = -scrollView.contentOffset.x
    }

}
