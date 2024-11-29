//
//  BeatPlayerView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 26.11.19.
//  MIT License
//

import Foundation
import AVFoundation

class BeatPlayerView: ViewController {
    
    var defaultBpm = 75
    var quaterCounter = 0
    var beatCounter = 0
    var stringPosition = 0
    
    var player: AVAudioPlayer?
    
    var timer: Timer?
    
    @IBOutlet weak var txtBPM: NSTextField!
    @IBOutlet weak var txtBeats: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.txtBPM.placeholderString = "\(self.defaultBpm)"
//        //Joey Greg
//        self.txtBeats.stringValue = "&a1 &2 & 3 e & a 4 & 5 e& a 6e & a 7 e& a 8 &"
    }
    
    override func viewDidDisappear() {
        self.stopPeriodicFunction()
    }
    
    func preparePlayer() {
        let primeUrl = Bundle.main.url(forResource: "PrimeAV", withExtension: "mp3")!
        let clickUrl = Bundle.main.url(forResource: "Click", withExtension: "mp3")!

        do {
    
            self.player = try AVAudioPlayer(contentsOf: primeUrl)
            self.player!.prepareToPlay()
            self.player!.volume = 0.025
            self.player!.play()
            delayWithSeconds(0.1) {
                self.player!.volume = 1
                
                do {
                    self.player = try AVAudioPlayer(contentsOf: clickUrl)
                    self.player!.prepareToPlay()
                } catch {}
            }

        } catch { }
    }
    
    func playSound() {
        if self.player != nil {
            self.player!.stop()
            self.player!.play()
        }
    }
    
    func printTime(andText text: String? = nil) {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss SSS"
//
//        if text != nil{
//            print("\(formatter.string(from: Date())) - \(text!)")
//        }else{
//            print("\(formatter.string(from: Date()))")
//        }
    }
    
    func startPeriodicFunction(withBPM bpm: Int, closure: @escaping() -> () ) {
        if bpm == 0 { return }
        
        self.preparePlayer()
        
        let delay = Double(60) / Double(bpm) / Double(4)
                
        self.timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: true){_ in
            closure()
        }
        
        self.timer?.fire()
    }
    
    func stopPeriodicFunction() {
        self.timer?.invalidate()
        
        self.quaterCounter  = 0
        self.beatCounter    = 0
        self.stringPosition = 0
    }
    
    @IBAction func handlePlayBeats(_ sender: Any) {
        if self.txtBeats.stringValue == "" { return }
        
        var bpm = self.txtBPM?.integerValue ?? 0
        
        if bpm == 0 {
            bpm = self.defaultBpm
            self.txtBPM?.integerValue = self.defaultBpm
        }
        
        self.stopPeriodicFunction()
        self.startPeriodicFunction(withBPM: bpm) {
            let beatsString = self.txtBeats.stringValue

            if self.stringPosition == beatsString.count || self.quaterCounter >= 100 {
                self.stopPeriodicFunction()
                return
            }

            var count = 0
            var currentChar = "\(beatsString[self.stringPosition])"
            while currentChar == " " {
                self.stringPosition += 1
                currentChar = "\(beatsString[self.stringPosition])"
            }
            
            if Int(currentChar) != nil && Int(beatsString[self.stringPosition+1]) != nil {
               currentChar = "\(beatsString[self.stringPosition])\(beatsString[self.stringPosition+1])"
               count = 1
            }
            
            // Determine the current quater beat to be played
            var bIsE    = false
            var bIsAnd  = false
            var bIsA    = false
            var bIsBeat = false
            var printChar = ""
            switch(self.quaterCounter % 4){
                case 0:
                    bIsE = true
                    printChar = "e"
                    break
                case 1:
                    bIsAnd = true
                    printChar = "&"
                    break
                case 2:
                    bIsA = true
                    printChar = "a"
                    break
                case 3:
                    bIsBeat = true
                    printChar = "1"
                    self.beatCounter += 1
                    break
                default: break // nothing
            }
            
            if (bIsE && currentChar.lowercased() == "e") ||
               (bIsAnd && currentChar == "&") ||
               (bIsA && currentChar.lowercased() == "a") ||
               (bIsBeat && Int(currentChar) != nil && self.beatCounter == Int(currentChar)){

                self.stringPosition += 1 + count

                self.playSound()
                
                self.printTime(andText: "\(printChar) - beatCounter: \(self.beatCounter) - currentChar: \(currentChar) - click")

            }else{
                self.printTime(andText: "\(printChar) - beatCounter: \(self.beatCounter) - currentChar: \(currentChar)")
            }

            self.quaterCounter += 1
        }
    }
    
    @IBAction func handleStop(_ sender: Any) {
        self.stopPeriodicFunction()
    }
    
}
