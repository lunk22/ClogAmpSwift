//
//  Log.swift
//  logtest
//  Credit to https://stackoverflow.com/a/44541541
//

import Foundation

struct Log: TextOutputStream {
    
    func clear() {
        let fm = FileManager.default
        let log = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ClogAmpSwift/songLog.txt")
        //if fm.fileExists(atPath: log.path) {
            try? fm.removeItem(atPath: log.path)
        //}
    }
    
    func write(_ string: String) {
        let fm = FileManager.default
        let log = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ClogAmpSwift/songLog.txt")
        if let stringData = string.data(using: .utf8){
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

var logger = Log()
