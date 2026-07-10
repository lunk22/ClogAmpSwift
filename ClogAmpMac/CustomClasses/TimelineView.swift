//
//  TimelineView.swift
//  ClogAmpSwift
//

import AppKit

/// A custom seek-bar replacement that visualises playback progress and dance-position markers.
///
/// Layout (top → bottom):
///   • Track bar (barHeight pt tall, rounded rect)
///   • Thin playhead line spanning the full view height
///   • ▲ triangle markers sitting just below the bar for each position
///   • Position name labels below each triangle
///
/// The view is purely programmatic – no storyboard entry needed.
class TimelineView: NSView {

    // MARK: - Public API

    /// Playback progress 0.0 … 1.0
    var progress: Double = 0 {
        didSet { needsDisplay = true }
    }

    /// List of position markers.  `time` is a fraction (0–1) of the total duration.
    var positions: [(time: Double, name: String)] = [] {
        didSet { needsDisplay = true }
    }

    /// Called with a 0–1 fraction whenever the user clicks or drags to seek.
    var seekCallback: ((Double) -> Void)?

    // MARK: - Layout constants

    private let barHeight:    CGFloat = 10
    private let barTopOffset: CGFloat = 4   // gap between view top and bar top
    private let labelFont = NSFont.systemFont(ofSize: 9, weight: .regular)

    // MARK: - Colours (resolved lazily so they respect Dark/Light mode changes)

    private var trackColor:    NSColor { NSColor(white: 0.25, alpha: 1) }
    private var fillColor:     NSColor { NSColor.systemBlue }
    private var playheadColor: NSColor { NSColor.white }
    private var markerColor:   NSColor { NSColor.labelColor.withAlphaComponent(0.7) }
    private var labelColor:    NSColor { NSColor.secondaryLabelColor }

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let w = bounds.width
        let barRect = NSRect(x: 0, y: bounds.height - barTopOffset - barHeight,
                             width: w, height: barHeight)
        let radius: CGFloat = barHeight / 2

        // 1. Background track
        let track = NSBezierPath(roundedRect: barRect, xRadius: radius, yRadius: radius)
        trackColor.setFill()
        track.fill()

        // 2. Progress fill (clipped to bar shape)
        if progress > 0 {
            let fillWidth = w * CGFloat(min(progress, 1.0))
            let fillRect = NSRect(x: 0, y: barRect.minY, width: fillWidth, height: barHeight)
            NSGraphicsContext.current?.saveGraphicsState()
            track.setClip()
            fillColor.setFill()
            NSBezierPath(rect: fillRect).fill()
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        // 3. Position markers + labels
        var lastLabelMaxX: CGFloat = -CGFloat.infinity
        for pos in positions {
            let x = CGFloat(pos.time) * w
            drawMarker(at: x, barRect: barRect, name: pos.name, lastLabelMaxX: &lastLabelMaxX)
        }

        // 4. Playhead (drawn last so it's always on top) — spans only the bar
        let ph = CGFloat(min(progress, 1.0)) * w
        let playhead = NSBezierPath()
        playhead.move(to: NSPoint(x: ph, y: barRect.maxY))
        playhead.line(to: NSPoint(x: ph, y: barRect.minY))
        playhead.lineWidth = 1.5
        playheadColor.setStroke()
        playhead.stroke()
    }

    private func drawMarker(at x: CGFloat, barRect: NSRect,
                            name: String, lastLabelMaxX: inout CGFloat) {
        // Hairline from bar bottom down
        let hairlineTop = barRect.minY
        let hairlineBot = hairlineTop - 6

        let hair = NSBezierPath()
        hair.move(to: NSPoint(x: x, y: hairlineTop))
        hair.line(to: NSPoint(x: x, y: hairlineBot))
        hair.lineWidth = 1
        markerColor.setStroke()
        hair.stroke()

        // Label (suppress if it would overlap the previous one)
        guard !name.isEmpty else { return }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor
        ]
        let size = (name as NSString).size(withAttributes: attrs)
        let labelX = x - size.width / 2
        let labelY = hairlineBot - size.height - 1

        // Suppress if this label would overlap the previous visible one
        if labelX < lastLabelMaxX + 4 {
            return
        }
        lastLabelMaxX = labelX + size.width

        (name as NSString).draw(at: NSPoint(x: labelX, y: labelY), withAttributes: attrs)
    }

    // MARK: - Mouse handling (seek on click / drag)

    override func mouseDown(with event: NSEvent) {
        seek(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        seek(with: event)
    }

    private func seek(with event: NSEvent) {
        let localX = convert(event.locationInWindow, from: nil).x
        let fraction = Double(max(0, min(localX / bounds.width, 1)))
        seekCallback?(fraction)
    }

    // Accept first-responder so mouse events are delivered even without focus
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
