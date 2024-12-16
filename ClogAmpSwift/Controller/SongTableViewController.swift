//
//  SongTableViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//

import AppKit

class SongTableViewController: ViewController {
    
    // MARK: Properties
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    var sSortBy        = "title"
    var bSortAsc       = true
    
    var listRefreshRunning = false
    
    //Search stuff
    var lastSearchTime: UInt64 = 0
    var searchSting    = ""
    var searchTimer: Timer?
    
    var filterValue: String = ""
    
    weak var mainView: MainViewController?
    
    // MARK: Outlets
    @IBOutlet weak var songTable: TableView!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var pathControl: NSPathControl!

    // MARK: Overrides
    override func viewDidLoad() {
        let delay = 1.25
        if Settings.focusFilterOnAppStart {
            delayWithSeconds(delay) {
                self.searchField.becomeFirstResponder()
            }
        } else {
            delayWithSeconds(delay) {
                self.songTable.enclosingScrollView?.becomeFirstResponder()
            }
        }
        
        self.songTable.selectionDelegate = self
        self.songTable.delegate          = self
        self.songTable.dataSource        = self

        if let musicPath = Settings.folderPathMusic {
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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("monoChanged"), object: nil, queue: nil){ _ in
            DispatchQueue.main.async(qos: .default) {
                self.refreshTable()
            }
        }
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        if self.mainView?.playerView?.currentSong === nil {
            //Load previously loaded Song (Song that was loaded as the app was last closed)
            if let lastLoadedSongURL = Settings.lastLoadedSongURL {
                if FileManager.default.fileExists(atPath: lastLoadedSongURL) {
                    let url  = URL(string: lastLoadedSongURL.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!)!
                    let song = Song.retrieveSong(path: url)
                    self.loadSong(song, openLoadView: false)
                }
            }
        }
        
        super.viewDidAppear()
    }
    
    override func keyDown(with event: NSEvent) {
    
        switch event.keyCode {
            case 36: // Enter
                if songTable.selectedRow >= 0 {
                    self.loadSong(self.aSongsForTable[songTable.selectedRow])
                    
                    DispatchQueue.main.async(qos: .default) {
                        self.mainView?.positionTableView?.refreshTable()
                    }
                }
            default:
                self.mainView?.keyDown(with: event)
        }
    }
    
    // MARK: Custom Methods
    func loadSong(_ song: Song, openLoadView: Bool = true) {
        self.mainView?.playerView?.loadSong(song: song)
        
        if !openLoadView {return}
        
        switch Settings.viewAfterSongLoad {
            case 1:
                self.mainView?.tabView.selectTabViewItem(at: 1)
            case 2:
                self.mainView?.tabView.selectTabViewItem(at: 2)
            default:
                return
        }
    }
    
    func setMusicDirectory(_ dir: String){
        // Guard clause: Prevent multiple refreshes running simultaneously
        if self.listRefreshRunning {
            return
        }
        
        self.listRefreshRunning = true
        self.aSongs.removeAll()
        self.aSongsForTable.removeAll()
        
        self.pathControl.url = URL(fileURLWithPath: dir)
        
        DispatchQueue.global(qos: .userInteractive).async {

            self.aSongs = FileSystemUtils.readFolderContentsAsSong(sPath: dir, percentCallback: {
                let percent = $0
                if percent < 100 {
                    DispatchQueue.main.async(qos: .default) {
                        self.progressIndicator.doubleValue = Double(percent)
                        self.progressIndicator.isHidden = false
                    }
                }
                
            })
            
            if(self.aSongs.count > 0){
                self.aSongsForTable = self.aSongs
                
                DispatchQueue.main.async(qos: .default) {
                    self.performSortSongs()
                }
            }
            
            DispatchQueue.main.async(qos: .default) {
                self.progressIndicator.doubleValue = 0.0
                self.progressIndicator.isHidden = true
                self.filterTable()
                self.refreshTable()
                self.listRefreshRunning = false
            }
        }
    }
    
    func sortSongs(by: String, ascending: Bool){
        self.sSortBy  = by
        self.bSortAsc = ascending
        
        self.performSortSongs()
    }
    
    private func performSortSongs() {
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
            } else {
                return false;
            }
        }
        
        self.aSongsForTable.sort(by: {
            return compare(a: $0.getValueToCompare(self.sSortBy), b: $1.getValueToCompare(self.sSortBy))
        })
        
        //Update the table view to represent the new sort order
        self.refreshTable(false)
    }
    
    func refreshTable(_ rememberSelection: Bool = true) {
        DispatchQueue.main.async(qos: .default) {
            let selRow = self.songTable.selectedRow
            self.songTable.reloadData()
//            self.filterTable()
            if rememberSelection {
                self.songTable.selectRowIndexes([selRow], byExtendingSelection: false)
            }
        }
    }
    
    func loadSelectedSong() {
        if(self.songTable.selectedRow >= 0) {
            let song = self.aSongsForTable[self.songTable.selectedRow]
            self.loadSong(song)
        }
    }
    
    func filterTable() {
        if(self.filterValue != ""){
            DispatchQueue.main.async(qos: .default) {
                self.aSongsForTable = self.aSongs.filter{
                    var titleScore  = $0.getValueAsString("title").lowercased().score(word: self.filterValue)
                    
                    if $0.getValueAsString("title").lowercased().contains(self.filterValue) {
                        titleScore += 1.0
                    }
                    
                    let titleScoreRounded = (titleScore*10).rounded(.toNearestOrAwayFromZero)/10
                    
                    let match = (
                        titleScoreRounded >= Settings.filterTitleFactor ||
                        $0.getValueAsString("artist").lowercased().contains(self.filterValue) ||
                        $0.getValueAsString("level").lowercased().contains(self.filterValue) ||
                        $0.getValueAsString("path").lowercased().contains(self.filterValue)
                    )
                    
                    return match
                }
                
                self.performSortSongs()
            }
        } else {
            self.aSongsForTable = self.aSongs
            self.performSortSongs()
        }
        
    }
    
    // MARK: UI Selectors - Actions
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
        
        if let savedPath = Settings.folderPathMusic {
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
        UserDefaults.standard.set((Settings.songTableFontSize + 1), forKey: "songTableFontSize")
        self.refreshTable()
    }
    
    @IBAction func handleDecreaseTextSize(_ sender: NSButton) {
        UserDefaults.standard.set((Settings.songTableFontSize - 1), forKey: "songTableFontSize")
        self.refreshTable()
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

        if(iRow < 0 || iCol < 0){
            return;
        }

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
                if song.bpm != Int(text) {
                    song.bpm = Int(text) ?? 0  
                    song.saveChanges()
                }
            case "level":
                if song.level != text {
                    song.level = text
                    song.saveChanges()
                }
            case "waitBeats":
                if song.waitBeats != Int(text) {
                    song.waitBeats = Int(text) ?? 0
                    song.saveChanges()
                }
            default:
                return
        }
    }
    
    @IBAction func handleRefreshList(_ sender: Any) {
        if let musicPath = Settings.folderPathMusic {
            self.setMusicDirectory(musicPath)
        }
    }
}

extension SongTableViewController: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if self.aSongsForTable.count <= row {
            return nil
        }
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            
            textField.stringValue = self.aSongsForTable[row].getValueAsString(tableColumn!.identifier.rawValue)
            
            if (tableColumn!.identifier.rawValue == "bpm" || tableColumn!.identifier.rawValue == "waitBeats") && textField.stringValue == "0" {
                textField.stringValue = ""
            }
            
            if Settings.songTableMonoFont {
                textField.font = NSFont.init(name: "Menlo", size: CGFloat(Settings.songTableFontSize))
            } else {
                textField.font = NSFont.systemFont(ofSize: CGFloat(Settings.songTableFontSize))
            }
            
            textField.sizeToFit()
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
       if Settings.songTableMonoFont {
           return CGFloat(round(Double(Settings.songTableFontSize) * 1.7))
       } else {
           return CGFloat(Settings.songTableFontSize + 8)
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
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        return self.aSongsForTable[row].getValueAsString("path") as NSString
        return PasteboardWriter(path: self.aSongsForTable[row].getValueAsString("path"), at: -1)
    }

//    //Don't ask why, but this function prevents the cells from switching to edit mode on a single click in a non-selected row
//    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        return nil;
//    }
}

extension SongTableViewController: TableViewDelegate {
    
    func rowSelected() {
        self.loadSelectedSong()
    }
    
    func rightClicked() {
        let menu = NSMenu()
        
        let menuItemLoad = NSMenuItem(title: NSLocalizedString("menuLoadSong", comment: ""), action: #selector(menuLoadSong(_:)), keyEquivalent: "")
        let menuItemFinder = NSMenuItem(title: NSLocalizedString("menuOpenInFinder", comment: ""), action: #selector(menuOpenInFinder(_:)), keyEquivalent: "")
        let menuItemBPM = NSMenuItem(title: NSLocalizedString("menuDetermineBPM", comment: ""), action: #selector(menuDetermineBPM(_:)), keyEquivalent: "")
        
        let songExists = self.songTable.clickedRow >= 0 ? self.aSongsForTable[self.songTable.clickedRow].songFileExists() : false
        
        menuItemLoad.isEnabled = songExists
        menuItemFinder.isEnabled = songExists
        menuItemBPM.isEnabled = songExists
        
//        menuItemLoad.image = NSImage(named: NSImage.touchBarPlayTemplateName)
//        menuItemFinder.image = NSImage(named: NSImage.pathTemplateName)
        
        menu.addItem(menuItemLoad)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(menuItemFinder)
        menu.addItem(menuItemBPM)
        menu.delegate = self
        
        self.songTable.menu = menu
    }
    
    @objc func menuLoadSong(_ sender: AnyObject) {
        self.loadSelectedSong()
    }
    
    @objc func menuOpenInFinder(_ sender: AnyObject) {
        if self.songTable.selectedRow >= 0 {
            let song = self.aSongsForTable[self.songTable.selectedRow]
            NSWorkspace.shared.activateFileViewerSelecting([song.filePathAsUrl])
        }
    }
    
    @objc func menuDetermineBPM(_ sender: AnyObject) {
        if self.songTable.selectedRow >= 0 {
            let song = self.aSongsForTable[self.songTable.selectedRow]
            song.determineBassBPM() { _ in // determined BPM
                if PlayerAudioEngine.shared.song?.filePathAsUrl != song.filePathAsUrl {
                    song.saveChanges()
                }
                self.refreshTable(true)
            }
        }
    }
    
}

extension SongTableViewController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update table selection to the right clicked row
        self.songTable.selectRowIndexes(IndexSet(integer: self.songTable.clickedRow), byExtendingSelection: false)
    }
}

extension SongTableViewController: NSTextFieldDelegate {
    //For the search field
    
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        self.filterValue = textField.stringValue.lowercased()
        
        self.filterTable()
    }
    
}
