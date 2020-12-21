//
//  UIKitExtras.swift
//  AudioWaveformGraph
//
//  Created by John Scalo on 12/17/20.
//

import UIKit

extension UIScrollView {
    func recenterForScale(_ scale: CGFloat) {
        
        // Keep the scroll content centered while zooming or resizing. This is worked out by seeing that while scaling the graph, the viewable area (scrollView.bounds) remains fixed while the total width (scrollView.contentSize) and offset (scrollView.contentOffset) change. We can keep the center fixed by scaling the content offset with a fixed ratio, where the ratio is:
        //
        // r = offset / (contentWidth - boundsWidth)
        //
        // We then calculate the new totalWidth by multiplying by the new scale and solve for offset:
        //
        // newContentWidth = offset * scale
        // newOffset = r * (newContentWidth - boundsWidth)
        //

        if scale != 1.0 && contentSize.width != bounds.width {
            let oldOffset = contentOffset.x
            let ratio = oldOffset / (contentSize.width - bounds.width)
            let newContentW = contentSize.width * scale
            let newOffset = ratio * (newContentW - bounds.width)
            contentOffset = CGPoint(x: newOffset, y: contentOffset.y)
        }
    }
}


