//
//  PlayerView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import AppKit
import AVFoundation

class PlayerView: NSViewController {
    /*
     * Outlets
     */
    
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var lengthField: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var volumeText: NSTextField!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var speedText: NSTextField!
    
    
    /*
     * Properties
     */
    var currentSong: Song? {
        didSet {
            do {
                self.avAudioPlayer = try AVAudioPlayer(contentsOf: self.currentSong!.path)
                
                self.descriptionField.stringValue = self.currentSong!.getValueAsString("title")
            } catch {
            }
        }
    }
    var avAudioPlayer: AVAudioPlayer? {
        didSet {
            self.avAudioPlayer!.enableRate = true
            self.avAudioPlayer!.prepareToPlay()
            
            self.updateRate()
            self.updateTime()
            self.updateVolume()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
     * General Stuff
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    /*
     * Update related stuff
     */
    func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
        }
    }
    func tick() {
        //Do Some Stuff while the track is playing to update the UI...
        self.updateRate()
        self.updateTime()
        self.updateVolume()
        
        
        //re-trigger the update while the player is playing
        if self.avAudioPlayer!.isPlaying {
            delayWithSeconds(0.01) {
                self.tick()
            }
        }
    }
    
    func updateRate(){
        self.avAudioPlayer?.rate = 1.0 + (self.speedSlider.floatValue / 100)
        self.speedText.stringValue = "\(self.speedSlider.integerValue)%"
    }
    func updateTime() {
        let calcBase = self.avAudioPlayer!.duration - self.avAudioPlayer!.currentTime
        
        let durMinutes = Int((calcBase / 60).rounded(.down))
        let durSeconds = Int(calcBase.truncatingRemainder(dividingBy: 60))
        
        self.lengthField.stringValue = durSeconds >= 10 ? "\(durMinutes):\(durSeconds)" : "\(durMinutes):0\(durSeconds)"
        
    }
    
    func updateVolume(){
        self.avAudioPlayer?.volume = self.volumeSlider.floatValue/100
        self.volumeText.stringValue = "\(self.volumeSlider.integerValue)%"
    }
    
    /*
     * Actions
     */
    @IBAction func play(_ sender: Any) {
        self.play()
    }
    
    @IBAction func pause(_ sender: Any) {
        self.pause()
    }
    
    @IBAction func stop(_ sender: Any) {
        self.stop()
    }
    
    @IBAction func speedChanged(_ sender: NSSlider) {
        self.updateRate()
    }
    
    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.updateVolume()
    }
    
}

/*
 * PlayerDelegate Extension
 */
extension PlayerView: PlayerDelegate {
    func loadSong(song: Song) {
        self.currentSong = song
        
    }
    func play() {
        self.avAudioPlayer!.play()
            
        //Start the Update of the UI every .1 seconds
        self.tick()
    }
    func pause() {
        if(self.avAudioPlayer!.isPlaying) {
            self.avAudioPlayer!.pause()
        } else {
            self.avAudioPlayer!.play()
        }
    }
    func stop() {
        self.avAudioPlayer!.stop()
        self.avAudioPlayer!.currentTime = 0.0
    }
}
