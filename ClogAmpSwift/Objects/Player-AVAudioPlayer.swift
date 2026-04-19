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
//class Player: NSObject {
//
//    var song: Song
//    var avPlayer: AVAudioPlayer?
//    var observer: Any?
//    var songHistoryWritten: Bool
//    var theClosure: (() -> Void)?
//    var timer: Timer?
//
//    init(song: Song) {
//        self.song = song
//        self.songHistoryWritten = false
//
//        super.init()
//
//        do {
//            self.avPlayer = try AVAudioPlayer(contentsOf: self.song.filePathAsUrl) //, format: AVAudioFormat(settings: settings)
//            self.avPlayer?.prepareToPlay()
//            self.avPlayer?.enableRate = true
//            self.avPlayer?.isMeteringEnabled = true
//            self.avPlayer?.delegate = self
//
//        } catch {}
//    }
//
//    func play() {
//        if self.theClosure != nil {
//            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true){_ in
//                self.theClosure!()
//                print(self.getCurrentPower())
//            }
//        }
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
//            if self.timer != nil {
//                self.timer!.invalidate()
//            }
//
//            self.avPlayer?.pause()
//        }else{
//            self.play()
//        }
//    }
//
//    func stop() {
//        self.avPlayer?.stop()
//        self.seek(seconds: 0.0){_ in }
//        if self.timer != nil {
//            self.timer!.invalidate()
//        }
//        if self.theClosure != nil {
//            self.theClosure!()
//        }
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
//    func getCurrentPower() -> Float {
//        self.avPlayer?.updateMeters()
//        var averagePowerAcc: Float = 0.0
//        for i in 0...(self.avPlayer?.numberOfChannels ?? 0)-1 {
//            averagePowerAcc += self.avPlayer?.averagePower(forChannel: i) ?? 0
//        }
//
//        return averagePowerAcc / Float(self.avPlayer?.numberOfChannels ?? 1)
//    }
//
//    @objc func songFinished() {
//        self.stop()
//        self.theClosure!()
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    func addPeriodicTimeObserver(using block: @escaping () -> Void) {
//        self.theClosure = block
//
//        NotificationCenter.default.addObserver(self,
//           selector: #selector(songFinished),
//           name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
//           object: nil
//        ) // Add observer
//    }
//
//    func removeTimeObserver() {
//        self.theClosure = nil
//        if self.timer != nil {
//            self.timer!.invalidate()
//            self.timer = nil
//        }
//    }
//
//}
//
//extension Player: AVAudioPlayerDelegate {
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        self.songFinished()
//    }
//}
