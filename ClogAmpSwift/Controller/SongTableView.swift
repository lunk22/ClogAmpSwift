//
//  SongTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class SongTableView: ViewController {
    
    //MARK: Properties
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    var sSortBy        = "title"
    var bSortAsc       = true
    
    var fontSize       = 0
    
    let prefMonoFontSongs = UserDefaults.standard.bool(forKey: "prefMonoFontSongs")
    
    //Search stuff
    var lastSearchTime: UInt64 = 0
    var searchSting    = ""
    var searchTimer: Timer?
    
    weak var mainView: MainView?
    
    //MARK: Outlets
    @IBOutlet weak var songTable: TableView!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var percentLabel: NSTextField!
    @IBOutlet weak var pathControl: NSPathControl!
    
    //MARK: Overrides
    override func viewDidLoad() {
        if !UserDefaults.standard.bool(forKey: "prefStartFocusFilter") {
            self.delayWithSeconds(1.25, closure: {
                DispatchQueue.main.async {
                    self.songTable.enclosingScrollView?.becomeFirstResponder()
                }
            })
        } else {
            self.delayWithSeconds(1.25, closure: {
                DispatchQueue.main.async {
                    self.searchField.becomeFirstResponder()
                }
            })
        }
        
        self.songTable.selectionDelegate = self
        self.songTable.delegate          = self
        self.songTable.dataSource        = self
        
        self.fontSize = UserDefaults.standard.integer(forKey: "songTableFontSize")
        if(self.fontSize == 0){
            self.fontSize = 12
        }

        if let musicPath = UserDefaults.standard.string(forKey: "musicFolderPath") {
//            //############################################################################
//            //Read Access Rights
//            if let bookmarksUrl = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first?.appendingPathComponent("ClogAmpSwift/bookmarks"){
//
//                func restore(_ bookmark: (key: URL, value: Data)) {
//                    let url: URL?
//                    var isStale = false
//
//                    do {
//                        url = try URL.init(resolvingBookmarkData: bookmark.value, options: NSURL.BookmarkResolutionOptions.withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
//
//                        url?.startAccessingSecurityScopedResource()
//                    } catch { }
//
//                }
//
//                if let bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: bookmarksUrl.path) as? [URL: Data] {
//                    for bookmark in bookmarks {
//                        restore(bookmark)
//                    }
//                }
//            }
//            //############################################################################
            
            self.setMusicDirectory(musicPath)
        }
        
        //In case of first run, set title and ascending. In case the app already ran at least once, nothing changes the sort here
        self.songTable.sortDescriptors = [NSSortDescriptor(key: self.sSortBy, ascending: self.bSortAsc)]
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        if self.mainView?.playerView?.currentSong === nil {
            //Load previously loaded Song (Song that was loaded as the app was last closed)
            if let lastLoadedSongURL = UserDefaults.standard.string(forKey: "lastLoadedSongURL") {
                if FileManager.default.fileExists(atPath: lastLoadedSongURL) {
                    let url  = URL(string: lastLoadedSongURL.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!
                    let song = Song.retrieveSong(path: url)
                    self.mainView?.playerView?.loadSong(song: song)
                    
                    DispatchQueue.main.async {
                        self.mainView?.positionTableView?.refreshTable(single: true)
                    }
                }
            }
        }
        
        super.viewDidAppear()
    }
    
    override func keyDown(with event: NSEvent) {
    
        switch event.keyCode {
            case 36: // Enter
                if songTable.selectedRow >= 0 {
                    self.mainView?.playerView?.loadSong(song: self.aSongsForTable[songTable.selectedRow])
                    
                    DispatchQueue.main.async {
                        self.mainView?.positionTableView?.refreshTable()
                    }
                }
            default:
                let currentSearchTime = mach_absolute_time() //nanoseconds
                
                //1ms = 1 000 000 ns
                //500ms = 500 000 000 ns
                if (currentSearchTime - self.lastSearchTime) < 500000000 || event.modifierFlags.contains(.shift) {
                    //within search time or shift pressed?
                    if event.modifierFlags.contains(.shift) {
                        //shift pressed => even within 500ms = new search
                        self.searchSting  = event.charactersIgnoringModifiers ?? ""
                    }else{
                        self.searchSting += event.charactersIgnoringModifiers ?? ""
                    }
                    
                    self.lastSearchTime  = currentSearchTime
                    
                    self.searchTimer?.invalidate()
                    
                    self.searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {
                        timer in
                        //do stuff
                        for song in self.aSongsForTable {
                            if song.getValueAsString("title").starts(with: self.searchSting) {
                                do {
                                    let index = self.aSongsForTable.firstIndex(where: {
                                        songElement in
                                        return song === songElement
                                    }) ?? -1
                                
                                    if index >= 0 {
                                        self.songTable.selectRowIndexes([index], byExtendingSelection: false)
                                        self.songTable.scrollRowToVisible(index)
                                        break //stop the for loop, we found the line
                                    }
                                }
                            }
                        }
                    })
                    
                }else{
                    self.mainView?.keyDown(with: event)
                }
        }
    }
    
    //MARK: Custom Methods
    func setMusicDirectory(_ dir: String){
        self.aSongs.removeAll()
        
        self.pathControl.url = URL(fileURLWithPath: dir)
        
        DispatchQueue.global(qos: .background).async {
            var positionLoaded = false

            FileSystemUtils.readFolderContentsAsSong(sPath: dir) {
                let song    = $0
                let percent = $1
                
                DispatchQueue.main.async {
                    self.percentLabel.isHidden = false
                    
                    if percent < 100 {
                        self.percentLabel.stringValue = "\(percent)%"
                    }
                }
                
                self.aSongs.append(song)
                self.aSongsForTable = self.aSongs
                
                
                
                if !positionLoaded {
                    self.aSongs[0].loadPositions(true)
                    positionLoaded = true
                }
            }
            
            if(self.aSongs.count > 0){
                self.aSongs[0].loadPositions(true)
                
                self.aSongsForTable = self.aSongs
                
                DispatchQueue.main.async {
                    self.performSortSongs()
                }
            }
            
            DispatchQueue.main.async {
                self.percentLabel.stringValue = ""
                self.percentLabel.isHidden = true
            }
        }
    }
    
    func sortSongs(by: String, ascending: Bool){
        self.sSortBy  = by
        self.bSortAsc = ascending
        
        self.performSortSongs()
    }
    
    func performSortSongs() {
        func compare(a: Any, b: Any) -> Bool {
            if let valueA = a as? Int, let valueB = b as? Int {
                if(self.bSortAsc){
                    return valueA < valueB
                }else{
                    return valueA > valueB
                }
            } else if let valueA = a as? String, let valueB = b as? String {
                if(self.bSortAsc){
                    return valueA < valueB
                }else{
                    return valueA > valueB
                }
//            } else if let valueA = a as? Bool, let valueB = b as? Bool {
//                if(self.bSortAsc){
//                    return valueA == valueB
//                }else{
//                    return valueA != valueB
//                }
            } else {
                return false;
            }
        }
        
        self.aSongsForTable.sort(by: {
            return compare(a: $0.getValueToCompare(self.sSortBy), b: $1.getValueToCompare(self.sSortBy))
        })
        
        //Update the table view to represent the new sort order
        DispatchQueue.main.async {
            //don't call self.refreshTable() as it would remember the selection
            self.songTable.reloadData()
        }
    }
    
    func refreshTable() {
        DispatchQueue.main.async {
            let selRow = self.songTable.selectedRow
            self.songTable.reloadData()
            self.songTable.selectRowIndexes([selRow], byExtendingSelection: false)
        }
    }
    
    func loadSelectedSong() {
        if(self.songTable.selectedRow >= 0) {
            let song = self.aSongsForTable[self.songTable.selectedRow]
            self.mainView?.playerView?.loadSong(song: song)
//            self.mainView?.pdfView?.findPdfForSong(songName: song.getValueAsString("title"), fileName: song.filePathAsUrl.lastPathComponent)
            DispatchQueue.main.async {
                self.mainView?.positionTableView?.refreshTable(single: true)
            }
        }
    }
    
    //MARK: UI Selectors - Actions
    @IBAction func handleSongSelected(_ sender: Any) {
        self.loadSelectedSong()
    }
    
    @IBAction func handleSelectMusicDirectory(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = NSLocalizedString("chooseFolder", tableName: "Main", comment: "")
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canChooseFiles          = false
        dialog.canCreateDirectories    = false
        dialog.allowsMultipleSelection = false
        
        if let savedPath = UserDefaults.standard.string(forKey: "musicFolderPath") {
            dialog.directoryURL        = URL(fileURLWithPath: savedPath)
        }
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
                
//                //############################################################################
//                //Save the access rights
//                var bookmarks = [URL: Data]()
//
//                do {
//                    let data: Data = try result.bookmarkData(
//                        options: URL.BookmarkCreationOptions.withSecurityScope,
//                        includingResourceValuesForKeys: nil,
//                        relativeTo: nil
//                    )
//
//                    bookmarks[result] = data
//
//                    if let bookmarksUrl = FileManager.default.urls(for: FileManager.SearchPathDirectory.applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first?.appendingPathComponent("ClogAmpSwift/bookmarks"){
//
//                        NSKeyedArchiver.archiveRootObject(bookmarks, toFile: bookmarksUrl.path)
//
//                    }
//
//                }catch{}
//                //############################################################################
                
                //Open directory
                self.setMusicDirectory(result.path)
                UserDefaults.standard.set(result.path, forKey: "musicFolderPath")
            }
        }
    }
    
    @IBAction func handleIncreaseTextSize(_ sender: NSButton) {
        self.fontSize += 1
        self.refreshTable()
        
        UserDefaults.standard.set(self.fontSize, forKey: "songTableFontSize")
    }
    
    @IBAction func handleDecreaseTextSize(_ sender: NSButton) {
        self.fontSize -= 1
        self.refreshTable()
        
        UserDefaults.standard.set(self.fontSize, forKey: "songTableFontSize")
    }
    @IBAction func handleSearchEnter(_ sender: NSTextField) {
        self.songTable.enclosingScrollView?.becomeFirstResponder()
        if self.aSongsForTable.count > 0 {
            let indexSet = IndexSet(integer: 0)
            self.songTable.selectRowIndexes(indexSet, byExtendingSelection: false)
        }
    }
    
    @IBAction func onEndEditing(_ sender: NSTextField) {
        let iRow = self.songTable.row(for: sender)
        let iCol = self.songTable.column(for: sender)
        let oCol = self.songTable.tableColumns[iCol]
        
        let text = sender.stringValue
        let identifier = oCol.identifier.rawValue
        
        let song = self.aSongsForTable[iRow]
        
        switch identifier {
            case "title":
                if song.title != text {
                    song.title = text
                    song.saveChanges()
                }
            case "artist":
                if song.artist != text {
                    song.artist = text
                    song.saveChanges()
                }
            case "bpm":
                if song.bpm != UInt(text) {
                    song.bpm = UInt(text) ?? 0  
                    song.saveChanges()
                }
            case "level":
                if song.level != text {
                    song.level = text
                    song.saveChanges()
                }
            default:
                return
        }
    }
}

extension SongTableView: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if self.aSongsForTable.count <= row {
            return nil
        }
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            
            textField.stringValue = self.aSongsForTable[row].getValueAsString(tableColumn!.identifier.rawValue)
            
            if prefMonoFontSongs {
                textField.font = NSFont.init(name: "B612-Regular", size: CGFloat(self.fontSize))
            } else {
                textField.font = NSFont.systemFont(ofSize: CGFloat(self.fontSize))
            }
            
            textField.sizeToFit()
            textField.setFrameOrigin(NSZeroPoint)
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if prefMonoFontSongs {
            return CGFloat(round(Double(self.fontSize) * 1.7))
        } else {
            return CGFloat(self.fontSize + 8)
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.aSongsForTable.count
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        if(tableView.sortDescriptors.count > 0){
            let oDesc = tableView.sortDescriptors[0]
            self.sortSongs(by: oDesc.key!, ascending: oDesc.ascending )
        }
        
    }
    
    //Don't ask why, but this function prevents the cells from switching to edit mode on a single click in a non-selected row
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return nil;
    }
}

extension SongTableView: TableViewDelegate {
    
    func rowSelected() {
        self.loadSelectedSong()
    }
    
}

extension SongTableView: NSTextFieldDelegate {
    //For the search field
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let value = textField.stringValue.lowercased()
        
        if(value != ""){
            self.aSongsForTable = self.aSongs.filter{
                return (
                    $0.getValueAsString("title").lowercased().contains(value) ||
                    $0.getValueAsString("artist").lowercased().contains(value) ||
                    $0.getValueAsString("level").lowercased().contains(value) ||
                    $0.getValueAsString("path").lowercased().contains(value)
                )
            }
        }else{
            self.aSongsForTable = self.aSongs
        }
        
        self.performSortSongs()
    }
    
}

