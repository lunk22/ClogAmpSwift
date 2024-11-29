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
    @IBOutlet weak var lengthField:      NSTextField!
    @IBOutlet weak var volumeSlider:     NSSlider!
    @IBOutlet weak var volumeText:       NSTextField!
    @IBOutlet weak var speedSlider:      NSSlider!
    @IBOutlet weak var speedText:        NSTextField!
    
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var bpmText:    NSTextField!
    
    @IBOutlet weak var btnPlay:  NSButton!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var btnStop:  NSButton!
        
    //MARK: Properties
    var observer: Any?
    
    private let imgHeight = 21
    private let imgWidth = 21
    
    private let colorGray = NSColor.darkGray
    
    private var imgPlayGray:  NSImage
    private var imgPauseGray: NSImage
    private var imgStopGray:  NSImage
    
    private var imgPlay:  NSImage
    private var imgPause: NSImage
    private var imgStop:  NSImage
    
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
            
            self.descriptionField.stringValue = "\(title) (\(duration))"
            
            //Time, Speed, Volume, Player Buttons
            self.updateTimeInUI()
            self.updatePositionTable(single: true)
            
            self.mainView?.pdfView?.findPdfForSong(
                songName: self.currentSong?.getValueAsString("title") ?? "",
                fileName: self.currentSong?.filePathAsUrl.lastPathComponent ?? ""
            )
            
            if Settings.autoDetermineBpm && self.currentSong!.bpm == 0 {
                self.determineBpmFCS()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        imgPlayGray = NSImage(shape: "play",   color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        imgPauseGray = NSImage(shape: "pause", color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        imgStopGray = NSImage(shape: "stop",   color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        
        imgPlay = NSImage(shape: "play",   color: .systemGreen,  size: NSSize(width: imgWidth, height: imgHeight))
        imgPause = NSImage(shape: "pause", color: .systemYellow, size: NSSize(width: imgWidth, height: imgHeight))
        imgStop = NSImage(shape: "stop",   color: .systemRed,    size: NSSize(width: imgWidth, height: imgHeight))

        super.init(coder: aDecoder)
        
        PlayerAudioEngine.shared.setTimeObserverCallback() { _ in
            //Do stuff
            self.tick()
            self.updatePositionTable(single: false)
            self.updateMeters()
        }

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.playing, object: nil, queue: .current) { _ in
            self.btnPlay.image  = Settings.colorizedPlayerState ? self.imgPlay : self.imgPlayGray
            self.btnPause.image = self.imgPauseGray
            self.btnStop.image  = self.imgStopGray
            
            self.mainView?.mainWindow?.tbPlay.image  = Settings.colorizedPlayerState ? self.imgPlay : self.imgPlayGray
            self.mainView?.mainWindow?.tbPause.image = self.imgPauseGray
            self.mainView?.mainWindow?.tbStop.image  = self.imgStopGray
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.paused, object: nil, queue: .current) { _ in
            self.btnPlay.image  = self.imgPlayGray
            self.btnPause.image = Settings.colorizedPlayerState ? self.imgPause : self.imgPauseGray
            self.btnStop.image  = self.imgStopGray
            
            self.mainView?.mainWindow?.tbPlay.image  = self.imgPlayGray
            self.mainView?.mainWindow?.tbPause.image = Settings.colorizedPlayerState ? self.imgPause : self.imgPauseGray
            self.mainView?.mainWindow?.tbStop.image  = self.imgStopGray
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopped, object: nil, queue: .current) { _ in
            self.btnPlay.image  = self.imgPlayGray
            self.btnPause.image = self.imgPauseGray
            self.btnStop.image  = Settings.colorizedPlayerState ? self.imgStop : self.imgStopGray
            
            self.mainView?.mainWindow?.tbPlay.image  = self.imgPlayGray
            self.mainView?.mainWindow?.tbPause.image = self.imgPauseGray
            self.mainView?.mainWindow?.tbStop.image  = Settings.colorizedPlayerState ? self.imgStop : self.imgStopGray
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
    
    func updateMeters() {
        if Settings.audioMetering {
            let meteringLevelImgHeight = Float(self.imgHeight) * (PlayerAudioEngine.shared.meteringLevel / 100)
            
            if PlayerAudioEngine.shared.isPlaying(){
                self.btnPlay.image = NSImage(shape: "play", color: .systemGreen, size: NSSize(width: self.imgWidth, height: self.imgHeight), fillHeight: Double(meteringLevelImgHeight))
            }
        }
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
            
            if(Settings.countdownTime) {
                currentTime = Double(duration) - currentTime
            }
            
            //Time Field: e.g. 3:24
            let durMinutes = Int(Float(currentTime / 60).rounded(.down))
            let durSeconds = Int(Double(currentTime).truncatingRemainder(dividingBy: 60))
            
            let sSeconds = durSeconds >= 10 ? "\(durSeconds)" : "0\(durSeconds)"
            let sMinutes = durMinutes >= 10 ? "\(durMinutes)" : "\(durMinutes)"
            
            if Settings.countdownTime {
                self.lengthField.stringValue = "- \(sMinutes):\(sSeconds)".asTime()
            }else{
                // 2 spaces equal the size of the minus
                // => Minus plus the space = 3 spaces
                self.lengthField.stringValue = "   \(sMinutes):\(sSeconds)".asTime()
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
    
    @IBAction func changeTimeDisplay(_ sender: AnyObject) {
        UserDefaults.standard.set(!Settings.countdownTime, forKey: "countTimeDown")
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
        self.currentSong?.determineBassBPM(){ _ in
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
