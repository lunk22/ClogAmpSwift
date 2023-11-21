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
            
            playerLogger.clear()
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: song!.getValueAsString("title"),
                MPMediaItemPropertyArtist: song!.getValueAsString("artist"),
//                MPMediaItemProperty
            ]
        }
    }
    
    var audioFile: AVAudioFile? = nil
    var audioEngine: AVAudioEngine
    var audioPlayer: AVAudioPlayerNode
    var speedControl: AVAudioUnitVarispeed
    var pitchControl: AVAudioUnitTimePitch
    
    var offset: AVAudioFramePosition = AVAudioFramePosition(0) {
        didSet {
            pausedFrame = 0
        }
    }

    var songHistoryWritten: Bool = false
    var timeObserverCallback: ((Any) -> Void)? = nil
    var cancelTimeObserver: Bool = false
    
    var playing: Bool = false {
        didSet {
            if playing {
                paused = false
            }
        }
    }
    
    var paused: Bool = false {
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
            }
        }
    }
    
    var pausedFrame: AVAudioFramePosition = AVAudioFramePosition(0)
    
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
    
    init() {
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
        audioEngine.mainMixerNode.volume = 0

        NotificationCenter.default.addObserver(self,
           selector: #selector(shutdown),
           name: Notification.Name("CAM_Shutdown"),
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
        
        // .playing enables the media keys initially. Set it to .stopped immediately after to reflect it properly in the command center UI
        MPNowPlayingInfoCenter.default().playbackState = .playing
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
    
    deinit {
        removeTimeObserver()
    }
    
    func prepareAudioPlayer() {
        audioEngine.disconnectNodeInput(audioPlayer)
        audioEngine.detach(audioPlayer)
        
        audioPlayer = AVAudioPlayerNode()
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: speedControl, format: nil)
        
        audioPlayer.scheduleFile(audioFile!, at: nil)
    }
        
    func setRate(_ offset: Int) {
        let newRate = 1.0 + Float(offset) / 100
        pitchControl.rate = newRate
        
//        // Calculate Pitch
//        if let song = song {
//            song.pitch = lround(log2(Double(speedControl.rate)) * 1200.0) * -1
//            updatePitch()
//        }
    }
    
    // MARK: Controlling the Player
    func play() {
        if isPlaying() { return }
        if let song = song {
            do {
                try audioEngine.start()
                audioPlayer.play()
                
                playing = true
                MPNowPlayingInfoCenter.default().playbackState = .playing
//                MPRemoteCommandEvent.
                
                addTimeObserver()
                
                if(!songHistoryWritten){
                    songHistoryWritten = true
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
    func getCurrentTime() -> Double { // time in seconds
        var sampleTime = min(currentFrame, audioFile?.length ?? 0)
        sampleTime = max(sampleTime, 0)
        return Double(sampleTime) / sampleRate
    }
    
    func getDuration() -> Double { // time in seconds
        let fileSampleRate = Double(audioFile?.processingFormat.sampleRate ?? 0)
        let fileFrameCount = Double(audioFile?.length ?? 0)
        return fileFrameCount / fileSampleRate
    }
    
    // MARK: Event Handler
    @objc func songFinished() {
        stop()
    }
    
    @objc func shutdown() {
        stop()
    }
    
    // MARK: Time Observer
    func addTimeObserverCallback(using block: @escaping (Any) -> Void) {
        timeObserverCallback = block
    }
    
    func executeTimeObserverCallback() {
        printTimes()
        timeObserverCallback!(0)
    }
    
    func addTimeObserver() {
        func execute() {
            if cancelTimeObserver {
                cancelTimeObserver = false
                return
            }
            if isPlaying() && remainingFrames > 0 {
                delayWithSeconds(0.1) {
                    execute()
                }
            } else if !isPaused() {
                stop()
                
                NotificationCenter.default.post(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            }
            
            executeTimeObserverCallback()
            
        }
        
        execute()
    }
    
    func removeTimeObserver() {
        cancelTimeObserver = true
    }
    
    // MARK: Helper Function
    func doSeek(_ newFrame: AVAudioFramePosition) {
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
    
    func updateRate(){
        if let song = song {
            setRate(song.speed)
        }
    }
    
    func updateVolume() {
        //        avPlayer.volume = Float(song.volume) / 100
    }
    
    func printTimes() {
        print("Sample Frame: \(sampleTime) | Paused Frame: \(pausedFrame) | Offset: \(offset) |  => Current Frame: \(currentFrame)")
    }
}
