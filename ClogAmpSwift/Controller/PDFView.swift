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
    
    var aPdfUrls: [URL] = []
    
    weak var mainView: MainView?
    
    @IBOutlet weak var pdfView: PDFView!
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func handleSelectPdfDirectory(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = NSLocalizedString("chooseFolder", tableName: "Main", comment: "")
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        
        if let savedPath = UserDefaults.standard.string(forKey: "pdfFolderPath") {
            dialog.directoryURL        = URL(fileURLWithPath: savedPath)
        }
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
                //Open directory
                UserDefaults.standard.set(result.path, forKey: "pdfFolderPath")
                
                //Clear existing URLs, even if it's the same folder (do a refresh)
                self.clearPdfInUi()
                self.aPdfUrls = []
                
                self.findPdfForCurrentSong()
            }
        }
    }
    
    @IBAction func handleAssignSinglePdf(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = NSLocalizedString("choosePdf", tableName: "Main", comment: "")
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
        dialog.canChooseFiles          = true
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["pdf"]
        
        if let savedPath = UserDefaults.standard.string(forKey: "pdfFolderPath") {
            dialog.directoryURL        = URL(fileURLWithPath: savedPath)
        }
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
                //Assign & open file
                Database.insert(
                    intoCuesheetAssignment: self.mainView?.playerView?.currentSong?.filePathAsUrl.lastPathComponent,
                    assignedPDFPath: result.path
                )
                
                self.openPdfInUi(result)
            }
        }
    }
    
    @IBAction func handleRemovePdfAssignment(_ sender: Any) {
        let bDeleted = Database.delete(fromCuesheetAssignment: self.mainView?.playerView?.currentSong?.filePathAsUrl.lastPathComponent)
        
        if bDeleted {
            self.clearPdfInUi()
            
            self.findPdfForCurrentSong()
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
        do {
            try ObjC.catchException {
                self.pdfView.document = nil
                DispatchQueue.main.async {
                    self.pdfView.updateLayer()
                }
            }
        }
        catch {
            print("An error ocurred: \(error)")
        }
    }
    
    func findPdfForCurrentSong() {
        self.findPdfForSong(
            songName: self.mainView?.playerView?.currentSong?.getValueAsString("title") ?? "",
            fileName: self.mainView?.playerView?.currentSong?.filePathAsUrl.lastPathComponent ?? ""
        )
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
        
        if let pdfPath = Database.getAssignedPDF(fileName) {
            self.openPdfInUi(URL(fileURLWithPath: pdfPath))
        } else if let savedPath = UserDefaults.standard.string(forKey: "pdfFolderPath") {
            DispatchQueue.global(qos: .background).async {
                if self.aPdfUrls.count == 0 {
                    self.aPdfUrls = FileSystemUtils.readFolderContentsAsURL(sPath: savedPath, filterExtension: "pdf")
                }
                if(self.aPdfUrls.count > 0) {
                    var dictResults = [Result]()
                    for url in self.aPdfUrls {
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
