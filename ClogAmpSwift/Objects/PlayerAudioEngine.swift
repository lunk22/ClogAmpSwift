//
//  PlayerAudioEngine.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 16.11.23.
//

import Foundation
import AppKit
import AVFoundation
import MediaPlayer

class PlayerAudioEngine {
    
    struct NotificationNames {
        static let playing = Notification.Name("PlayerAudioEngine_Playing")
        static let paused = Notification.Name("PlayerAudioEngine_Paused")
        static let stopped = Notification.Name("PlayerAudioEngine_Stopped")
        static let rateChanged = Notification.Name("PlayerAudioEngine_RateChanged")
        static let volumeChanged = Notification.Name("PlayerAudioEngine_VolumeChanged")
        static let positionChanged = Notification.Name("PlayerAudioEngine_PositionChanged")
        static let songFinished = Notification.Name("PlayerAudioEngine_SongFinished")
        static let songNotFound = Notification.Name("PlayerAudioEngine_SongUpdated")
        
        static let shutdown = Notification.Name("PlayerAudioEngine_Shutdown")
    }
    
    static let shared = PlayerAudioEngine()
    
    // MARK: Instance Vars
    var song: Song? = nil {
        willSet {
            stop()
        }
        didSet {
            songHistoryWritten = false
            readyToPlay = false
            shouldPlay = false
            
            if song == nil {
                return
            }
            
            // load the file & prepare the player to play its file from the beginning
            do {
                audioFile = try AVAudioFile(forReading: song!.filePathAsUrl)
                prepareAudioPlayer()
                setRate(song!.speed)
            } catch {
                // clear song
                song = nil
                NotificationCenter.default.post(name: NotificationNames.songNotFound, object: nil)
            }
            
            offset = AVAudioFramePosition(0)
            
            let volume = UserDefaults.standard.integer(forKey: "playerVolume")
            setVolume( volume > 0 ? volume : 100)
            
            playerLogger.clear()
            
            setMPNowPlayingInfoCenter()
        }
    }
    
    var meteringLevel: Float = 0.0
    
    private var audioFile: AVAudioFile? = nil
    private var audioEngine: AVAudioEngine
    private var audioPlayer: AVAudioPlayerNode
    private var speedControl: AVAudioUnitVarispeed
    private var pitchControl: AVAudioUnitTimePitch
    private var equalizer: AVAudioUnitEQ
    private var offset: AVAudioFramePosition = AVAudioFramePosition(0) {
        didSet {
            pausedFrame = 0
        }
    }
    private var songHistoryWritten: Bool = false
    private var timeObserverCallback: ((Any) -> Void)? = nil
    private var readyToPlay: Bool = false
    private var shouldPlay: Bool = false
    private var playing: Bool = false {
        didSet {
            if playing {
                stopped = false
                paused = false
                NotificationCenter.default.post(name: NotificationNames.playing, object: nil)
            } else {
                if !paused {
                    stopped = true
                }
            }
        }
    }
    private var paused: Bool = false {
        willSet {
            if newValue {
                pausedFrame = sampleTime
            } else {
                pausedFrame = 0
            }
        }
        didSet {
            if paused {
                stopped = false
                playing = false
                NotificationCenter.default.post(name: NotificationNames.paused, object: nil)
            } else {
                if !playing {
                    stopped = true
                }
            }
        }
    }
    private var pausedFrame: AVAudioFramePosition = AVAudioFramePosition(0)
    private var stopped: Bool = false {
        didSet {
            if stopped && oldValue != stopped {
                NotificationCenter.default.post(name: NotificationNames.stopped, object: nil)
            }
        }
    }
    private var timeObserverTimer: Timer? = nil
    
    // MARK: Calculated Vars
    private var sampleRate: Double {
        if let avAudioFile = audioFile {
            return avAudioFile.processingFormat.sampleRate
        }
        
        return 0.0
    }
    private var sampleTime: AVAudioFramePosition {
        guard
            let lastRenderTime = audioPlayer.lastRenderTime,
            let playerTime = audioPlayer.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        
        return playerTime.sampleTime
    }
    private var currentFrame: AVAudioFramePosition {
        if isPaused() {
            return pausedFrame + offset
        }
        
        return sampleTime + offset
    }
    private var remainingFrames: Int64 {
        return (audioFile?.length ?? 0) - (sampleTime + offset)
    }
    
    private var eqFrequencyMultiplier: Float = 1.0
    private let eqExponentForNegativeDb: Float = 1//.43
    
    // MARK: Functions
    private init() {
        // 1: create the AVAudio stuff
        audioEngine = AVAudioEngine()
        speedControl = AVAudioUnitVarispeed()
        pitchControl = AVAudioUnitTimePitch()
        audioPlayer = AVAudioPlayerNode()
        equalizer = AVAudioUnitEQ()
        
        // 2: connect the components to our playback engine
        audioEngine.attach(audioPlayer)
        audioEngine.attach(pitchControl)
        audioEngine.attach(speedControl)
        audioEngine.attach(equalizer)
        
        // 3: arrange the parts so that output from one is input to another
        audioEngine.connect(audioPlayer, to: speedControl, format: nil)
        audioEngine.connect(speedControl, to: pitchControl, format: nil)
        audioEngine.connect(pitchControl, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: audioEngine.mainMixerNode, format: nil)
        
        let freqs = [
            Settings.eqFrequencyLowHz,
            Settings.eqFrequencyMidHz,
            Settings.eqFrequencyHighHz
        ]
        
        for i in 0...(freqs.count - 1) {
            equalizer.bands[i].frequency  = Float(freqs[i])
            equalizer.bands[i].bypass     = false
            equalizer.bands[i].filterType = .parametric
        }
        
        setFrequencyDbHigh(newTargetDb: Settings.eqFrequencyHigh)
        setFrequencyDbMid(newTargetDb: Settings.eqFrequencyMid)
        setFrequencyDbLow(newTargetDb: Settings.eqFrequencyLow)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(shutdown),
                                               name: NotificationNames.shutdown,
                                               object: nil
        ) // Add shutdown observer
        
        // Media Center
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("MP Remote Command: Play/Pause")
            self.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("MP Remote Command: Play")
            self.play()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("MP Remote Command: Pause")
            if self.isPlaying(){
                self.pause()
            }
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [Settings.skipForward as NSNumber] // Prevents the UI from showing a number
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("MP Remote Command: Skip Forward")
            self.jump(Settings.skipForward)
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [Settings.skipBack as NSNumber] // Prevents the UI from showing a number
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            print("MP Remote Command: Skip Back")
            self.jump((Settings.skipBack * -1))
            return .success
        }
        
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let castEvent = event as? MPChangePlaybackPositionCommandEvent {
                self.seek(seconds: castEvent.positionTime)
            }
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
//        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.jump(Settings.skipForward)
//            return .success
//        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
//        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            self.jump((Settings.skipBack * -1))
//            return .success
//        }
        
        // .playing enables the media keys initially. Set it to .stopped immediately after to reflect it properly in the command center UI
        MPNowPlayingInfoCenter.default().playbackState = .playing
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
    
    private func prepareAudioPlayer() {
        // Reset gain
        equalizer.globalGain = 0
        
        audioEngine.disconnectNodeInput(audioPlayer)
        audioEngine.detach(audioPlayer)
        
        audioPlayer = AVAudioPlayerNode()
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: speedControl, format: nil)
        
        audioPlayer.scheduleFile(audioFile!, at: nil)
        
        if Settings.normalizeAudioLevels {
            print("Audio normalization started for file: \(audioFile!.url)", to: &normalizationLogger)
            averagePowers(audioFileURL: audioFile!.url, forChannel: 0, completionHandler: { powers, success  in
                if success {
                    let maxValue = powers.max() ?? 0.0
                    // Calc with -10 to not deviate too far from system volume. Calculate with base of 0 will increase the gain too much
                    let adjustedGain = Settings.normalizeAudioBoost ? -5 - maxValue : -10 - maxValue
                    self.equalizer.globalGain = adjustedGain
                    print("Audio normalization completed. Gain adjustment: \(adjustedGain) - Boost active: \(Settings.normalizeAudioBoost)", to: &normalizationLogger)
                    print("----------------------------------------------------", to: &normalizationLogger)
                } else {
                    print("Failed to perform audio normalization.", to: &normalizationLogger)
                    print("----------------------------------------------------", to: &normalizationLogger)
                }
                // No matter if it was successful, the file should still be playable
                self.readyToPlay = true
                
                if self.shouldPlay {
                    self.play()
                }
            })
        } else {
            readyToPlay = true
            
            if self.shouldPlay {
                self.play()
            }
        }
    }
    
    // MARK: Player Settings
    func adjustFrequencyDb(_ newTargetDb: Float) -> Float {
        var targetDb: Float = newTargetDb
        if targetDb < 0.0 {
            targetDb = pow(targetDb * -1, eqExponentForNegativeDb) * -1
        }
        
        return targetDb
    }
    
    // Metering
    func averagePowers(audioFileURL: URL, forChannel channelNumber: Int, completionHandler: @escaping(_ powers: [Float], _ success: Bool) -> ()) {
        // Credits go to https://stackoverflow.com/a/52280271
        // This is only slightly modified to handle errors
        let audioFile = try? AVAudioFile(forReading: audioFileURL)
        guard let audioFile = audioFile else {
            completionHandler([0], false)
            return
        }
        let audioFilePFormat = audioFile.processingFormat
        let audioFileLength = audioFile.length
        
        //Set the size of frames to read from the audio file, you can adjust this to your liking
        let frameSizeToRead = Int(audioFilePFormat.sampleRate/20)
        
        //This is to how many frames/portions we're going to divide the audio file
        let numberOfFrames = Int(audioFileLength)/frameSizeToRead
        
        //Create a pcm buffer the size of a frame
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFilePFormat, frameCapacity: AVAudioFrameCount(frameSizeToRead)) else {
            completionHandler([0], false)
            return
        }
        
        //Do the calculations in a background thread, if you don't want to block the main thread for larger audio files
        DispatchQueue.global(qos: .userInitiated).async {
            
            //This is the array to be returned
            var returnArray : [Float] = [Float]()
            
            //We're going to read the audio file, frame by frame
            for i in 0..<numberOfFrames {
                
                //Change the position from which we are reading the audio file, since each frame starts from a different position in the audio file
                audioFile.framePosition = AVAudioFramePosition(i * frameSizeToRead)
                
                //Read the frame from the audio file
                do {
                    try audioFile.read(into: audioBuffer, frameCount: AVAudioFrameCount(frameSizeToRead))
                } catch {
                    completionHandler([0], false)
                    return
                }
                
                //Get the data from the chosen channel
                let channelData = audioBuffer.floatChannelData![channelNumber]
                
                //This is the array of floats
                let arr = Array(UnsafeBufferPointer(start:channelData, count: frameSizeToRead))
                
                //Calculate the mean value of the absolute values
                let meanValue = arr.reduce(0, {$0 + abs($1)})/Float(arr.count)
                
                //Calculate the dB power (You can adjust this), if average is less than 0.000_000_01 we limit it to -160.0
                let dbPower: Float = meanValue > 0.000_000_01 ? (20 * log10(meanValue)) : -160.0
                
                //append the db power in the current frame to the returnArray
                returnArray.append(dbPower)
            }
            
            //Return the dBPowers
            completionHandler(returnArray, true)
        }
    }

    func convertPower(power: Float) -> Float {
        guard power.isFinite else { return 0.0 }
        let minDb: Float = -80.0
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    func installMeteringTap() {
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        
        audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _  in
            if Settings.audioMetering {
                guard let channelData = buffer.floatChannelData else {
                    return
                }
                
                let channelDataValue = channelData.pointee
                let channelDataValueArray = stride(
                    from: 0,
                    to: Int(buffer.frameLength),
                    by: buffer.stride
                ).map { channelDataValue[$0] }
                
                let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
                
                let avgPower = 20 * log10(rms)
                
                self.meteringLevel = self.convertPower(power: avgPower) * 100
            }
        }
    }
    
    func removeMeteringTap() {
        audioEngine.mainMixerNode.removeTap(onBus: 0)
        self.meteringLevel = 0.0
    }
    
    func setFrequencyDbLow(newTargetDb: Float) {
        equalizer.bands[0].gain = adjustFrequencyDb(newTargetDb)
    }
    
    func setFrequencyDbMid(newTargetDb: Float) {
        equalizer.bands[1].gain = adjustFrequencyDb(newTargetDb)
    }
    
    func setFrequencyDbHigh(newTargetDb: Float) {
        equalizer.bands[2].gain = adjustFrequencyDb(newTargetDb)
    }
    
    func setRate(_ offset: Int) {
        song?.speed = offset
        let newRate = 1.0 + Float(offset) / 100
        pitchControl.rate = newRate
        
        //        // Calculate Pitch
        //        if let song = song {
        //            song.pitch = lround(log2(Double(speedControl.rate)) * 1200.0) * -1
        //            updatePitch()
        //        }
        
        NotificationCenter.default.post(name: NotificationNames.rateChanged, object: nil)
    }
    
    func setVolume(_ volume: Int) { // in %
        UserDefaults.standard.set(volume, forKey: "playerVolume")
        self.audioEngine.mainMixerNode.outputVolume = Float(volume) / 100
        NotificationCenter.default.post(name: NotificationNames.volumeChanged, object: nil)
    }
    
    func getVolume() -> Int {
        return lroundf(self.audioEngine.mainMixerNode.outputVolume * 100)
    }
    
    // MARK: Controlling the Player
    func play() {
        if !readyToPlay {
            shouldPlay = true
            return
        }
        shouldPlay = false
        if isPlaying() { self.seek(seconds: 0.0); return }
        if let song = song {
            
            // Highest Prio for song playback
            DispatchQueue.main.async(qos: .userInteractive) {
                do {
                    
                    try self.audioEngine.start()
                    self.audioPlayer.play()

//                    print("File: \(self.song?.title ?? "") | Gain: \(self.equalizer.globalGain)")
                    
                    self.playing = true
                    MPNowPlayingInfoCenter.default().playbackState = .playing
                    
                    self.startTimeObserver()
                    
                    self.installMeteringTap()
                    
                    if(!self.songHistoryWritten){
                        self.songHistoryWritten = true
                        Database.insertSong(
                            intoHistory: song.getValueAsString("title"),
                            withArtist: song.getValueAsString("artist"),
                            withPath: song.getValueAsString("path")
                        )
                    }
                } catch {
                    /* Handle the error. */
                }
            }
        }
    }
    
    func pause() {
        if(isPlaying()){
            // Set it first so it can remember the currentFrame as pauseFrame
            paused = true
            MPNowPlayingInfoCenter.default().playbackState = .paused
            
            audioPlayer.pause()
            audioEngine.pause()
            
            removeMeteringTap()
            endTimeObserver()
            executeTimeObserverCallback()
        }else{
            play()
        }
    }
    
    func stop() {
        audioPlayer.stop()
        audioEngine.stop()
        removeMeteringTap()
        endTimeObserver()
        playing = false
        paused = false
        offset = AVAudioFramePosition(0)
        doSeek(offset)
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        executeTimeObserverCallback()
    }
    
    // seek = absolute time
    func seek(seconds: Double) {
        // Absolute => override offset
        let newOffset = AVAudioFramePosition(llround(Double(seconds) * sampleRate))
        if newOffset >= 0{
            offset = newOffset
        } else {
            offset = 0
        }
        
        doSeek(offset)
    }
    
    // jump = relative time
    func jump(_ seconds: Int) {
        // Relative => Calculate offset
        let newOffset = AVAudioFramePosition(currentFrame + llround(Double(seconds) * sampleRate))
        if newOffset >= 0{
            offset = newOffset
        } else {
            offset = 0
        }
        doSeek(offset)
    }
    
    // MARK: Player State
    func isPlaying() -> Bool {
        return playing
    }
    
    func isPaused() -> Bool {
        return paused
    }
    
    func isStopped() -> Bool {
        return !isPlaying() && !isPaused()
    }
    
    // MARK: Time Info
    func getCurrentTime(rounded: Bool = false) -> Double { // time in seconds
        var sampleTime = max(currentFrame, offset)
        sampleTime = min(sampleTime, audioFile?.length ?? 0)
        sampleTime = max(sampleTime, 0)
        let calculatedCurrentTime = (Double(sampleTime) / sampleRate)
        return rounded ? calculatedCurrentTime.rounded(.down) : calculatedCurrentTime
    }
    
    func getDuration() -> Double { // time in seconds
        let fileSampleRate = Double(audioFile?.processingFormat.sampleRate ?? 0)
        let fileFrameCount = Double(audioFile?.length ?? 0)
        return fileFrameCount / fileSampleRate
    }
    
    // MARK: Event Handler
    @objc private func songFinished() {
        stop()
    }
    
    @objc private func shutdown() {
        stop()
    }
    
    // MARK: Time Observer
    func setTimeObserverCallback(using block: @escaping (Any) -> Void) {
        timeObserverCallback = block
    }
    
    private func executeTimeObserverCallback() {
        printTimes()
        timeObserverCallback?(0)
        setMPNowPlayingInfoCenter()
    }
    
    private func startTimeObserver() {
        endTimeObserver() // cancel old one, if available
        
        self.timeObserverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true){ _ in
            self.executeTimeObserverCallback()
            
            if (self.remainingFrames <= 0) && !self.isStopped() {
                print("Timer: song finished - \(self.remainingFrames)")
                self.stop()
                NotificationCenter.default.post(name: NotificationNames.songFinished, object: nil)
            }
        }
        
    }
    
    private func endTimeObserver() {
        if let timeObserverTimer = self.timeObserverTimer {
            DispatchQueue.main.async {
                timeObserverTimer.invalidate()
            }
            self.timeObserverTimer = nil
        }
    }
    
    // MARK: Helper Function
    private func doSeek(_ newFrame: AVAudioFramePosition) {
        let wasPlaying = isPlaying()
        
        // Safe current volume
        let originalVolume = self.audioPlayer.volume
        self.audioPlayer.volume = 0.0
        
        var newFramePosition = max(newFrame, 0)
        newFramePosition = min(newFramePosition, audioFile?.length ?? 0)
        
        audioPlayer.stop()
        
        if(newFramePosition < audioFile?.length ?? 0) {
            let remainingFrames = AVAudioFrameCount(audioFile!.length - newFramePosition)
            audioPlayer.scheduleSegment(audioFile!, startingFrame: newFramePosition, frameCount: remainingFrames, at: nil)
            
            // Restore volume
            self.audioPlayer.volume = originalVolume
            
            if(wasPlaying){
                audioPlayer.play()
                startTimeObserver()
            } else if newFramePosition > 0 {
                self.paused = true
                executeTimeObserverCallback()
            }
            
        } else {
            // Nothing done, just restore volume
            self.audioPlayer.volume = originalVolume
        }
    }
    
    private func printTimes() {
        //        print("Sample Frame: \(sampleTime) | Paused Frame: \(pausedFrame) | Offset: \(offset) |  => Current Frame: \(currentFrame)")
    }
    
    private func setMPNowPlayingInfoCenter() {
        if let song = self.song {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: song.getValueAsString("title"),
                MPMediaItemPropertyArtist: song.getValueAsString("artist"),
                MPMediaItemPropertyPlaybackDuration: Double(song.duration),
                MPNowPlayingInfoPropertyPlaybackRate: pitchControl.rate,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: getCurrentTime(rounded: true)
            ]
        }
    }
}
