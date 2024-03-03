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
            
            if AppPreferences.autoDetermineBpm && self.currentSong!.bpm == 0 {
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
            self.btnPlay.image  = AppPreferences.colorizedPlayerState ? NSImage(named: "play") : NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = AppPreferences.colorizedPlayerState ? NSImage(named: "play") : NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.paused, object: nil, queue: .current) { _ in
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = AppPreferences.colorizedPlayerState ? NSImage(named: "pause") : NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = AppPreferences.colorizedPlayerState ? NSImage(named: "pause") : NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopped, object: nil, queue: .current) { _ in
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = AppPreferences.colorizedPlayerState ? NSImage(named: "stop") : NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = AppPreferences.colorizedPlayerState ? NSImage(named: "stop") : NSImage(named: "stopGray")
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
        
//        // Initial values
//        let volume = UserDefaults.standard.integer(forKey: "playerVolume")
//        self.volumeSlider.integerValue = volume > 0 ? volume : 100
//        self.volumeText.stringValue    = "\(self.volumeSlider.integerValue)%"
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
        if PlayerAudioEngine.shared.song == nil { return }
        
        DispatchQueue.main.async(qos: .default) {
            var currentTime = PlayerAudioEngine.shared.getCurrentTime(rounded: true)
            let duration = PlayerAudioEngine.shared.getDuration()
            let percent: Double = currentTime / Double(duration) * 100
            
            if(AppPreferences.countdownTime) {
                currentTime = Double(duration) - currentTime
            }
            
            //Time Field: e.g. 3:24
            let durMinutes = Int(Float(currentTime / 60).rounded(.down))
            let durSeconds = Int(Double(currentTime).truncatingRemainder(dividingBy: 60))
            
            let sSeconds = durSeconds >= 10 ? "\(durSeconds)" : "0\(durSeconds)"
            let sMinutes = durMinutes >= 10 ? "\(durMinutes)" : "\(durMinutes)"
            
            if AppPreferences.countdownTime {
                self.lengthField.stringValue = "- \(sMinutes):\(sSeconds)".asTime()
            }else{
                self.lengthField.stringValue = "\(sMinutes):\(sSeconds)".asTime()
            }
            
            // timeSlider has a range of 0 - 100k, so multiply percent by 1000
            self.timeSlider.integerValue = lround(percent * 1000)
        }
    }
    
    func updateVolumeInUI(){
        DispatchQueue.main.async(qos: .default) {
            if PlayerAudioEngine.shared.song != nil {
                self.volumeSlider.integerValue = PlayerAudioEngine.shared.getVolume()
                self.volumeText.stringValue    = "\(self.volumeSlider.integerValue)%"
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
        UserDefaults.standard.set(!AppPreferences.countdownTime, forKey: "countTimeDown")
        self.updateTimeInUI()
    }
    
    @IBAction func increaseSpeedButtonClicked(_ sender: AnyObject) {
        self.increaseSpeed()
    }
    
    @IBAction func decreaseSpeedButtonClicked(_ sender: AnyObject) {
        self.decreaseSpeed()
    }
    
    @IBAction func increaseVolumeButtonClicked(_ sender: AnyObject) {
        let currentVolume = PlayerAudioEngine.shared.getVolume()
        if(currentVolume >= 0 && currentVolume < 100){
            PlayerAudioEngine.shared.setVolume(Int(currentVolume + 1))
        }
    }
    
    @IBAction func decreaseVolumeButtonClicked(_ sender: AnyObject) {
        let currentVolume = PlayerAudioEngine.shared.getVolume()
        if(currentVolume > 0) {
            PlayerAudioEngine.shared.setVolume(Int(currentVolume - 1))
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
    
    func increaseSpeed(_ offset: Int? = 1) {
        if let song = PlayerAudioEngine.shared.song {
            if(song.speed == 40){
                return
            }

            self.setSpeed(song.speed + (offset ?? 1))
        }
    }
    
    func decreaseSpeed(_ offset: Int? = 1) {
        if let song = PlayerAudioEngine.shared.song {
            if(song.speed == -40){
                return
            }
            
            self.setSpeed(song.speed - (offset ?? 1))
        }
    }
    
    func resetSpeed() {
        self.setSpeed(0)
    }
    
    func setVolume(_ newVolume: Int) {
        PlayerAudioEngine.shared.setVolume(newVolume)
    }
}
