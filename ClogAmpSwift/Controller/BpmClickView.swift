//
//  BpmClickView.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 29.11.23.
//

class BpmClickView: ViewController {
    
    @IBOutlet weak var calculatedBpmText: NSTextField!
    
    let eventArrayMinSize = 4
    let eventArrayMaxSize = 50
    let roundingFactor: Double = 10000
    
    var eventArray: Array<Date> = []
    var timeoutWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    override func viewDidAppear() {
//        super.viewDidAppear()
//        
//        let window = NSApplication.shared.windows.first() { window in
//            return window.identifier?.rawValue ?? "" == "bpmClickWindow"
//        }
//        
//        if window != nil {
//            window?.center()
//        }
//    }
    
    override func viewDidDisappear() {
        clear()
    }
    
    @IBAction func handleBpmButtonClicked(_ sender: Any) {
        eventArray.append(Date())
        
        var cumulatedTimeDiff: Double = 0.0
        var prefEventDate: Date?
        
        if eventArray.count < eventArrayMinSize { return }
        if eventArray.count > eventArrayMaxSize { eventArray.removeFirst() }
        
        var distances: Array<Double> = []
        
        // Calculate distances between events
        for eventDate in eventArray {
            if prefEventDate != nil {
                let distance = (prefEventDate!.distance(to: eventDate) * roundingFactor).rounded() / roundingFactor
                distances.append(distance)
            }
            
            prefEventDate = eventDate
        }
        
        // Remove min/max distance
        distances.sort()
        distances.removeFirst()
        distances.removeLast()
        
        // Sum all distances and calculate average
        for distance in distances {
            cumulatedTimeDiff += distance
        }
                        
        let averageTime = (cumulatedTimeDiff / Double(distances.count) * roundingFactor).rounded() / roundingFactor
        
        // BPM = amount of average distance in 60 seconds
        let bpm = 60.0 / averageTime
                
        if eventArray.count % 2 == 0 {
            calculatedBpmText.stringValue = "\(lround(bpm))"
        }
        
        // Cancel timeout handler
        if timeoutWorkItem != nil {
            timeoutWorkItem!.cancel()
            timeoutWorkItem = nil
        }
        
        // Create new, non-canceled worker item
        timeoutWorkItem = DispatchWorkItem(block: {
            self.clear()
        })
        
        // Schedule worker item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: timeoutWorkItem!)
    }
    
    func clear() {
        eventArray = []
        timeoutWorkItem = nil
    }
    
}
