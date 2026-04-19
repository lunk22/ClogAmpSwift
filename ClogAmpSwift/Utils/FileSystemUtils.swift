//
//  FileSystemUtils.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  MIT License
//

import AppKit

class FileSystemUtils {
    static func readFolderContentsAsURL(sPath: String) -> [URL] {
        let sPathEncoded = sPath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
        
        let fileManager = FileManager.default
        var aFileURLs = [URL]()

        //paths of all files and directories
        var aPaths = fileManager.subpaths(atPath: sPath)
        
        //filter to only use MP3s
        aPaths = aPaths?.filter{ $0.hasSuffix("mp3") }
        
        //convert strings to URLs
        for sFilePath in aPaths! {
            let sFilePathEncoded = sFilePath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
            let url = URL(string: "\(sPathEncoded)/\(sFilePathEncoded)")
            aFileURLs.append(url!)
        }
        
        return aFileURLs
    }
    
    static func readFolderContentsAsSong(sPath: String, oView: ViewController, using block: @escaping (Song, Int/* Percent */) -> Void) {
        let aUrls = readFolderContentsAsURL(sPath: sPath)
        var count = 0

        for url in aUrls {
            let song = Song.retrieveSong(path: url)
            count = count + 1
            
            //Load the positions for the first 9 songs to make sure the framework works alright
            if count < 10 {
                song.loadPositions()
            }
            
            block(song, (count*100)/aUrls.count)
        }
    }
}
