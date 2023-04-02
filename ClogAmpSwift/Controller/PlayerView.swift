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
    var countTimeDown: Bool = UserDefaults.standard.bool(forKey: "countTimeDown")
    
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
    @IBOutlet weak var bpmText: NSTextField!
    
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    
    
    
    
    /*
     * Properties
     */
    var observer: Any?
    
    var currentSong: Song? {
        willSet(oNewSong) {
            self.currentSong?.saveChanges()
        }
        didSet {
            self.stop()
            self.deregisterPeriodicUpdates()
            self.currentSong!.loadPositions()
            self.avPlayer = Player(song: self.currentSong!)
            self.registerPeriodicUpdate()
            let x = self.currentSong!.getValueAsString("path")
            UserDefaults.standard.set(x, forKey: "lastLoadedSongURL")
            
            //Update UI
            //Text of selected song
            let title = self.currentSong!.getValueAsString("title")
            let duration = self.currentSong!.getValueAsString("duration")
            
            self.descriptionField.stringValue = "\t\(title) (\(duration))"
            //Speed, Volume
            self.tick()
            //Time
            self.updateTime()
            
            self.mainView?.pdfView?.findPdfForSong(
                songName: self.currentSong?.getValueAsString("title") ?? "",
                fileName: self.currentSong?.filePathAsUrl.lastPathComponent ?? ""
            )
            
            if UserDefaults.standard.bool(forKey: "prefAutoDetermineBPM") && self.currentSong!.bpm == 0 {
                self.determineBpmFCS()
            }
        }
    }
    
    var avPlayer: Player?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
     * General Stuff
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let colorFilter = CIFilter(name: "CIFalseColor")!
//        colorFilter.setDefaults()
//        if #available(OSX 10.14, *) {
//            colorFilter.setValue(CIColor(cgColor: NSColor.green.cgColor), forKey: "inputColor0")
//            colorFilter.setValue(CIColor(cgColor: NSColor.controlTextColor.cgColor), forKey: "inputColor1")
//        } else {
//            // Fallback on earlier versions
//        }
//
//        self.timeSlider.contentFilters = [colorFilter]
    }
    
    /*
     * Update related stuff
     */
    func registerPeriodicUpdate() {
        self.avPlayer?.addPeriodicTimeObserver() {
            [weak self] time in
            //Do stuff
            self?.updateTime()//Double(time.value / Int64(time.timescale)))
            self?.updatePositionTable(single: false)
        }
    }
    
    func deregisterPeriodicUpdates() {
        self.avPlayer?.removeTimeObserver()
    }
    
    func tick(updateSongTab: Bool = false, updatePositionTab: Bool = true) {
        if(updatePositionTab){
            self.updatePositionTable(single: true)
        }

        self.updateRate()
        self.updateVolume()

        if(updateSongTab){
            self.updateSongTable()
        }

        if UserDefaults.standard.bool(forKey: "prefColorPlayerState") {
            if self.avPlayer?.isPlaying() ?? false {
                self.btnPlay.image  = NSImage(named: "play")
                self.btnPause.image = NSImage(named: "pauseGray")
                self.btnStop.image  = NSImage(named: "stopGray")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "play")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
            }else if (self.avPlayer?.getCurrentTime() ?? 0.0) > 0.0 && !(self.avPlayer?.isPlaying() ?? false) {
                self.btnPlay.image  = NSImage(named: "playGray")
                self.btnPause.image = NSImage(named: "pause")
                self.btnStop.image  = NSImage(named: "stopGray")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pause")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
            }else if (self.avPlayer?.getCurrentTime() ?? 0.0) == 0.0 && !(self.avPlayer?.isPlaying() ?? false) {
                self.btnPlay.image  = NSImage(named: "playGray")
                self.btnPause.image = NSImage(named: "pauseGray")
                self.btnStop.image  = NSImage(named: "stop")
                
                self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
                self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
                self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stop")
            }
        }else{
            self.btnPlay.image  = NSImage(named: "playGray")
            self.btnPause.image = NSImage(named: "pauseGray")
            self.btnStop.image  = NSImage(named: "stopGray")
            
            self.mainView?.mainWindow?.tbPlay.image  = NSImage(named: "playGray")
            self.mainView?.mainWindow?.tbPause.image = NSImage(named: "pauseGray")
            self.mainView?.mainWindow?.tbStop.image  = NSImage(named: "stopGray")
        }
    }
    
    func updateRate(){
        self.avPlayer?.updateRate()
        
        DispatchQueue.main.async {
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
        }
    }
    func updateTime(_ seconds: Double = -1) {
        DispatchQueue.main.async {
            var percent: Int = 0;
            if(self.currentSong != nil) {
                //Time Field: e.g. 3:24
                var currentTime = seconds

                if(currentTime == -1){
                    currentTime = self.avPlayer?.getCurrentTime() ?? 0
                }

                if(currentTime.isNaN){
                    currentTime = 0
                }
                
                //Position Slider
                let duration = self.currentSong?.duration ?? 0
/*                if(duration.isNaN) {
                    duration = 0
                }
*/
                if(duration > 0){
                    percent = lround(Double(currentTime / Double(duration) * 10000))
                }
                
                if(self.countTimeDown) {
                    currentTime = Double(duration) - currentTime
                }
                
                let durMinutes = Int(Float(currentTime / 60).rounded(.down))
                let durSeconds = Int(Double(currentTime).truncatingRemainder(dividingBy: 60))
                
                let sSeconds = durSeconds >= 10 ? "\(durSeconds)" : "0\(durSeconds)"
                let sMinutes = durMinutes >= 10 ? "\(durMinutes)" : "\(durMinutes)"
                
                if self.countTimeDown {
                    self.lengthField.stringValue = "- \(sMinutes):\(sSeconds)"
                }else{
                    self.lengthField.stringValue = "\t\(sMinutes):\(sSeconds)"
                }
            }
            
            self.timeSlider.integerValue = percent
        }
    }
    
    func updateVolume(){
        self.avPlayer?.updateVolume()
        
        DispatchQueue.main.async {
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
        self.currentSong?.volume = Int(sender.integerValue)
        self.updateVolume()
    }
    
    @IBAction func timeChanged(_ sender: NSSlider) {
        self.deregisterPeriodicUpdates()
        let v1 = Double(sender.integerValue) / sender.maxValue
        let duration = self.avPlayer?.getDuration() ?? 0
        let time = duration * v1
        self.avPlayer?.seek(seconds: time){
            _ in
            self.updateTime()
            self.registerPeriodicUpdate()
        }
    }
    
    @IBAction func changeTimeDisplay(_ sender: NSButton) {
        self.countTimeDown = !self.countTimeDown
        self.updateTime()
        UserDefaults.standard.set(self.countTimeDown, forKey: "countTimeDown")
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
        self.updateVolume()
    }
    
    @IBAction func decreaseVolumeButtonClicked(_ sender: AnyObject) {
        let currentVolume = self.currentSong?.volume ?? -1
        if(currentVolume > 0){
            self.currentSong?.volume = Int(currentVolume - 1)
        }
        self.updateVolume()
    }
    
    func determineBpmFCS() {
        self.currentSong?.determineBassBPM(){
            _ in
            self.currentSong?.saveChanges()
            self.mainView?.songTableView?.refreshTable()
            self.updateRate()
        }
    }

    func handlePositionSelected(_ index: Int) {
        //Check the index is in range
        if(index == -1 || self.currentSong?.positions.count ?? -1 <= index){
            return
        }
        
        if let oPosition = self.currentSong?.positions[index] {
            self.avPlayer?.seek(seconds: Float64(oPosition.time / 1000)){
                _ in
                self.tick(updateSongTab: false, updatePositionTab: false)
                
                let prefPlayPositionOnSelection = UserDefaults.standard.bool(forKey: "prefPlayPositionOnSelection")
                
                if prefPlayPositionOnSelection && !(self.avPlayer?.isPlaying() ?? false){
                    self.play()
                }
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
    @objc func songFinished() {
        self.stop()
    }
    func play() {
        if(self.avPlayer?.isPlaying() ?? false){
            //If play is called while the song is playing, it should start over
            self.avPlayer?.stop({ _ in
                self.mainView?.positionTableView?.positionTable.scrollToBeginningOfDocument(nil)
                self.avPlayer?.play()
                //Update UI
                self.tick()
            })
        }else{
            if(self.avPlayer?.getCurrentTime() == 0.0){
                self.mainView?.positionTableView?.positionTable.scrollToBeginningOfDocument(nil)
            }
            self.avPlayer?.play()
            //Update UI
            self.tick()
            
            NotificationCenter.default.addObserver(self,
               selector: #selector(songFinished),
               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
               object: nil
            ) // Add observer
        }
        
    }
    func pause() {
        if(self.avPlayer?.isPlaying() ?? false){
            self.avPlayer?.pause()
            self.tick()
        }else{
            self.play()
        }
    }
    func stop() {
        self.avPlayer?.stop({
            _ in
            self.tick()
        })
        
        NotificationCenter.default.removeObserver(self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    func jump(_ seconds: Int) {
        self.avPlayer?.jump(seconds)
        self.updateTime()
        
        self.tick(updateSongTab: false, updatePositionTab: false)
    }
    func increaseSpeed() {
        if(self.currentSong?.speed == 40){
            return
        }
        self.currentSong?.speed += 1
        self.tick(updateSongTab: true, updatePositionTab: false)
    }
    func decreaseSpeed() {
        if(self.currentSong?.speed == -40){
            return
        }
        self.currentSong?.speed -= 1
        self.tick(updateSongTab: true, updatePositionTab: false)
    }
    func resetSpeed() {
        self.currentSong?.speed = 0
        self.tick(updateSongTab: true, updatePositionTab: false)
    }
}
