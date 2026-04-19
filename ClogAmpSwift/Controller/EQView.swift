//
//  BpmClickView.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 29.11.23.
//  Copyright © 2023 Pascal Roessel. All rights reserved.
//

class EQView: ViewController {
    
    @IBOutlet weak var freqHighSlider: NSSlider!
    @IBOutlet weak var freqMidSlider: NSSlider!
    @IBOutlet weak var freqLowSlider: NSSlider!
    
    @IBAction func freqChangedLow(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.floatValue, forKey: "eqFrequencyLow")
        PlayerAudioEngine.shared.setFrequencyDbLow(newTargetDb: sender.floatValue)
    }
    
    @IBAction func freqChangedMid(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.floatValue, forKey: "eqFrequencyMid")
        PlayerAudioEngine.shared.setFrequencyDbMid(newTargetDb: sender.floatValue)
    }
    
    @IBAction func freqChangedHigh(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.floatValue, forKey: "eqFrequencyHigh")
        PlayerAudioEngine.shared.setFrequencyDbHigh(newTargetDb: sender.floatValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        freqHighSlider.floatValue = AppPreferences.eqFrequencyHigh
        freqMidSlider.floatValue = AppPreferences.eqFrequencyMid
        freqLowSlider.floatValue = AppPreferences.eqFrequencyLow
    }
    
}
