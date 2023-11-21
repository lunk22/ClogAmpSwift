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
    
    //MARK: Outlets
    
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var lengthField: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var volumeText: NSTextField!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var speedText: NSTextField!
    
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var bpmText: NSTextField!
    
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    
    //MARK: Properties
    var observer: Any?
    
    var currentSong: Song? {
        willSet(oNewSong) {
            self.currentSong?.saveChanges()
        }
        didSet {
            self.doStop()
            self.currentSong!.loadPositions()
            
            self.avPlayer?.song = self.currentSong!
            
            let x = self.currentSong!.getValueAsString("path")
            UserDefaults.standard.set(x, forKey: "lastLoadedSongURL")
            
            //Update UI
            //Text of selected song
            let title = self.currentSong!.getValueAsString("title")
            let duration = self.currentSong!.getValueAsString("duration")
            
            self.descriptionField.stringValue = "\t\(title) (\(duration))"
            
            //Time, Speed, Volume, Player Buttons
            self.updateTimeInUI()
            self.updateRateInUI()
            self.updateVolumeInUI()
            self.updatePlayerStateInUI()
            self.updatePositionTable(single: true)
            
            self.mainView?.pdfView?.findPdfForSong(
                songName: self.currentSong?.getValueAsString("title") ?? "",
                fileName: self.currentSong?.filePathAsUrl.lastPathComponent ?? ""
            )
            
            if Defaults.autoDetermineBpm && self.currentSong!.bpm == 0 {
                self.determineBpmFCS()
            }
        }
    }
    
    var avPlayer: PlayerAudioEngine?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.avPlayer = PlayerAudioEngine()
        self.avPlayer?.addTimeObserverCallback(using: {
            _ in
            //Do stuff
            self.tick()
            self.updatePositionTable(single: false)
        })
    }
    
    /*
     * General Stuff
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: Update related stuff
    
    func tick() {        
        self.updateTimeInUI()
        self.updatePositionTable(single: true)
        self.updatePlayerStateInUI()
    }
    
    func updatePlayerStateInUI() {
        if Defaults.colorizedPlayerState {
            if self.avPlayer?.isPlaying() ?? false {
                self.btnPlay.image  = NSImage(named: "play")
                self.btnPause.image = NSImage(named: "pauseGray")
                self.btnStop.image  = NSImage(named: "stopGray")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "play")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
            } else if (self.avPlayer?.isPaused() ?? false) {
                self.btnPlay.image  = NSImage(named: "playGray")
                self.btnPause.image = NSImage(named: "pause")
                self.btnStop.image  = NSImage(named: "stopGray")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pause")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
            } else {
                self.btnPlay.image  = NSImage(named: "playGray")
                self.btnPause.image = NSImage(named: "pauseGray")
                self.btnStop.image  = NSImage(named: "stop")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stop")
            }
        } else {
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
    }
    
    func updateRateInUI(){        
        DispatchQueue.main.async(qos: .userInitiated) {
            self.speedSlider.integerValue = self.currentSong?.speed ?? 0
            self.speedText.stringValue    = "\(self.currentSong?.speed ?? 0)%"
            
            if var bpm = self.currentSong?.bpm {
                if bpm > 0 {
                    let percent = Double(Int(100) + Int(self.currentSong?.speed ?? 0)) / 100
                    bpm = Int(lround((Double(bpm) * percent)))
                    self.bpmText.stringValue = "\(bpm) bpm"
                }else{
                    self.bpmText.stringValue = ""
                }
            }else{
                self.bpmText.stringValue = ""
            }
            
            self.updateSongTable()
        }
    }

    func updateTimeInUI() {
        DispatchQueue.main.async(qos: .userInitiated) {
            var percent: Double = 0.0;
            if(self.currentSong != nil) {
                var currentTime = self.avPlayer?.getCurrentTime() ?? 0

                if(currentTime.isNaN){
                    currentTime = 0
                }
                
                //Position Slider
                let duration = self.currentSong?.duration ?? 0

                if(duration > 0){
                    percent = currentTime / Double(duration) * 100
                }
                
                if(Defaults.countdownTime) {
                    currentTime = Double(duration) - currentTime
                }
                
                //Time Field: e.g. 3:24
                let durMinutes = Int(Float(currentTime / 60).rounded(.down))
                let durSeconds = Int(Double(currentTime).truncatingRemainder(dividingBy: 60))
                
                let sSeconds = durSeconds >= 10 ? "\(durSeconds)" : "0\(durSeconds)"
                let sMinutes = durMinutes >= 10 ? "\(durMinutes)" : "\(durMinutes)"
                
                if Defaults.countdownTime {
                    self.lengthField.stringValue = "- \(sMinutes):\(sSeconds)"
                }else{
                    self.lengthField.stringValue = "\t\(sMinutes):\(sSeconds)"
                }
            }
            
            // timeSlider has a range of 0 - 100k, so multiply percent by 1000
            self.timeSlider.integerValue = lround(percent * 1000)
        }
    }
    
    func updateVolumeInUI(){
        DispatchQueue.main.async(qos: .userInitiated) {
            self.volumeSlider.integerValue = Int(self.currentSong?.volume ?? 100)
            self.volumeText.stringValue    = "\(self.currentSong?.volume ?? 100)%"
        }
    }
    
    func updatePositionTable(single: Bool){
        self.mainView?.positionTableView?.refreshTable(single: single)
    }
    
    func updateSongTable(){
        self.mainView?.songTableView?.refreshTable()
    }
    
    //MARK: Actions

    @IBAction func play(_ sender: Any) {
        self.doPlay()
    }
    
    @IBAction func pause(_ sender: Any) {
        self.doPause()
    }
    
    @IBAction func stop(_ sender: Any) {
        self.doStop()
    }
    
    @IBAction func speedChanged(_ sender: NSSlider) {
        let newSpeed = sender.integerValue
        self.setSpeed(newSpeed)
    }
    
    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.setVolume(Int(sender.integerValue))
    }
    
    @IBAction func timeChanged(_ sender: NSSlider) {
        let v1 = Double(sender.integerValue) / sender.maxValue
        let duration = self.avPlayer?.getDuration() ?? 0
        let time = duration * v1
        self.avPlayer?.seek(seconds: time)
    }
    
    @IBAction func changeTimeDisplay(_ sender: NSButton) {
        UserDefaults.standard.set(!Defaults.countdownTime, forKey: "countTimeDown")
        self.updateTimeInUI()
    }
    
    @IBAction func increaseSpeedButtonClicked(_ sender: AnyObject) {
        self.increaseSpeed()
    }
    
    @IBAction func decreaseSpeedButtonClicked(_ sender: AnyObject) {
        self.decreaseSpeed()
    }
    
    @IBAction func increaseVolumeButtonClicked(_ sender: AnyObject) {
        let currentVolume = self.currentSong?.volume ?? -1
        if(currentVolume >= 0 && currentVolume < 100){
            self.currentSong?.volume = Int(currentVolume + 1)
        }
        self.updateVolumeInUI()
    }
    
    @IBAction func decreaseVolumeButtonClicked(_ sender: AnyObject) {
        let currentVolume = self.currentSong?.volume ?? -1
        if(currentVolume > 0){
            self.currentSong?.volume = Int(currentVolume - 1)
        }
        self.updateVolumeInUI()
    }
    
    // MARK: Custom Functions
    
    func determineBpmFCS() {
        self.currentSong?.determineBassBPM(){
            _ in
            self.currentSong?.saveChanges()
            self.mainView?.songTableView?.refreshTable()
            self.updateRateInUI()
        }
    }

    func handlePositionSelected(_ index: Int) {
        //Check the index is in range
        if(index == -1 || self.currentSong?.getPositions().count ?? -1 <= index){
            return
        }
        
        if let oPosition = self.currentSong?.getPositions()[index] {
            self.avPlayer?.seek(seconds: Float64(oPosition.time / 1000))
            
            if Defaults.playPositionOnSelection && !(self.avPlayer?.isPlaying() ?? false){
                self.doPlay()
            }
            
        }
    } //func handlePositionSelected
    
    func loadSong(song: Song) {
        if song.songFileExists() {
            self.currentSong = song
        }
    }
    
    func getSong() -> Song? {
        return self.currentSong
    }
    
    func doPlay() {
        if(self.avPlayer?.isPlaying() ?? false){
            //If play is called while the song is playing, it should start over
            self.avPlayer?.seek(seconds: 0.0)
            self.mainView?.positionTableView?.positionTable.scrollToBeginningOfDocument(nil)
        }else{
            if(self.avPlayer?.getCurrentTime() == 0.0){
                self.mainView?.positionTableView?.positionTable.scrollToBeginningOfDocument(nil)
            }
            self.avPlayer?.play()
        }
        
    }
    
    @objc func doPause() {
        if(self.avPlayer?.isPlaying() ?? false){
            self.avPlayer?.pause()
            self.tick()
        }else{
            self.doPlay()
        }
    }
    
    func doStop() {
        self.avPlayer?.stop()
    }
    
    func jump(_ seconds: Int) {
        self.avPlayer?.jump(seconds)
    }
    
    func setSpeed(_ newSpeed: Int) {
        self.currentSong?.speed = newSpeed
        self.avPlayer?.updateRate()
        self.updateRateInUI()
    }
    
    func increaseSpeed() {
        if(self.currentSong?.speed == 40){
            return
        }
        
        if(self.currentSong?.speed != nil) {
            self.setSpeed(self.currentSong!.speed + 1)
        }
    }
    
    func decreaseSpeed() {
        if(self.currentSong?.speed == -40){
            return
        }
        
        if(self.currentSong?.speed != nil) {
            self.setSpeed(self.currentSong!.speed - 1)
        }
    }
    
    func resetSpeed() {
        self.setSpeed(0)
    }
    
    func setVolume(_ newVolume: Int) {
        self.currentSong?.volume = newVolume
        self.avPlayer?.updateVolume()
        self.updateVolumeInUI()
    }
}
