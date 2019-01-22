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
        /*func stringByAddingPercentEncodingForRFC3986(_ in: String) -> String? {
            let unreserved = "-._~/?"
            let allowed = NSMutableCharacterSet.alphanumeric()
            allowed.addCharacters(in: unreserved)
            return in.stringByAddingPercentEncodingWithAllowedCharacters(allowed)
        }*/
        
        let fileManager = FileManager.default
        var aFileURLs = [URL]()

        //paths of all files and directories
        var aPaths = fileManager.subpaths(atPath: sPath)
        
        //filter to only use MP3s
        aPaths = aPaths?.filter{ $0.hasSuffix("mp3") }
        
        //convert strings to URLs
        for sFilePath in aPaths! {
            let sFilePathEncoded = sFilePath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
            let url = URL(string: "\(sPath)/\(sFilePathEncoded)")
            aFileURLs.append(url!)
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
