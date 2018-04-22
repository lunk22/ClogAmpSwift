//
//  FileSystemUtils.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import Foundation
class FileSystemUtils {
    static func readFolderContentsAsURL(sPath: String) -> [URL] {
        let fileManager = FileManager.default
        var aFileURLs = [URL]()
        do {
            let aURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: sPath), includingPropertiesForKeys: nil, options: [])
            aFileURLs = [URL]() + aURLs.filter{ $0.pathExtension == "mp3" }//[0...10]
        } catch {
            print("Error")
        }
        
        return aFileURLs
    }
    
    static func readFolderContentsAsSong(sPath: String) -> [Song] {
        var aSongs = [Song]()
        for url in readFolderContentsAsURL(sPath: sPath) {
            aSongs.append(Song(path: url))
        }
        return aSongs
    }
}
