//
//  PlaylistView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 12.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class PlaylistView: ViewController {
    
    var aPlaylists = [Playlist]();
    
    @IBOutlet weak var playlistTable: NSTableView!
    @IBOutlet weak var songTable: NSTableView!
    
    override func viewDidLoad() {
        self.aPlaylists = Database.getPlaylists() as! [Playlist]
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
//        let iCol = self.playlistTable.column(for: sender)
//        let oCol = self.playlistTable.tableColumns[iCol]
        
        if iRow < 0 {
            return
        }
        
        let text = sender.stringValue
        
        let oPlaylist = self.aPlaylists[iRow]
        oPlaylist.description = text
        
    }
    
}
 
extension PlaylistView: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            
            if tableView == self.playlistTable{
                if let desc = self.aPlaylists[row].description {
                    textField.stringValue = desc as String
                }else{
                    textField.stringValue = ""
                }
            }else{
                textField.stringValue = "dummy"
            }
            
            
//            if prefMonoFontSongs {
                textField.font = NSFont.init(name: "B612-Regular", size: CGFloat(16))
//            } else {
//                textField.font = NSFont.systemFont(ofSize: CGFloat(self.fontSize))
//            }
            
//            textField.sizeToFit()
            
            return cell
        }
        
        return nil
    }
    
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return CGFloat(20)
//    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.playlistTable{
            return self.aPlaylists.count
        }else{
            return 0
        }
    }
    
}
