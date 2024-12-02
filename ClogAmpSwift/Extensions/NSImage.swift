//
//  NSImage.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 01.08.24.
//

import Foundation

enum Shape: String {
    case play
    case pause
    case stop
}

extension NSImage {
    convenience init(shape: Shape, color: NSColor, size: NSSize, fillHeight: Double? = nil) {
        func generatePlay(_ rect: NSRect) -> Bool {
            // Height diff. between image size and the requested fill height
            let heightDiff = size.height - (fillHeight ?? size.height)
            //
            // 0,0 is the lower left corner => create a new rect with negative y offset (shifted down)
            let offsetRect = rect.offsetBy(dx: 0, dy: -heightDiff)
            //
            // Determine intersection of both rects => area to be filled with the desired color
            let intersectionRect = rect.intersection(offsetRect)
            
            //            -----------------------
            
            let path = NSBezierPath()
            path.move(to: NSMakePoint(0, 0))
            path.line(to: NSMakePoint(0, size.height))
            path.line(to: NSMakePoint(size.width, size.height / 2))
            path.line(to: NSMakePoint(0, 0))
            path.close()
            
            // Fill
            NSColor.darkGray.setFill()
            path.fill()
            
            intersectionRect.clip()
            
            color.setFill()
            path.fill()
            
            return true
        }
        
        func generatePause(_ rect: NSRect) -> Bool {
            let path = NSBezierPath()
            path.move(to: NSMakePoint(0, 0))
            path.line(to: NSMakePoint(0, size.height))
            path.line(to: NSMakePoint(size.width * 2/5, size.height))
            path.line(to: NSMakePoint(size.width * 2/5, 0))
            path.line(to: NSMakePoint(0, 0))
            path.close()

            path.move(to: NSMakePoint(size.width * 3/5, 0))
            path.line(to: NSMakePoint(size.width * 3/5, size.height))
            path.line(to: NSMakePoint(size.width, size.height))
            path.line(to: NSMakePoint(size.width, 0))
            path.line(to: NSMakePoint(size.width * 3/5, 0))
            path.close()
            
            // Fill
            color.setFill()
            path.fill()
            
            return true
        }
        
        func generateStop(_ rect: NSRect) -> Bool {
            color.setFill()
            rect.fill()
            
            return true
        }
        
        switch shape {
            case .play:
                self.init(size: size, flipped: false, drawingHandler: generatePlay)
                break
            case .pause:
                self.init(size: size, flipped: false, drawingHandler: generatePause)
                break
            case .stop:
                self.init(size: size, flipped: false, drawingHandler: generateStop)
                break
        }
    }
    
    
}
