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
        willSet {
            PlayerAudioEngine.shared.song?.saveChanges()
        }
        didSet {
            PlayerAudioEngine.shared.stop()
            self.currentSong!.loadPositions()
            
            PlayerAudioEngine.shared.song = self.currentSong!
            
            let x = self.currentSong!.getValueAsString("path")
            UserDefaults.standard.set(x, forKey: "lastLoadedSongURL")
            
            //Update UI
            //Text of selected song
            let title = self.currentSong!.getValueAsString("title")
            let duration = self.currentSong!.getValueAsString("duration")
            
            self.descriptionField.stringValue = "\t\(title) (\(duration))"
            
            //Time, Speed, Volume, Player Buttons
            self.updateTimeInUI()
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        PlayerAudioEngine.shared.setTimeObserverCallback() {
            _ in
            //Do stuff
            self.tick()
            self.updatePositionTable(single: false)
        }

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.playing, object: nil, queue: .current) { _ in
            self.btnPlay.image  = Defaults.colorizedPlayerState ? NSImage(named: "play") : NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = Defaults.colorizedPlayerState ? NSImage(named: "play") : NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.paused, object: nil, queue: .current) { _ in
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = Defaults.colorizedPlayerState ? NSImage(named: "pause") : NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = Defaults.colorizedPlayerState ? NSImage(named: "pause") : NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopped, object: nil, queue: .current) { _ in
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = Defaults.colorizedPlayerState ? NSImage(named: "stop") : NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = Defaults.colorizedPlayerState ? NSImage(named: "stop") : NSImage(named: "stopGray")
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.rateChanged, object: nil, queue: .current) { _ in
            self.updateRateInUI()
        }
        
        NotificationCenter.default.addObserver(forName: Song.NotificationNames.bpmChanged, object: nil, queue: .current) { _ in
            self.updateRateInUI()
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.volumeChanged, object: nil, queue: .current) { _ in
            self.updateVolumeInUI()
        }
        
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
    }
    
    @objc func updateRateInUI(){
        DispatchQueue.main.async(qos: .default) {
            if let song = PlayerAudioEngine.shared.song {
                self.speedSlider.integerValue = song.speed
                self.speedText.stringValue    = "\(song.speed)%"
                
                if var bpm = self.currentSong?.bpm {
                    if bpm > 0 {
                        let percent = Double(Int(100) + Int(song.speed)) / 100
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
    }

    func updateTimeInUI() {
        DispatchQueue.main.async(qos: .default) {
            var currentTime = PlayerAudioEngine.shared.getCurrentTime(rounded: true)
            let duration = PlayerAudioEngine.shared.getDuration()
            let percent: Double = currentTime / Double(duration) * 100
            
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
            
            // timeSlider has a range of 0 - 100k, so multiply percent by 1000
            self.timeSlider.integerValue = lround(percent * 1000)
        }
    }
    
    func updateVolumeInUI(){
        DispatchQueue.main.async(qos: .default) {
            if let song = PlayerAudioEngine.shared.song {
                self.volumeSlider.integerValue = song.volume
                self.volumeText.stringValue    = "\(song.volume)%"
            }
        }
    }
    
    func updatePositionTable(single: Bool){
        self.mainView?.positionTableView?.refreshTable(single: single)
    }
    
    func updateSongTable(){
        self.mainView?.songTableView?.refreshTable()
    }
    
    //MARK: Actions    
    @IBAction func speedChanged(_ sender: NSSlider) {
        let newSpeed = sender.integerValue
        self.setSpeed(newSpeed)
    }
    
    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.setVolume(Int(sender.integerValue))
    }
    
    @IBAction func timeChanged(_ sender: NSSlider) {
        let v1 = Double(sender.integerValue) / sender.maxValue
        let duration = PlayerAudioEngine.shared.getDuration()
        let time = duration * v1
        PlayerAudioEngine.shared.seek(seconds: time)
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
            PlayerAudioEngine.shared.song?.saveChanges()
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
            PlayerAudioEngine.shared.seek(seconds: Float64(oPosition.time / 1000))
            
            if Defaults.playPositionOnSelection && !(PlayerAudioEngine.shared.isPlaying()){
                PlayerAudioEngine.shared.play()
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
    
    func jump(_ seconds: Int) {
        PlayerAudioEngine.shared.jump(seconds)
    }
    
    func setSpeed(_ newSpeed: Int) {
        PlayerAudioEngine.shared.setRate(newSpeed)
    }
    
    func increaseSpeed() {
        if let song = PlayerAudioEngine.shared.song {
            if(song.speed == 40){
                return
            }

            self.setSpeed(song.speed + 1)
        }
    }
    
    func decreaseSpeed() {
        if let song = PlayerAudioEngine.shared.song {
            if(song.speed == -40){
                return
            }
            
            self.setSpeed(song.speed - 1)
        }
    }
    
    func resetSpeed() {
        self.setSpeed(0)
    }
    
    func setVolume(_ newVolume: Int) {
        PlayerAudioEngine.shared.setVolume(newVolume)
    }
}
