//
//  PlayerView.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//  MIT License
//

import AppKit
import AVFoundation

class PlayerView: ViewController {
    
    weak var mainView: MainView?
    
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
        willSet(oNewSong) {
            self.currentSong?.saveChanges()
        }
        didSet {
            self.stop()
            
            self.currentSong!.loadPositions()
            self.avPlayer = AVPlayer(url: self.currentSong!.filePathAsUrl)
            //Update UI
            //Text of selected song
            self.descriptionField.stringValue = self.currentSong!.getValueAsString("title")
            //Speed, Volume, Time
            self.tick(single: true)
        }
    }
//    var avAudioPlayer: AVAudioPlayer? {
//        didSet {
//            self.avAudioPlayer!.prepareToPlay()
//            self.avAudioPlayer!.enableRate = true
//        }
//    }
    
    var avPlayer: AVPlayer? {
        didSet {
            self.tick(single: true)
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
    func tick(single: Bool, updateSongTab: Bool = false, updatePositionTab: Bool = true) {
        //Do Some Stuff while the track is playing to update the UI...
        self.updateTime()
        
        if(updatePositionTab){
            self.updatePositionTable(single: single)
        }
        
        if(single){
            self.updateRate()
            self.updateVolume()
        }
        
        if(updateSongTab){
            self.updateSongTable()
        }
        
        //re-trigger the update while the player is playing
        if (self.avPlayer?.rate ?? 0.0 > 0.0) || !single {
            delayWithSeconds(0.1) {
                self.tick(single: false)
            }
        }
    }
    
    func updateRate(){
        if(self.avPlayer?.rate ?? 0.0 > 0.0){
            self.avPlayer?.rate = 1.0 + Float(Float(self.currentSong!.speed) / 100)
        }
        
        self.speedSlider.integerValue = self.currentSong?.speed ?? 0
        self.speedText.stringValue    = "\(self.currentSong?.speed ?? 0)%"
    }
    func updateTime() {
        var percent: Int = 0;
        if(self.currentSong != nil) {
            //Time Field: e.g. 3:24
            let calcBase = /*self.avAudioPlayer!.duration -*/ self.avPlayer?.currentTime().value ?? 0
            let durMinutes = Int(Float(calcBase / 60).rounded(.down))
            let durSeconds = Int(Double(calcBase).truncatingRemainder(dividingBy: 60))
            
            self.lengthField.stringValue = durSeconds >= 10 ? "\(durMinutes):\(durSeconds)" : "\(durMinutes):0\(durSeconds)"
            
            //Position Slider
            let v1 = self.avPlayer?.currentTime().value ?? 0
            let v2 = self.avPlayer?.currentItem?.asset.duration.value ?? 0
            if(v2 > 0){
                percent = lround(Double(v1 / v2 * 10000))
            }
        }
        
        self.timeSlider.integerValue = percent
    }
    
    func updateVolume(){
        self.avPlayer?.volume          = Float(self.currentSong?.volume ?? 0) / 100
        self.volumeSlider.integerValue = Int(self.currentSong?.volume ?? 100)
        self.volumeText.stringValue    = "\(self.currentSong?.volume ?? 100)%"
    }
    
    func updatePositionTable(single: Bool){
        self.mainView?.positionTableView?.refreshTable(single: single)
    }
    
    func updateSongTable(){
        self.mainView?.songTableView?.refreshTable()
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
        let v1 = Double(sender.integerValue)
        let v2 = self.avPlayer?.currentItem?.asset.duration.value ?? 0
        let time = Int64(v1 / 10 * Double(v2))
        self.avPlayer?.seek(to: CMTimeMake(value: time, timescale: 1000))
        self.updateTime()
    }
//}
//
///*
// * PlayerDelegate Extension
// */
//extension PlayerView: PlayerDelegate {
    func handlePositionSelected(_ index: Int) {
        //Check the index is in range
        if(index == -1 || self.currentSong?.positions.count ?? -1 <= index){
            return
        }
        
        if let oPosition = self.currentSong?.positions[index] {
            self.avPlayer?.seek(to: CMTimeMake(value: Int64(oPosition.time), timescale: 1000))
            self.tick(single: true)
        }
    } //func handlePositionSelected
    
    func loadSong(song: Song) {
        self.currentSong = song
    }
    func getSong() -> Song? {
        return self.currentSong
    }
    func play() {
        if(self.avPlayer?.rate ?? 0.0 > 0.0){
            //If play is called while the song is playing, it should start over
            self.stop()
        }
        
        self.avPlayer?.play()
        //        self.avPlayer?.rate = 1.0
        //Start the Update of the UI every .xxx seconds
        self.tick(single: false)
        
    }
    func pause() {
        if(self.avPlayer?.rate ?? 0.0 > 0.0) {
            self.avPlayer?.rate = 0.0
            self.tick(single: true)
        } else {
            self.play()
        }
    }
    func stop() {
        self.avPlayer?.rate = 0.0
        self.avPlayer?.seek(to: CMTimeMake(value: 0, timescale: 1000))
        self.tick(single: true)
    }
    func jump(_ seconds: Int) {
        if var currentTime = self.avPlayer?.currentTime().value {
            currentTime = currentTime + Int64(seconds*1000)
            self.avPlayer?.seek(to: CMTimeMake(value: currentTime, timescale: 1000))
        }
        
        self.tick(single: true, updateSongTab: false, updatePositionTab: false)
    }
    func increaseSpeed() {
        if(self.currentSong?.speed == 40){
            return
        }
        self.currentSong?.speed += 1
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
    func decreaseSpeed() {
        if(self.currentSong?.speed == -40){
            return
        }
        self.currentSong?.speed -= 1
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
    func resetSpeed() {
        self.currentSong?.speed = 0
        self.tick(single: true, updateSongTab: true, updatePositionTab: false)
    }
}
