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
    
    
    // MARK: Functions
    override func viewDidLayout() {
        super.viewDidLayout()

        let fontName = self.textFieldTime.font?.fontName ?? "Monaco"
        let font = NSFont(name: fontName, size: 100) ?? NSFont.monospacedDigitSystemFont(ofSize: 100, weight: .regular)

        // Measure a representative string at size 100 to derive a scaling ratio
        let sampleString = " 00:00:00"
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let sampleSize = (sampleString as NSString).size(withAttributes: attrs)

        let scaleForWidth  = self.view.frame.width  / sampleSize.width
        let scaleForHeight = self.view.frame.height / sampleSize.height
        let newFontSize    = min(scaleForWidth, scaleForHeight) * 100

        self.textFieldTime.font = NSFont(name: fontName, size: newFontSize)
                               ?? NSFont.monospacedDigitSystemFont(ofSize: newFontSize, weight: .regular)
    }
    
    override func viewWillAppear() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {
            timer in
            
            //Do Some Stuff while the track is playing to update the UI...
            let date     = Date()
            let calendar = Calendar.current
            let hours    = calendar.component(.hour, from: date)
            let minutes  = calendar.component(.minute, from: date)
            let seconds  = calendar.component(.second, from: date)
            
            var time = " "
            if(hours < 10) {
                time += "0\(hours)"
            }else{
                time += "\(hours)"
            }
            
            if(minutes < 10) {
                time += ":0\(minutes)"
            }else{
                time += ":\(minutes)"
            }
            
            if(seconds < 10) {
                time += ":0\(seconds)"
            }else{
                time += ":\(seconds)"
            }
            
            DispatchQueue.main.async(qos: .default) {
                self.textFieldTime.stringValue = time.asTime()
            }
            
        })
    }
    
    override func viewDidDisappear() {
        self.timer?.invalidate()
    }
}
