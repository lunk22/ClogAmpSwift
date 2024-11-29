//
//  PlayerLog.swift
//  ClogAmpSwift
//
//  Created by Pascal Freundlich on 12.07.23.
//  Credit to https://stackoverflow.com/a/44541541
//

import Foundation

struct PlayerLog: TextOutputStream {
    
    func clear() {
        let fm = FileManager.default
        let log = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ClogAmpSwift/playerLog.txt")
        
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: log.path) {
            if let bytes = fileAttributes[.size] as? Int64 {
                // Keep log until it exceeds 1MB
                if bytes > 500000 {
                    try? fm.removeItem(atPath: log.path)
                } // if bytes > 1000000 {
            } // if let bytes = fileAttributes[.size] as? Int64 {
        } // if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: log.path) {
    } // func clear() {
    
    func write(_ string: String) {
        // Guard clause - no string => no log
        if string == "" {return}
        
        let fm = FileManager.default
        let log = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ClogAmpSwift/playerLog.txt")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd, HH:mm:ss.SSS"
        let dateString = dateFormatter.string(from: Date())
        
        // Append new line without timestamp
        let logString = string == "\n" ? string : "\(dateString) - \(string)"

        if let stringData = logString.data(using: .utf8){
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(stringData)
                handle.closeFile()
            } else {
                try? stringData.write(to: log)
            }
        }
    }
}

var playerLogger = PlayerLog()
