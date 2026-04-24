//
//  BpmClickViewController.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 29.11.23.
//

class BpmClickViewController: ViewController {
    
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
        
        // Remove outliers: trim ~10% from each end, minimum 1 when enough data
        distances.sort()
        if distances.count > 2 {
            let trimCount = max(1, distances.count / 10)
            distances.removeFirst(trimCount)
            distances.removeLast(trimCount)
        }
        
        // Sum all distances and calculate average
        for distance in distances {
            cumulatedTimeDiff += distance
        }
                        
        let averageTime = (cumulatedTimeDiff / Double(distances.count) * roundingFactor).rounded() / roundingFactor
        
        // BPM = amount of average distance in 60 seconds
        let bpm = 60.0 / averageTime
                
        calculatedBpmText.stringValue = "\(lround(bpm))"
        
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
