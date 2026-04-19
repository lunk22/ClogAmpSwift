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
    @IBOutlet weak var timeSlider: NSSlider!
    
    
    /*
     * Properties
     */
    var currentSong: Song? {
        didSet {
            do {
                self.stop()
                
                self.currentSong!.loadPositions()
                self.avAudioPlayer = try AVAudioPlayer(contentsOf: self.currentSong!.path)
                
                //Update UI
                //Text of selected song
                self.descriptionField.stringValue = self.currentSong!.getValueAsString("title")
                //Speed, Volume, Time
                self.tick()
            } catch {
            }
        }
    }
    var avAudioPlayer: AVAudioPlayer? {
        didSet {
            self.avAudioPlayer!.enableRate = true
            self.avAudioPlayer!.prepareToPlay()
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
        if self.avAudioPlayer?.isPlaying ?? false {
            delayWithSeconds(0.01) {
                self.tick()
            }
        }
    }
    
    func updateRate(){
        self.avAudioPlayer?.rate      = 1.0 + Float(Float(self.currentSong!.speed) / 100)
        self.speedSlider.integerValue = self.currentSong!.speed
        self.speedText.stringValue    = "\(self.currentSong!.speed)%"
    }
    func updateTime() {
        //Time Field: e.g. 3:24
        let calcBase = /*self.avAudioPlayer!.duration -*/ self.avAudioPlayer?.currentTime
        let durMinutes = Int(((calcBase ?? 0) / 60).rounded(.down))
        let durSeconds = Int((calcBase ?? 0).truncatingRemainder(dividingBy: 60))
        
        self.lengthField.stringValue = durSeconds >= 10 ? "\(durMinutes):\(durSeconds)" : "\(durMinutes):0\(durSeconds)"
        
        //Position Slider
        let duration = self.avAudioPlayer?.duration
        let currentTime = self.avAudioPlayer?.currentTime
        let percent = lround((currentTime ?? 0) / (duration ?? 0) * 10000)
        self.timeSlider.integerValue = percent
    }
    
    func updateVolume(){
        self.avAudioPlayer?.volume     = Float(self.currentSong!.volume / 100)
        self.volumeSlider.integerValue = Int(self.currentSong!.volume)
        self.volumeText.stringValue    = "\(self.currentSong!.volume)%"
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
        let int = sender.integerValue
        self.currentSong?.speed = int
        self.updateRate()
    }
    
    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.currentSong?.volume = UInt(sender.integerValue)
        self.updateVolume()
    }
    
    @IBAction func timeChanged(_ sender: NSSlider) {
        let currentTime = Double(sender.integerValue) / 10000 * self.avAudioPlayer!.duration
        self.avAudioPlayer!.currentTime = currentTime;
        self.updateTime()
    }
}

/*
 * PlayerDelegate Extension
 */
extension PlayerView: PlayerDelegate {
    func handlePositionSelected(_ index: Int) {
        if let oPosition = self.currentSong?.positions[index] {
            let timeInterval = (Double(oPosition.time) / 1000) as TimeInterval
            self.avAudioPlayer?.currentTime = timeInterval
            self.tick()
        }
    } //func handlePositionSelected
    
    func loadSong(song: Song) {
        self.currentSong = song
    }
    func getSong() -> Song? {
        return self.currentSong
    }
    func play() {
        if((self.avAudioPlayer?.play() ?? false)){
            //Start the Update of the UI every .1 seconds
            self.tick()
        }
    }
    func pause() {
        if((self.avAudioPlayer?.isPlaying ?? false)) {
            self.avAudioPlayer?.pause()
        } else {
            self.play()
        }
    }
    func stop() {
        self.avAudioPlayer?.stop()
        self.avAudioPlayer?.currentTime = 0.0
        self.tick()
    }
    func increaseSpeed() {
        self.currentSong?.speed += 1
        self.tick()
    }
    func decreaseSpeed() {
        self.currentSong?.speed -= 1
        self.tick()
    }
}
