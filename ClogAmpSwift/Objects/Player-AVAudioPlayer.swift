////
////  Player.swift
////  ClogAmpSwift
////
////  Created by Roessel, Pascal on 11.02.19.
////  Copyright © 2019 Pascal Roessel. All rights reserved.
////
//
//import AppKit
//import AVFoundation
//
//class Player {
//    
//    var song: Song
//    var avPlayer: AVAudioPlayer?
//    var observer: Any?
//    var songHistoryWritten: Bool
//    
//    init(song: Song) {
//        self.song = song
//        AVAudioFormat
//        do {
//            self.avPlayer = try AVAudioPlayer(contentsOf: self.song.filePathAsUrl)
//            self.avPlayer?.prepareToPlay()
//            self.avPlayer?.enableRate = true
//            print(self.avPlayer?.settings)
////            let settings = [AVAudioTimePitchAlgorithm: AVAudioTimePitchAlgorithm.spectral]
////                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
////                AVSampleRateKey: 12000,
////                AVNumberOfChannelsKey: 1,
////                AVAudioTimePitchAlgorithm: AVAudioTimePitchAlgorithm.spectral
////                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
////            ]
//            
////            self.avPlayer?.format = AVAudioFormat(settings: <#T##[String : Any]#>)
//            
////            self.avPlayer?.delegate = self
////            self.avPlayer.currentItem?.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.spectral // High Quality Pitch Algorithm
//        } catch {}
//        
//        self.songHistoryWritten = false
//    }
//    
//    func play() {
//        self.avPlayer?.play()
//        self.updateRate()
//        
//        if(!self.songHistoryWritten){
//            self.songHistoryWritten = true
//            Database.insertSong(
//                intoHistory: self.song.getValueAsString("title"),
//                withArtist: self.song.getValueAsString("artist"),
//                withPath: self.song.getValueAsString("path")
//            )
//        }
//    }
//    
//    func pause() {
//        if(self.isPlaying()){
//            self.avPlayer?.pause()
//        }else{
//            self.play()
//        }
//    }
//    
//    func stop() {
//        self.avPlayer?.stop()
//        self.seek(seconds: 0.0){_ in }
//    }
//    
//    func isPlaying() -> Bool {
//        return self.avPlayer?.isPlaying ?? false
//    }
//    
//    func seek(seconds: Float64, using block: @escaping (Bool) -> Void) {
//        let timescale = CMTimeScale(1)
//        self.seek(seconds: (seconds * Double(timescale)), timescale: timescale, using: block)
//    }
//    
//    private func seek(seconds: Float64, timescale: CMTimeScale, using block: @escaping (Bool) -> Void) {
////        print("Raw: \(seconds), TimeScale: \(timescale),  Seconds: \(seconds / Double(timescale))")
//
//        self.avPlayer?.currentTime = Double(seconds / Float64(timescale))
//        
//        block(true)
////        self.avPlayer.seek(
////            to: CMTimeMake(value: Int64(lround(seconds)), timescale: timescale),
////            toleranceBefore: CMTime.zero,
////            toleranceAfter: CMTime.zero,
////            completionHandler: block
////        )
//    }
//    
//    func jump(_ seconds: Int) {
//        
//        let currentTime = self.getCurrentTime()
//        let jumpPos = currentTime + Double(seconds)
//        
//        self.seek(seconds: jumpPos * 1000, timescale: 1000){_ in }
//    }
//    
//    func updateRate(){
//        if(self.isPlaying()){
//            self.avPlayer?.rate = 1.0 + Float(Float(self.song.speed) / 100)
//        }
//    }
//    
//    func updateVolume() {
//        self.avPlayer?.volume = Float(self.song.volume) / 100
//    }
//    
//    func getCurrentTime() -> Double {
//        return self.avPlayer?.currentTime ?? 0
//    }
//    
//    func getDuration() -> Double {
//        return self.avPlayer?.duration ?? 0
//    }
//    
//    func addPeriodicTimeObserver(using block: @escaping (CMTime) -> Void) {
////        self.observer = self.avPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 100, timescale: 1000), queue: nil, using: block)
//        block(CMTime(value: 0, timescale: 1))
//    }
//    
//    func removeTimeObserver() {
////        if let observer = self.observer {
////            self.avPlayer.removeTimeObserver(observer)
////        }
////        self.observer = nil
//    }
//}
//
////extension Player: AVAudioPlayerDelegate {
////    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
////        self.stop()
////    }
////}
