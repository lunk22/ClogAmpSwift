//
//  FileSystemUtils.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 13.04.18.
//  MIT License
//

import AppKit

class FileSystemUtils {
    
    static var aSongs = [Song]()
    
    static func readFolderContentsAsURL(sPath: String, filterExtension: String = "mp3") -> [URL] {
        
        func readPathFiles(_ path: String) -> [String] {
            //paths of all files and directories
            var aPaths: [String] = []
            do {
                aPaths = try FileManager.default.subpathsOfDirectory(atPath: path)
                
                aPaths.indices.forEach {
                    let fileName = aPaths[$0]
                    let filePath = "\(path)/\(fileName)"
                    let filePathEncoded = filePath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
                    
                    aPaths[$0] = filePathEncoded
                    
                    var isDir: ObjCBool = ObjCBool(false)

                    if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) && isDir.boolValue {
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
            } catch {}
            
            return aPaths
        }
        
//        func adjustPaths(_ inArray: [String], withPath: String) -> [String] {
//            var resultArray = inArray
//            resultArray.indices.forEach {
//                let fileName = resultArray[$0]
//                let filePath = "\(withPath)/\(fileName)"
//                let filePathEncoded = filePath.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
//
//                resultArray[$0] = filePathEncoded
//            }
//
//            return resultArray
//        }
        
        var aFileURLs = [URL]()

        //paths of all files and directories
        var aPaths = readPathFiles(sPath)
                
        //filter to only use the disired file extension
        aPaths = aPaths.filter{ $0.hasSuffix(filterExtension) }
        
        //convert strings to URLs
        for sFilePath in aPaths {
//            if(filterExtension == "pdf"){
//                let fileUrl = URL(fileURLWithPath: stringPath)
//                aFileURLs.append(fileUrl)
//            }else{
                let url = URL(string: sFilePath)
                aFileURLs.append(url!)
//            }
        }
        
        return aFileURLs
    }
    
    static func readFolderContentsAsSong(sPath: String, using block: @escaping (Song, Int/* Percent */) -> Void) {
        // Create Date Formatter
        let dateFormatter = DateFormatter()

        // Set Date/Time Style
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        let aUrls = readFolderContentsAsURL(sPath: sPath)
        var count = 0
        
        // Free the buffer before redetermination
        aSongs = []
        
        logger.clear()
        
        for url in aUrls {
            let song = Song.retrieveSong(path: url)
            aSongs.append(song)
            count = count + 1
            
            print("\(dateFormatter.string(from: Date())): Complete: \((count*100)/aUrls.count)%", to: &logger)
            print("\(dateFormatter.string(from: Date())): Currently processed File: \(url.path)", to: &logger)
            
            block(song, (count*100)/aUrls.count)
            
            print("\(dateFormatter.string(from: Date())): File processed: \(url.path)", to: &logger)
            print("----------------------------------------------------", to: &logger)
        }
    }
}
