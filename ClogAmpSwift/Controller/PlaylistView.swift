//
//  PlaylistView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 12.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class PlaylistView: ViewController {
    
    var aPlaylists = [Playlist]()
    var aSongs     = [Song]() {
        didSet {
            if self.aSongs.count > 0 {
                self.btnPlay.isEnabled = true
                self.btnStop.isEnabled = true
                self.cbContPlayback.isEnabled = true
                self.lblPause.isEnabled = true
                self.txtPause.isEnabled = true
            }
        }
    }
    var oSelectedPlaylist: Playlist?
    var iSongIndex: Int = -1
    
    var playerView: PlayerView?
    weak var mainView: MainView?
    
    @IBOutlet weak var playlistTable: NSTableView!
    @IBOutlet weak var songTable: TableView!
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    @IBOutlet weak var cbContPlayback: NSButton!
    @IBOutlet weak var lblPause: NSTextField!
    @IBOutlet weak var txtPause: NSTextField!    
    
    override func viewDidLoad() {
        self.aPlaylists = Database.getPlaylists() as! [Playlist]
        
//        // https://www.natethompson.io/2019/03/23/nstableview-drag-and-drop.html
        self.songTable.registerForDraggedTypes([.string, .tableRowIndex])
        
        let viewController = NSApplication.shared.windows[0].contentViewController as! MainView
        self.mainView = viewController
        self.playerView = viewController.playerView
        
        self.btnPlay.isEnabled = false
        self.btnStop.isEnabled = false
        self.cbContPlayback.isEnabled = false
        self.lblPause.isEnabled = false
        self.txtPause.isEnabled = false
        
        self.songTable.selectionDelegate = self
    }
    
    func loadPlaylist() {
        let iIndex = self.playlistTable.selectedRow
        if iIndex < 0 { return }
        self.aSongs = []
        self.oSelectedPlaylist = self.aPlaylists[iIndex]
        
        self.cbContPlayback.state = self.oSelectedPlaylist!.contPlayback ? NSControl.StateValue.on : NSControl.StateValue.off
        self.txtPause.integerValue = Int(self.oSelectedPlaylist!.pause)
        
        let aSongItems = Database.getPlaylistSongs(self.oSelectedPlaylist!.plID) as! [PlaylistSongItem]
        
        for playlistSong in aSongItems {
            if let foundSong = FileSystemUtils.aSongs.first(where:{$0.title == playlistSong.title || $0.filePathAsUrl.lastPathComponent == playlistSong.fileName}){
                self.aSongs.append(foundSong)
            }
            
        }
        
        self.songTable.reloadData()
    }
    
    func loadSong(_ index: Int = -1) {
        if index < 0{
            self.iSongIndex = self.songTable.selectedRow
        } else if self.aSongs.count - 1 >= index {
            self.iSongIndex = index
        } else {
            return
        }
        
        if(self.iSongIndex >= 0 && self.aSongs.count > self.iSongIndex){
            self.playerView?.loadSong(song: self.aSongs[self.iSongIndex])
            self.songTable.reloadData()
            
            switch Defaults.viewAfterSongLoad {
            case 1:
                self.mainView?.tabView.selectTabViewItem(at: 1)
            case 2:
                self.mainView?.tabView.selectTabViewItem(at: 2)
            default:
                return
            }
        }
    }
    
    func updatePlaylist(oPL: Playlist? = nil) {
        if oPL != nil {
            Database.updatePlaylist(
                oPL!.plID,
                withDesc: oPL!.description,
                withContPlayback: oPL!.contPlayback,
                withPause: oPL!.pause,
                withOrder: oPL!.order
            )
        } else if let oPlaylist = self.oSelectedPlaylist {
            Database.updatePlaylist(
                oPlaylist.plID,
                withDesc: oPlaylist.description,
                withContPlayback: self.cbContPlayback.state == NSControl.StateValue.on,
                withPause: Int32(self.txtPause?.integerValue ?? 0),
                withOrder: oPlaylist.order
            )
        }
        self.playlistTable.reloadData()
    }
    
    @IBAction func addNewPlaylist(_ sender: Any) {
        let newDesc = NSLocalizedString("newPlaylist", bundle: Bundle.main, comment: "") as NSString as String
        if let oPlaylist = Playlist.init(newPlaylistWithDesc: newDesc, withOrder: (Int32(self.aPlaylists.count + 1))) {
            self.aPlaylists.append(oPlaylist)
            self.playlistTable.reloadData()
            self.songTable.reloadData()
        }
    }
    
    @IBAction func deletePlaylist(_ sender: Any) {
        // Get index of the playlist
        let iIndex = self.playlistTable.selectedRow
        
        if iIndex < 0 {
            return
        }
        
        // Determine the playlist and delete it
        let oPlaylist = self.aPlaylists[iIndex]
        Database.deletePlaylist(oPlaylist.plID)
        
        // Remove the playlist from the array
        self.aPlaylists.remove(at: iIndex)
        
        // Unselect all in playlist table
        let indexSet = IndexSet(integer: -1)
        self.playlistTable.selectRowIndexes(indexSet, byExtendingSelection: false)
        
        // Update UI
        self.playlistTable.reloadData()
    }
    
    @IBAction func onEndEditingPlaylist(_ sender: NSTextField) {
        let iRow = self.playlistTable.row(for: sender)
        
        if iRow < 0 {
            return
        }
        
        let text = sender.stringValue
        
        let oPlaylist = self.aPlaylists[iRow]
        oPlaylist.description = text
        
        self.updatePlaylist(oPL: oPlaylist)
    }
    
    @IBAction func handleDoubleClickSong(_ sender: Any) {
        self.loadSong()
    }
    
    @IBAction func handleAddRemovePlaylist(_ sender: Any) {
        let segCont = sender as! NSSegmentedControl

        switch segCont.selectedSegment {
            case 0:
                self.addNewPlaylist(sender)
                break
            case 1:
                self.deletePlaylist(sender)
                break
            default: do { /* Do nothing */ }
        }
    }
    
    @IBAction func handleRemoveSong(_ sender: Any) {
        let selectedIndex = self.songTable.selectedRow
        if selectedIndex == -1 {
            return;
        }
        let song = self.aSongs[selectedIndex]
        
        let removed = Database.removeSong(
            fromPlaylist: self.oSelectedPlaylist!.plID,
            withTitle:    song.getValueAsString("title"),
            withDuration: Int32(song.duration),
            withFileName: song.getValueAsString("fileName")
        )
        
        if removed {
            self.aSongs.remove(at: selectedIndex)
            self.songTable.reloadData()
        }
    }
    
    @IBAction func handleStartPlaylist(_ sender: Any) {
        if self.oSelectedPlaylist != nil && self.aSongs.count > 0 {
            if self.iSongIndex == -1{
                self.loadSong(0)
            }
            self.playerView?.doPlay()
            
            NotificationCenter.default.addObserver(self,
               selector: #selector(songFinished),
               name: PlayerAudioEngine.NotificationNames.songFinished,
               object: nil
            ) // Add observer
        }
    }
    
    @IBAction func handleStopPlaylist(_ sender: Any?) {
        self.playerView?.doStop()
        self.iSongIndex = -1
        
        self.songTable.reloadData()
        
        NotificationCenter.default.removeObserver(self,
           name: PlayerAudioEngine.NotificationNames.songFinished,
           object: nil
        )
    }
    
    @IBAction func changeContPlayback(_ sender: Any) {
        self.txtPause.isEnabled = self.cbContPlayback.state == NSControl.StateValue.on
        
        self.updatePlaylist()
    }
    
    @IBAction func handlePauseChange(_ sender: Any) {
        self.updatePlaylist()
    }
    
    @objc func songFinished() {
        if self.oSelectedPlaylist != nil && self.iSongIndex >= 0 {
            if self.iSongIndex < self.aSongs.count - 1 {
                self.loadSong(self.iSongIndex + 1)
                
                if self.cbContPlayback.state == NSControl.StateValue.on {
//
                    delayWithSeconds(Double(self.txtPause.integerValue)) {
                        self.playerView?.doPlay()
                    }
                }
            } else {
                self.handleStopPlaylist(nil)
            }
        }
    }
}
 
extension PlaylistView: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var fontSize = 16
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            
            if tableView == self.playlistTable{
                if let desc = self.aPlaylists[row].description {
                    textField.stringValue = desc as String
                }else{
                    textField.stringValue = ""
                }
            }else{
                fontSize = 12
                textField.stringValue = self.aSongs[row].getValueAsString(tableColumn!.identifier as NSString as String)
            }
            
            
            if Defaults.songTableMonoFont {
                textField.font = NSFont.init(name: "B612-Regular", size: CGFloat(fontSize))
            } else {
                textField.font = NSFont.systemFont(ofSize: CGFloat(fontSize))
            }
            
            if(tableColumn!.identifier as NSString as String) == "title"{
                textField.drawsBackground = false
                textField.backgroundColor = NSColor.controlColor
                textField.textColor       = NSColor.controlTextColor
                
                if(self.iSongIndex == row){
                    textField.drawsBackground = true
                    textField.backgroundColor = NSColor.systemOrange
                    textField.textColor       = NSColor.black
                }
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == self.playlistTable{
            return CGFloat(24)
        }else if Defaults.songTableMonoFont {
            return CGFloat(round(Double(12) * 1.7))
        } else {
            return CGFloat(20)
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.playlistTable{
            return self.aPlaylists.count
        }else{
            return self.aSongs.count
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSTableView == self.playlistTable{
            self.loadPlaylist()
        }
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return PasteboardWriter(path: self.aSongs[row].getValueAsString("path"), at: row)
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        if tableView != self.songTable{ return [] }
        
        guard dropOperation == .above else { return [] }

        if let source = info.draggingSource as? NSTableView,
            source === tableView
        {
            tableView.draggingDestinationFeedbackStyle = .gap
        } else {
            tableView.draggingDestinationFeedbackStyle = .regular
        }
        return .move
        
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        if tableView != self.songTable{ return false }
        if self.oSelectedPlaylist == nil{ return false }
        
        var newIndex = row
        
        guard let items = info.draggingPasteboard.pasteboardItems
        else { return false }
        
        for item in items {
            let sPath = item.string(forType: .string)!
            let oldIndex = item.propertyList(forType: .tableRowIndex)! as! NSInteger

            
            if let song = FileSystemUtils.aSongs.first(where: { $0.getValueAsString("path") == sPath }){
                if oldIndex >= 0 {
                    if newIndex > oldIndex{
                        newIndex -= 1
                    }
                    self.aSongs.remove(at: oldIndex)
                    self.aSongs.insert(song, at: newIndex)
                    
                    if self.iSongIndex == oldIndex {
                        self.iSongIndex = newIndex
                    }else if oldIndex <= self.iSongIndex && self.iSongIndex <= newIndex {
                        self.iSongIndex -= 1
                    }else if oldIndex >= self.iSongIndex && self.iSongIndex >= newIndex {
                        self.iSongIndex += 1
                    }
                    
                    // Animate the rows
                    tableView.beginUpdates()
                    tableView.moveRow(at: oldIndex, to: newIndex)
                    tableView.endUpdates()
                } else {
                    self.aSongs.insert(song, at: newIndex)
                    
                    Database.addSong(
                        toPlaylist:   self.oSelectedPlaylist!.plID,
                        withTitle:    song.getValueAsString("title"),
                        withDuration: Int32(song.duration),
                        withFileName: song.getValueAsString("fileName"),
                        withOrder:    0
                    )
                }
                
                var count = 0
                for song in self.aSongs {
                    count += 1
                    Database.updateSongOrder(
                        inPlaylist:   self.oSelectedPlaylist!.plID,
                        withTitle:    song.getValueAsString("title"),
                        withDuration: Int32(song.duration),
                        withFileName: song.getValueAsString("fileName"),
                        withOrder:    Int32(count)
                    )
                }
            }
        }
        
        self.songTable.reloadData()
        return true
        
    }
    
}

extension PlaylistView: TableViewDelegate {
    
    func rowSelected() {
        self.loadSong()
    }
    
}
