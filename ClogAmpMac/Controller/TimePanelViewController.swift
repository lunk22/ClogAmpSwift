//
//  TimePanelViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 28.01.19.
//

import AppKit

class TimePanelViewController: ViewController {
    // MARK: Outlets
    @IBOutlet weak var textFieldTime: NSTextField!

    // MARK: Properties
    var timer: Timer?
    private var trackingArea: NSTrackingArea?

    // MARK: Functions

    private func naturalTextSize() -> NSSize {
        let fontName = self.textFieldTime.font?.fontName ?? "Monaco"
        let font = NSFont(name: fontName, size: 100) ?? NSFont.monospacedDigitSystemFont(ofSize: 100, weight: .regular)
        return (" 00:00:00 " as NSString).size(withAttributes: [.font: font])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let window = view.window else { return }

        let size = naturalTextSize()
        window.contentAspectRatio = size

        let ratio = 3.7953
        var contentRect = window.contentRect(forFrameRect: window.frame)
        contentRect.size.height = contentRect.size.width / ratio
        let newFrame = window.frameRect(forContentRect: contentRect)
        window.setFrame(newFrame, display: true)

        setupTrackingArea()
        updateTransparency(mouseInside: isMouseInsideWindow())

        NotificationCenter.default.addObserver(self,
            selector: #selector(defaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil)
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        let size = naturalTextSize()
        let scaleForWidth  = view.frame.width  / size.width
        let scaleForHeight = view.frame.height / size.height
        let newFontSize    = min(scaleForWidth, scaleForHeight) * 100

        let fontName = self.textFieldTime.font?.fontName ?? "Monaco"
        self.textFieldTime.font = NSFont(name: fontName, size: newFontSize)
                               ?? NSFont.monospacedDigitSystemFont(ofSize: newFontSize, weight: .regular)

        setupTrackingArea()
    }

    override func viewWillAppear() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            let date     = Date()
            let calendar = Calendar.current
            let hours    = calendar.component(.hour, from: date)
            let minutes  = calendar.component(.minute, from: date)
            let seconds  = calendar.component(.second, from: date)

            var time = " "
            time += hours   < 10 ? "0\(hours)"   : "\(hours)"
            time += minutes < 10 ? ":0\(minutes)" : ":\(minutes)"
            time += seconds < 10 ? ":0\(seconds)" : ":\(seconds)"

            self.textFieldTime.stringValue = time.asTime()
        })
    }

    override func viewDidDisappear() {
        timer?.invalidate()
        if let area = trackingArea {
            view.removeTrackingArea(area)
            trackingArea = nil
        }
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
    }

    // MARK: Transparency

    private func setupTrackingArea() {
        if let existing = trackingArea {
            view.removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let area = NSTrackingArea(rect: view.bounds, options: options, owner: self, userInfo: nil)
        view.addTrackingArea(area)
        trackingArea = area
    }

    private func isMouseInsideWindow() -> Bool {
        guard let window = view.window else { return false }
        return window.frame.contains(NSEvent.mouseLocation)
    }

    override func mouseEntered(with event: NSEvent) {
        setTransparent(false)
    }

    override func mouseExited(with event: NSEvent) {
        updateTransparency(mouseInside: false)
    }

    @objc private func defaultsDidChange() {
        updateTransparency(mouseInside: isMouseInsideWindow())
    }

    private func updateTransparency(mouseInside: Bool) {
        setTransparent(Settings.timeWindowTransparentInactive && !mouseInside)
    }

    private func setTransparent(_ transparent: Bool) {
        guard let window = view.window else { return }
        if transparent {
            window.isOpaque    = false
            window.hasShadow   = false
            window.backgroundColor = .clear
        } else {
            window.isOpaque    = false  // must stay false because titlebarAppearsTransparent
            window.hasShadow   = true
            window.backgroundColor = .windowBackgroundColor
        }
    }
}
