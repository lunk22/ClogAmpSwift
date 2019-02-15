//
//  SongTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class SongTableView: ViewController {
    
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    var sSortBy        = "title"
    var bSortAsc       = true
    
    var fontSize       = 0
    
    weak var mainView: MainView?
    
    //Outlets
    @IBOutlet weak var songTable: TableView!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var directoryLabel: NSTextField!

    //Overrides
    override func viewDidLoad() {
        
        self.songTable.selectionDelegate = self
        self.songTable.delegate          = self
        self.songTable.dataSource        = self
        
        self.fontSize = UserDefaults.standard.integer(forKey: "songTableFontSize")
        if(self.fontSize == 0){
            self.fontSize = 12
        }

        if let musicPath = UserDefaults.standard.string(forKey: "musicFolderPath") {
            self.setMusicDirectory(musicPath)
        }
        
        //In case of first run, set title and ascending. In case the app already ran at least once, nothing changes the sort here
        self.songTable.sortDescriptors = [NSSortDescriptor(key: self.sSortBy, ascending: self.bSortAsc)]
        
        super.viewDidLoad()
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
//            case 48: // Tab
            default:
                self.mainView?.keyDown(with: event)
        }
        
//        if(keyPressed == "enter"){
//        }else{
//
//        }
    }
    
    func setMusicDirectory(_ dir: String){
        DispatchQueue.global(qos: .background).async {
            var positionLoaded = false
//            self.aSongs =
            FileSystemUtils.readFolderContentsAsSong(sPath: dir, oView: self) {
                let song    = $0
                let percent = $1
                
                self.aSongs.append(song)
                self.aSongsForTable = self.aSongs
                
                DispatchQueue.main.async {
                    if percent < 100 {
                        self.directoryLabel.stringValue = "\(dir) - \(percent)%"
                    }else{
                        self.directoryLabel.stringValue = "\(dir)"
                    }
                    
                    self.performSortSongs()
                }
                
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
        }
        
        self.directoryLabel.stringValue = dir;
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
        let selRow = self.songTable.selectedRow
        self.songTable.reloadData()
        self.songTable.selectRowIndexes([selRow], byExtendingSelection: false)
    }
    
    func loadSelectedSong() {
        if(self.songTable.selectedRow >= 0) {
            self.mainView?.playerView?.loadSong(song: self.aSongsForTable[self.songTable.selectedRow])
            
            DispatchQueue.main.async {
                self.mainView?.positionTableView?.refreshTable()
            }
        }
    }
    
    //UI Selectors
    @IBAction func handleSongSelected(_ sender: Any) {
        self.loadSelectedSong()
    }
    
    @IBAction func handleSelectMusicDirectory(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canChooseFiles          = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
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
        default:
            return
        }
    }
}

extension SongTableView: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            let fontDescriptor = textField.font!.fontDescriptor
            
            textField.stringValue = self.aSongsForTable[row].getValueAsString(tableColumn!.identifier.rawValue)
            textField.font = NSFont.init(descriptor: fontDescriptor, size: CGFloat(self.fontSize))
            textField.sizeToFit()
            textField.setFrameOrigin(NSZeroPoint)
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(self.fontSize + 3)
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

