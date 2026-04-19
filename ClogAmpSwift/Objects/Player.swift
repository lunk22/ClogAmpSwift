//
//  Player.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 11.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit
import AVFoundation

class Player {
    
    var song: Song
    var avPlayer: AVPlayer
    var observer: Any?
    var songHistoryWritten: Bool
    
//    var callbackClosure: @escaping (CMTime) -> Void
    var timeObserverCallback: ((CMTime) -> Void)?
    
    init(song: Song) {
        self.song = song

        self.avPlayer = AVPlayer(url: self.song.filePathAsUrl)
        self.avPlayer.automaticallyWaitsToMinimizeStalling = false
        self.avPlayer.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.spectral // High Quality Pitch Algorithm
        self.songHistoryWritten = false
    }
    
    func setRate(_ newRate: Float) {
        let oldRate = self.avPlayer.rate
        
        if(oldRate == 0.0 && newRate > 0.0) {
            // was stopped, will play
            self.addTimeObserver()
        } else if(oldRate > 0.0 && newRate == 0.0){
            // was playing, will stop
            self.removeTimeObserver()
        }
        
        self.avPlayer.rate = newRate
    }
    
    func play() {
        self.setRate(1.0)
        self.updateRate()
        
        if(!self.songHistoryWritten){
            self.songHistoryWritten = true
            Database.insertSong(
                intoHistory: self.song.getValueAsString("title"),
                withArtist: self.song.getValueAsString("artist"),
                withPath: self.song.getValueAsString("path")
            )
        }
    }
    
    func pause() {
        if(self.isPlaying()){
            self.setRate(0.0)
        }else{
            self.play()
        }
    }
    
    func stop(_ block: @escaping (Bool) -> Void) {
        self.setRate(0.0)
        self.seek(seconds: 0.0, using: block)
    }
    
    func isPlaying() -> Bool {
        return self.avPlayer.rate > 0.0
    }
    
    func seek(seconds: Float64, using block: @escaping (Bool) -> Void) {
        let timescale = self.avPlayer.currentItem?.asset.duration.timescale ?? 1000
        self.doSeek(seconds: (seconds * Double(timescale)), timescale: timescale, using: block)
    }
    
    private func doSeek(seconds: Float64, timescale: CMTimeScale, using block: @escaping (Bool) -> Void) {
        self.avPlayer.seek(
            to: CMTimeMake(value: Int64(lround(seconds)), timescale: timescale),
            toleranceBefore: CMTime.zero,
            toleranceAfter: CMTime.zero,
            completionHandler: block
        )
    }
    
    func jump(_ seconds: Int) {
        let currentTime = self.getCurrentTime()
        let jumpPos = currentTime + Double(seconds)
        
        self.doSeek(seconds: jumpPos * 1000, timescale: 1000){_ in }
    }
    
    func updateRate(){
        if(self.isPlaying()){
            self.setRate(1.0 + Float(Float(self.song.speed) / 100))
        }
    }
    
    func updateVolume() {
        self.avPlayer.volume = Float(self.song.volume) / 100
    }
    
    func getCurrentTime() -> Double {
        if let cmCurrentTime = self.avPlayer.currentItem?.currentTime() {
            let currentTime = Double(cmCurrentTime.value) / Double(cmCurrentTime.timescale)
            if(currentTime < 0){
                return 0
            }
            return currentTime
        }
        return 0.0
    }
    
    func getDuration() -> Double {
        if let cmDuration = self.avPlayer.currentItem?.duration {
            return Double(cmDuration.value) / Double(cmDuration.timescale)
        }
        return 0.0
    }
    
    @objc func songFinished() {
        self.stop({_ in})
        delayWithSeconds(0.25) {
            self.timeObserverCallback!(CMTimeMake(value: 0, timescale: 1000))
            self.removeTimeObserver()
        }
    }
    
    func addTimeObserverCallback(using block: @escaping (CMTime) -> Void) {
        self.timeObserverCallback = block
    }
    
    func addTimeObserver() {
        self.observer = self.avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 100, timescale: 1000), queue: nil, using: self.timeObserverCallback!)
        
        NotificationCenter.default.addObserver(self,
           selector: #selector(songFinished),
           name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
           object: nil
        ) // Add song finished observer
        
        print("Time Observer added")
    }
    
    func removeTimeObserver() {
        
        if let observer = self.observer {
            self.avPlayer.removeTimeObserver(observer)
        }
        self.observer = nil
        
        NotificationCenter.default.removeObserver(self)
        
        print("Time Observer removed")
        
    }
}
