//
//  PDFView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 04.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation
import PDFKit

class PDFViewController: NSViewController {

    @IBOutlet weak var pdfView: PDFView!
    
    override func viewDidAppear() {
        super.viewDidLoad()
    }
    
    @IBAction func handleSelectPdfDirectory(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canChooseFiles          = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        
        if let savedPath = UserDefaults.standard.string(forKey: "pdfFolderPath") {
            dialog.directoryURL        = URL(fileURLWithPath: savedPath)
        }
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
                //Open directory
//                self.setPdfDirectory(result.path)
                UserDefaults.standard.set(result.path, forKey: "pdfFolderPath")
            }
        }
    }
    
    func openPdfInUi(_ url: URL) {
        DispatchQueue.main.async {
            let fileUrl = URL(fileURLWithPath: url.path)
            if let pdfDocument = PDFDocument(url: fileUrl) {
                self.pdfView.displayMode = .singlePageContinuous
                self.pdfView.autoScales = true
                self.pdfView.document = pdfDocument
                guard let firstPage = self.pdfView.document?.page(at: 0) else { return }
                self.pdfView.go(to: CGRect(x: 0, y: Int.max, width: 0, height: 0), on: firstPage)
            }
        }
    }
    
    func clearPdfInUi() {
        self.pdfView.document = nil
    }
    
    func findPdfForSong(songName: String, fileName: String) {
        class Result {
            var counter: Int
            var url: URL
            var score: Double
            
            init(counter: Int, url: URL, score: Double) {
                self.counter = counter
                self.url = url
                self.score = score
            }
        }
        if let savedPath = UserDefaults.standard.string(forKey: "pdfFolderPath") {
            DispatchQueue.global(qos: .background).async {
                let aUrls = FileSystemUtils.readFolderContentsAsURL(sPath: savedPath, filterExtension: "pdf")
                if(aUrls.count > 0) {
                    var dictResults = [Result]()
                    for url in aUrls {
                        let lastPathComponent = url.deletingPathExtension().lastPathComponent
                        
                        if fileName.replacingOccurrences(of: ".mp3", with: "") == lastPathComponent {
                            //That's the perfect match! Do something!
                            self.openPdfInUi(url)
                            return
                        }
                        
                        //Score for the song name (ID3)
                        var score = songName.score(word: lastPathComponent)
                        dictResults.append(Result(counter: dictResults.count + 1, url: url, score: score))
                        //Score for the file name
                        score = fileName.replacingOccurrences(of: ".mp3", with: "").score(word: lastPathComponent)
                        dictResults.append(Result(counter: dictResults.count + 1, url: url, score: score))
                    }
                    
                    let sortedResults = dictResults.sorted(by: { (a, b) -> Bool in
                        return a.score > b.score
                    })
                    
                    if(sortedResults[0].score > 0.0) {
                        self.openPdfInUi(sortedResults[0].url)
                    }else{
                        self.clearPdfInUi()
                    }
                }
            }
        }
    }
    
}
