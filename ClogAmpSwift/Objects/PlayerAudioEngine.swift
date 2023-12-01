//
//  PlayerAudioEngine.swift
//  ClogAmpSwift
//
//  Created by Freundlich, Pascal on 16.11.23.
//  Copyright © 2023 Pascal Freundlich. All rights reserved.
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
            
            // load the file & prepare the player to play its file from the beginning
            audioFile = try! AVAudioFile(forReading: song!.filePathAsUrl)
            prepareAudioPlayer()
            
            offset = AVAudioFramePosition(0)
            
            setRate(song!.speed)
            setVolume(song!.volume)
            
            playerLogger.clear()
            
            setMPNowPlayingInfoCenter()
        }
    }
    
    private var audioFile: AVAudioFile? = nil
    private var audioEngine: AVAudioEngine
    private var audioPlayer: AVAudioPlayerNode
    private var speedControl: AVAudioUnitVarispeed
    private var pitchControl: AVAudioUnitTimePitch
    private var offset: AVAudioFramePosition = AVAudioFramePosition(0) {
        didSet {
            pausedFrame = 0
        }
    }
    private var songHistoryWritten: Bool = false
    private var timeObserverCallback: ((Any) -> Void)? = nil
    private var cancelTimeObserver: Bool = false
    private var playing: Bool = false {
        didSet {
            if playing {
                paused = false
                cancelTimeObserver = false
                NotificationCenter.default.post(name: NotificationNames.playing, object: nil)
            } else {
                if !paused {
                    NotificationCenter.default.post(name: NotificationNames.stopped, object: nil)
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
                playing = false
                NotificationCenter.default.post(name: NotificationNames.paused, object: nil)
            } else {
                if !playing {
                    NotificationCenter.default.post(name: NotificationNames.stopped, object: nil)
                }
            }
        }
    }
    private var pausedFrame: AVAudioFramePosition = AVAudioFramePosition(0)

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
    private var currentFrameAsDouble: Double {
        return Double(currentFrame)
    }
    private var remainingFrames: Int64 {
        return (audioFile?.length ?? 0) - currentFrame
    }
    
    // MARK: Functions
    private init() {
        // 1: create the AVAudio stuff
        audioEngine = AVAudioEngine()
        speedControl = AVAudioUnitVarispeed()
        pitchControl = AVAudioUnitTimePitch()
        audioPlayer = AVAudioPlayerNode()

        // 2: connect the components to our playback engine
        audioEngine.attach(audioPlayer)
        audioEngine.attach(pitchControl)
        audioEngine.attach(speedControl)

        // 3: arrange the parts so that output from one is input to another
        audioEngine.connect(audioPlayer, to: speedControl, format: nil)
        audioEngine.connect(speedControl, to: pitchControl, format: nil)
        audioEngine.connect(pitchControl, to: audioEngine.mainMixerNode, format: nil)

        NotificationCenter.default.addObserver(self,
           selector: #selector(shutdown),
           name: NotificationNames.shutdown,
           object: nil
        ) // Add shutdown observer
        
        // Media Center
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.play()
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.pause()
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [Defaults.skipForward as NSNumber]
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.jump(Defaults.skipForward)
            return .success
        }
        
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [Defaults.skipBack as NSNumber]
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.jump((Defaults.skipBack * -1))
            return .success
        }

        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            if let castEvent = event as? MPChangePlaybackPositionCommandEvent {
                self.seek(seconds: castEvent.positionTime)
            }
            return .success
        }

        // .playing enables the media keys initially. Set it to .stopped immediately after to reflect it properly in the command center UI
        MPNowPlayingInfoCenter.default().playbackState = .playing
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
    
    private func prepareAudioPlayer() {
        audioEngine.disconnectNodeInput(audioPlayer)
        audioEngine.detach(audioPlayer)
        
        audioPlayer = AVAudioPlayerNode()
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: speedControl, format: nil)
        
        audioPlayer.scheduleFile(audioFile!, at: nil)
    }
        
    // MARK: Player Settings
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
        song?.volume = volume
        self.audioEngine.mainMixerNode.outputVolume = Float(volume) / 100
        NotificationCenter.default.post(name: NotificationNames.volumeChanged, object: nil)
    }
    
    // MARK: Controlling the Player
    func play() {
        if isPlaying() { self.seek(seconds: 0.0); return }
        if let song = song {
            
            // Highest Prio for song playback
            DispatchQueue.main.async(qos: .userInteractive) {
                do {
                    
                    try self.audioEngine.start()
                    self.audioPlayer.play()

                    self.playing = true
                    MPNowPlayingInfoCenter.default().playbackState = .playing
                    
                    self.startTimeObserver()
                    
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
        }else{
            play()
        }
    }
    
    func stop() {
        playing = false
        paused = false
        endTimeObserver()
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        audioPlayer.stop()
        audioEngine.stop()
        offset = AVAudioFramePosition(0)
        doSeek(currentFrame)
    }
    
    // seek = absolute time
    func seek(seconds: Double) {
        // Absolute => override offset
        offset = AVAudioFramePosition(llround(Double(seconds) * sampleRate))
        doSeek(offset)
    }
    
    // jump = relative time
    func jump(_ seconds: Int) {
        // Relative => Calculate offset
        offset = AVAudioFramePosition(currentFrame + llround(Double(seconds) * sampleRate))
        doSeek(currentFrame)
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
        var sampleTime = min(currentFrame, audioFile?.length ?? 0)
        sampleTime = max(sampleTime, 0)
        let calculatedCurrentTime = (Double(sampleTime) / sampleRate)
        return rounded ? calculatedCurrentTime.rounded() : calculatedCurrentTime
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
        timeObserverCallback!(0)
        setMPNowPlayingInfoCenter()
    }
    
    private func startTimeObserver() {
        func execute() {
            executeTimeObserverCallback()

            if cancelTimeObserver {
                cancelTimeObserver = false
                return
            }
            if isPlaying() && remainingFrames > 0 {
                delayWithSeconds(0.05) {
                    execute()
                }
            } else if !isPaused() {
                stop()
                NotificationCenter.default.post(name: NotificationNames.songFinished, object: nil)
            }
        }
        
        execute()
    }
    
    private func endTimeObserver() {
        cancelTimeObserver = true
    }
    
    // MARK: Helper Function
    private func doSeek(_ newFrame: AVAudioFramePosition) {
        let wasPlaying = isPlaying()
        
        var newFramePosition = max(newFrame, 0)
        newFramePosition = min(newFramePosition, audioFile?.length ?? 0)
        
        audioPlayer.stop()
        
        if(newFramePosition < audioFile?.length ?? 0) {
            let remainingFrames = AVAudioFrameCount(audioFile!.length - newFramePosition)
            audioPlayer.scheduleSegment(audioFile!, startingFrame: newFramePosition, frameCount: remainingFrames, at: nil)
            executeTimeObserverCallback()
            
            if(wasPlaying){
                audioPlayer.play()
            }
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
