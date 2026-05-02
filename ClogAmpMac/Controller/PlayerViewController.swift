//
//  PlayerViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//

import AppKit
import AVFoundation

class PlayerViewController: ViewController {
    
    weak var mainView: MainViewController?
    
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

    private var beatOverlayView: NSView!
    private var beatOverlayLabel: NSTextField!

    private var prePlayCountdownTimer: Timer? = nil
    private var prePlayAudioStartTimer: Timer? = nil
    private var prePlayBeatNumber: Int = 0
    private var prePlaySeekTarget: Double = 0
    private var prePlayAnchorTime: Double = 0  // suppress in-song countdown until anchor passes
    
    var currentSong: Song? {
        willSet {
            PlayerAudioEngine.shared.song?.saveChanges()
        }
        didSet {
            PlayerAudioEngine.shared.stop()

            if self.currentSong == nil { return }

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
        
        imgPlayGray = NSImage(shape: .play,   color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        imgPauseGray = NSImage(shape: .pause, color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        imgStopGray = NSImage(shape: .stop,   color: self.colorGray, size: NSSize(width: imgWidth, height: imgHeight))
        
        imgPlay = NSImage(shape: .play,   color: .systemGreen,  size: NSSize(width: imgWidth, height: imgHeight))
        imgPause = NSImage(shape: .pause, color: .systemYellow, size: NSSize(width: imgWidth, height: imgHeight))
        imgStop = NSImage(shape: .stop,   color: .systemRed,    size: NSSize(width: imgWidth, height: imgHeight))

        super.init(coder: aDecoder)
        
        PlayerAudioEngine.shared.setTimeObserverCallback() { _ in
            //Do stuff
            self.tick()
            self.updatePositionTable(single: false)
            self.updateMeters()
        }

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.playRequested, object: nil, queue: .current) { _ in
            if PlayerAudioEngine.shared.isPlaying() {
                // Stop playback first, then treat as a fresh play-from-start
                PlayerAudioEngine.shared.stop()
            }
            if self.shouldStartPrePlayCountdown() {
                self.startPrePlayCountdown()
            } else {
                PlayerAudioEngine.shared.suppressPlayRequestedNotification = true
                PlayerAudioEngine.shared.play()
            }
        }

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopRequested, object: nil, queue: .current) { _ in
            self.cancelPrePlayCountdown()
        }

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.pauseRequested, object: nil, queue: .current) { _ in
            if self.prePlayCountdownTimer != nil {
                // Cancel countdown and suppress the play() call pause() makes when not playing
                self.cancelPrePlayCountdown()
                PlayerAudioEngine.shared.suppressPlayRequestedNotification = true
            }
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
            // Only cancel if pre-play countdown isn't actively running
            // (seek during countdown triggers a transient paused state)
            if self.prePlayCountdownTimer == nil {
                self.cancelPrePlayCountdown()
            }
            self.btnPlay.image  = self.imgPlayGray
            self.btnPause.image = Settings.colorizedPlayerState ? self.imgPause : self.imgPauseGray
            self.btnStop.image  = self.imgStopGray
            
            self.mainView?.mainWindow?.tbPlay.image  = self.imgPlayGray
            self.mainView?.mainWindow?.tbPause.image = Settings.colorizedPlayerState ? self.imgPause : self.imgPauseGray
            self.mainView?.mainWindow?.tbStop.image  = self.imgStopGray
        }
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopped, object: nil, queue: .current) { _ in
            self.cancelPrePlayCountdown()
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
        
        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.songNotFound, object: nil, queue: .current) { _ in
            self.currentSong = nil
        }
    }
    
    /*
     * General Stuff
     */
    override func viewDidLoad() {
        super.viewDidLoad()

        // Update slider styles
        if #available(macOS 26.0, *) {
            self.speedSlider.neutralValue = 0
            self.volumeSlider.neutralValue = 0
            self.timeSlider.neutralValue = 0
        }

        setupBeatOverlay()
    }

    private func setupBeatOverlay() {
        beatOverlayView = NSView()
        beatOverlayView.wantsLayer = true
        beatOverlayView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.55).cgColor
        beatOverlayView.layer?.cornerRadius = 8
        beatOverlayView.translatesAutoresizingMaskIntoConstraints = false
        beatOverlayView.isHidden = true

        beatOverlayLabel = NSTextField(labelWithString: "")
        beatOverlayLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 96, weight: .bold)
        beatOverlayLabel.textColor = .white
        beatOverlayLabel.alignment = .center
        beatOverlayLabel.translatesAutoresizingMaskIntoConstraints = false
        beatOverlayView.addSubview(beatOverlayLabel)

        view.addSubview(beatOverlayView)

        NSLayoutConstraint.activate([
            beatOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            beatOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            beatOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            beatOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            beatOverlayLabel.centerXAnchor.constraint(equalTo: beatOverlayView.centerXAnchor),
            beatOverlayLabel.centerYAnchor.constraint(equalTo: beatOverlayView.centerYAnchor),
        ])
    }
    
    // MARK: Update related stuff
    
    func tick() {
        self.updateTimeInUI()
        self.updateBeatCountdown()
    }

    func updateBeatCountdown() {
        guard prePlayCountdownTimer == nil else { return } // pre-play countdown owns the overlay
        // Suppress until anchor passes if we just did a pre-play countdown
        if prePlayAnchorTime > 0 {
            if PlayerAudioEngine.shared.getCurrentTime() < prePlayAnchorTime {
                DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
                return
            } else {
                prePlayAnchorTime = 0  // anchor passed, resume normal behavior
            }
        }
        guard
            let song = self.currentSong,
            song.bpm > 0,
            Settings.showBeatCountdown,
            PlayerAudioEngine.shared.isPlaying()
        else {
            DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
            return
        }

        let currentTime = PlayerAudioEngine.shared.getCurrentTime()

        // Use first named position as beat phase anchor to compensate for leading silence.
        // If no named positions exist, nothing to count down to.
        guard let anchorPosition = song.getPositions().first(where: { !$0.name.isEmpty }) else {
            DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
            return
        }
        let anchorTime = Double(anchorPosition.time) / 1000.0

        let beatDuration = 60.0 / Double(song.bpm)

        // beatOffset is negative here (we're before the anchor); floor gives e.g. -8,-7,...,-1
        // Map to 1-8: beat 1 lands on the anchor
        let beatOffset = (currentTime - anchorTime) / beatDuration

        // Deactivate only once the anchor position timestamp has passed
        guard currentTime < anchorTime else {
            DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
            return
        }

        // Only show the overlay during the last 8 beats before the anchor
        guard beatOffset >= -8 else {
            DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
            return
        }

        let beatInGroup = ((Int(floor(beatOffset)) % 8) + 8) % 8 + 1
        DispatchQueue.main.async {
            self.beatOverlayLabel.stringValue = "\(beatInGroup)"
            self.beatOverlayView.isHidden = false
        }
    }

    // MARK: Pre-play countdown

    @IBAction override func play(_ sender: AnyObject) {
        PlayerAudioEngine.shared.play()
    }

    @IBAction override func pause(_ sender: AnyObject) {
        cancelPrePlayCountdown()
        super.pause(sender)
    }

    @IBAction override func stop(_ sender: AnyObject) {
        cancelPrePlayCountdown()
        super.stop(sender)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49, prePlayCountdownTimer != nil { // Space during countdown
            cancelPrePlayCountdown()
            return
        }
        super.keyDown(with: event)
    }

    private func shouldStartPrePlayCountdown() -> Bool {
        guard let song = currentSong else { return false }
        guard song.bpm > 0 else { return false }
        guard Settings.showBeatCountdown else { return false }
        guard !PlayerAudioEngine.shared.isPlaying() else { return false }
        guard !PlayerAudioEngine.shared.isPaused() else { return false }

        guard let anchor = song.getPositions().first(where: { !$0.name.isEmpty }) else { return false }
        let anchorTime   = Double(anchor.time) / 1000.0
        let beatDuration = 60.0 / Double(song.bpm)
        let currentTime  = PlayerAudioEngine.shared.getCurrentTime()
        let beatOffset   = (currentTime - anchorTime) / beatDuration
        return beatOffset > -8 && currentTime < anchorTime
    }

    private func startPrePlayCountdown() {
        guard
            let song = currentSong,
            song.bpm > 0,
            let anchor = song.getPositions().first(where: { !$0.name.isEmpty })
        else { return }

        let anchorTime   = Double(anchor.time) / 1000.0
        let beatDuration = 60.0 / Double(song.bpm)
        let currentTime  = PlayerAudioEngine.shared.getCurrentTime()

        let leadIn = anchorTime - currentTime           // seconds of audio before anchor
        let silentBeats = max(0, 8.0 - leadIn / beatDuration)  // silent countdown beats before audio starts
        let audioStartDelay = silentBeats * beatDuration        // seconds until we fire play

        // Where to seek before playing: 8 beats before anchor, or currentTime if not enough audio
        prePlaySeekTarget = anchorTime - 8.0 * beatDuration
        prePlayAnchorTime = anchorTime
        if prePlaySeekTarget < currentTime {
            prePlaySeekTarget = currentTime
        }

        prePlayBeatNumber = 1
        DispatchQueue.main.async {
            self.beatOverlayLabel.stringValue = "1"
            self.beatOverlayView.isHidden = false
        }

        // Per-beat display timer
        prePlayCountdownTimer?.invalidate()
        prePlayCountdownTimer = Timer.scheduledTimer(withTimeInterval: beatDuration, repeats: true) { [weak self] _ in
            self?.prePlayCountdownTick()
        }

        // One-shot timer to start audio at the right moment
        prePlayAudioStartTimer?.invalidate()
        if audioStartDelay <= 0 {
            // Enough lead-in: seek and start immediately
            PlayerAudioEngine.shared.seek(seconds: prePlaySeekTarget)
        } else {
            // Need silence first: schedule audio start after delay
            prePlayAudioStartTimer = Timer.scheduledTimer(withTimeInterval: audioStartDelay, repeats: false) { [weak self] _ in
                guard let self else { return }
                PlayerAudioEngine.shared.seek(seconds: self.prePlaySeekTarget)
                PlayerAudioEngine.shared.suppressPlayRequestedNotification = true
                PlayerAudioEngine.shared.play()
            }
        }
    }

    private func prePlayCountdownTick() {
        prePlayBeatNumber += 1
        if prePlayBeatNumber > 8 {
            prePlayCountdownTimer?.invalidate()
            prePlayCountdownTimer = nil
            prePlayAudioStartTimer?.invalidate()
            prePlayAudioStartTimer = nil
            DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
            // If audio hasn't started yet (no lead-in at all), start it now
            if !PlayerAudioEngine.shared.isPlaying() {
                PlayerAudioEngine.shared.seek(seconds: prePlaySeekTarget)
                PlayerAudioEngine.shared.suppressPlayRequestedNotification = true
                PlayerAudioEngine.shared.play()
            }
        } else {
            DispatchQueue.main.async {
                self.beatOverlayLabel.stringValue = "\(self.prePlayBeatNumber)"
            }
        }
    }

    private func cancelPrePlayCountdown() {
        prePlayCountdownTimer?.invalidate()
        prePlayCountdownTimer = nil
        prePlayAudioStartTimer?.invalidate()
        prePlayAudioStartTimer = nil
        prePlayAnchorTime = 0
        DispatchQueue.main.async { self.beatOverlayView.isHidden = true }
    }
    
    func updateMeters() {
        if Settings.audioMetering {
            let meteringLevelImgHeight = Float(self.imgHeight) * (PlayerAudioEngine.shared.meteringLevel / 100)
            
            if PlayerAudioEngine.shared.isPlaying(){
                self.btnPlay.image = NSImage(shape: .play, color: .systemGreen, size: NSSize(width: self.imgWidth, height: self.imgHeight), fillHeight: Double(meteringLevelImgHeight))
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
        self.currentSong?.determineBassBPM(){ bpm in
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
