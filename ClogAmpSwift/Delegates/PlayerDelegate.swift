//
//  PlayerDelegate.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 14.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import AppKit

protocol PlayerDelegate: class {
    func loadSong(song: Song)
    func play()
    func pause()
    func stop()
}
