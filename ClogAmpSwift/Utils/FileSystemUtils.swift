//
//  FileSystemUtils.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  MIT License
//

import AppKit
import Foundation

class FileSystemUtils {
    
    static var aSongs = [Song]()
    
    static func readFolderContentsAsURL(sPath: String, filterExtension: String = "mp3") -> [URL] {
        
        func readPathFiles(_ path: String) -> [String] {
            //paths of all files and directories
            var aPaths: [String] = []
            do {
                let aPathsToBeChecked = try FileManager.default.subpathsOfDirectory(atPath: path)
                
                aPathsToBeChecked.indices.forEach {
                    let fileName = aPathsToBeChecked[$0]
                    let filePath = "\(path)/\(fileName)"
                    if let filePathEncoded = filePath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed) {
                        var isDir: ObjCBool = ObjCBool(false)

                        if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) && FileManager.default.isReadableFile(atPath: filePath) {
                            if !isDir.boolValue {
                                aPaths.append(filePathEncoded)
                            } else {
                                let symlinkTestUrl = URL(fileURLWithPath: filePath)
                                do {
                                   if try symlinkTestUrl.checkResourceIsReachable() {
                                    let resourceValues = try symlinkTestUrl.resourceValues(forKeys: [.isSymbolicLinkKey])
                                    if resourceValues.isSymbolicLink ?? false {
                                        let symLinkDestination = symlinkTestUrl.resolvingSymlinksInPath()
                                        let aRecPaths = readPathFiles(symLinkDestination.path)
                                        aPaths.append(contentsOf: aRecPaths)
                                    }
                                   }
                                } catch {}
                            }
                        }
                    }
                }
            } catch {}
            
            return aPaths
        }
        
        var aFileURLs = [URL]()

        //paths of all files and directories
        var aPaths = readPathFiles(sPath)
                
        //filter to only use the disired file extension
        aPaths = aPaths.filter{ $0.hasSuffix(filterExtension) }
        
        //convert strings to URLs
        for sFilePath in aPaths {
            if let url = URL(string: sFilePath) {
                aFileURLs.append(url)
            }
        }
        
        return aFileURLs
    }
    
    static func readFolderContentsAsSong(sPath: String, percentCallback: @escaping (Int/* Percent */) -> Void) -> Array<Song> {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date/Time Style
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        let aUrls = readFolderContentsAsURL(sPath: sPath)
        var currentIndex = 0
        
        // Free the buffer before redetermination
        aSongs = []
        
        logger.clear()
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1 // synchronous execution
        
        for url in aUrls {
            
            queue.addOperation {
                print("\(dateFormatter.string(from: Date())): Complete: \((currentIndex*100)/aUrls.count)%", to: &logger)
                print("\(dateFormatter.string(from: Date())): File processed: \(url.path)", to: &logger)
                print("----------------------------------------------------", to: &logger)
                
                let song = Song.retrieveSong(path: url)
                aSongs.append(song)
                currentIndex = currentIndex + 1

                percentCallback(currentIndex*100/aUrls.count)
            }
        }

        queue.waitUntilAllOperationsAreFinished()
        
        return aSongs
    }
}
