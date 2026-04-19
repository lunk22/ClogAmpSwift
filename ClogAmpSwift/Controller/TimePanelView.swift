//
//  TimePanelView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 28.01.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class TimePanelView: ViewController {
    // MARK: Outlets
    @IBOutlet weak var textFieldTime: NSTextField!
    
    // MARK: Properties
    var timer: Timer?
    
    
    // MARK: Functions
    override func viewWillLayout() {
        // Determine relevant settings
        let width  = self.view.frame.width
        let height = self.view.frame.height
        let fontName = self.textFieldTime.font?.fontName ?? "Monaco"
        
        // Calculate height
        // let height = width / 4.554
        
        // Calculate font size
        let newFontSizeForWidth: CGFloat = width / 5.372
        let newFontSizeForHeight: CGFloat = height / 1.179
        let newFontSize = min(newFontSizeForWidth, newFontSizeForHeight)
        
        // Update UI
        self.textFieldTime.font = NSFont.init(name: fontName, size: CGFloat(newFontSize))
    }
    
    override func viewWillAppear() {
//        self.textFieldTime.font = NSFont.init(name: "B612-Regular", size: CGFloat(70))
        self.textFieldTime.alignment = .center
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {
            timer in
            
            //Do Some Stuff while the track is playing to update the UI...
            let date     = Date()
            let calendar = Calendar.current
            let hours    = calendar.component(.hour, from: date)
            let minutes  = calendar.component(.minute, from: date)
            let seconds  = calendar.component(.second, from: date)
            
            var time = ""
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
                self.textFieldTime.stringValue = time.replacingOccurrences(of: "0", with: "O")
//                self.textFieldTime.sizeToFit()
            }
            
        })
    }
    
    override func viewDidDisappear() {
        self.timer?.invalidate()
    }
}
