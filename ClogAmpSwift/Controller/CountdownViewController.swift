//
//  CountdownViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 18.02.19.
//

import Foundation

class CountdownViewController: ViewController {
    
    //MARK: Properties
    var timerSeconds: UInt = 0
    var calcTimerSeconds: UInt = 0
    var timer: Timer?
    
    override func viewDidLoad() {
        self.updateUiTimeField()
    }
    
    //MARK: Outlets
    @IBOutlet weak var timeField: NSTextField!
    
    //MARK: UI Actions
    @IBAction func add60Minutes(_ sender: NSButton) {
        self.timerSeconds     += 3600
        self.calcTimerSeconds += 3600
        self.updateUiTimeField()
    }
    @IBAction func add15Minutes(_ sender: NSButton) {
        self.timerSeconds     += 900
        self.calcTimerSeconds += 900
        self.updateUiTimeField()
    }
    @IBAction func add1Minute(_ sender: NSButton) {
        self.timerSeconds     += 60
        self.calcTimerSeconds += 60
        self.updateUiTimeField()
    }
    
    @IBAction func start(_ sender: NSButton) {
        if (self.timer?.isValid ?? false) {
            return
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.calcTimerSeconds > 0 {
                self.calcTimerSeconds -= 1
                self.updateUiTimeField()
            }else{
                self.updateUiTimeField()
                self.timer?.invalidate()
                self.timer = nil
            }
        }
    }
    @IBAction func pauseCountdown(_ sender: NSButton) {
        if(self.timer?.isValid ?? false){
            self.timer?.invalidate()
            self.timer = nil
            self.updateUiTimeField()
//        }else{
//            self.start(sender)
        }
    }
    @IBAction func stopCountdown(_ sender: NSButton) {
        self.timer?.invalidate()
        self.timer = nil
        self.calcTimerSeconds = self.timerSeconds
        self.updateUiTimeField()
    }
    
    @IBAction func reset(_ sender: NSButton) {
        self.timer?.invalidate()
        self.timer = nil
        self.calcTimerSeconds = 0
        self.timerSeconds = 0
        self.updateUiTimeField()
    }
    
    //MARK: Supporting Functions
    func updateUiTimeField() {
        var calcTime = self.calcTimerSeconds
        
        let sec  = calcTime % 60
        calcTime -= sec
        
        let min  = (calcTime % 3600) / 60
        calcTime -= min
        
        let hours = calcTime / 3600
        
        var sHours = "\(hours)"
        if(hours < 10){
            sHours = "0\(sHours)"
        }
        
        var sMin = "\(min)"
        if(min < 10){
            sMin = "0\(sMin)"
        }
        
        var sSec = "\(sec)"
        if(sec < 10){
            sSec = "0\(sSec)"
        }
        
        var timeString: String = " "
        timeString += "\(sHours)"
        timeString += ":\(sMin)"
        timeString += ":\(sSec)"
                
        self.timeField.stringValue = timeString.asTime()
    }
}
