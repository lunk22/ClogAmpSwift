//
//  PlaylistViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 12.11.19.
//

import AppKit

class PlaylistViewController: ViewController {

    var playlists = [Playlist]()
    var songs = [Song]() {
        didSet {
            let hasSongs = !songs.isEmpty
            btnPlay.isEnabled = hasSongs
            btnStop.isEnabled = hasSongs
            cbContPlayback.isEnabled = hasSongs
            lblPause.isEnabled = hasSongs
            txtPause.isEnabled = hasSongs && cbContPlayback.state == .on
        }
    }
    var selectedPlaylist: Playlist?
    var currentSongIndex: Int? = nil
    var playingPlaylistID: Int? = nil

    var playerView: PlayerViewController?
    weak var mainView: MainViewController?

    @IBOutlet weak var playlistTable: NSTableView!
    @IBOutlet weak var songTable: TableView!
    @IBOutlet weak var btnPlay: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    @IBOutlet weak var cbContPlayback: NSButton!
    @IBOutlet weak var lblPause: NSTextField!
    @IBOutlet weak var txtPause: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        playlists = Database.getPlaylists() as? [Playlist] ?? []

        songTable.registerForDraggedTypes([.string, .tableRowIndex])

        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "mainWindow" }),
           let viewController = window.contentViewController as? MainViewController {
            mainView = viewController
            playerView = viewController.playerView
        }

        btnPlay.isEnabled = false
        btnStop.isEnabled = false
        cbContPlayback.isEnabled = false
        lblPause.isEnabled = false
        txtPause.isEnabled = false

        songTable.selectionDelegate = self
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.delegate = self
    }

    func loadPlaylist() {
        let index = playlistTable.selectedRow
        guard index >= 0 else { return }
        currentSongIndex = nil
        selectedPlaylist = playlists[index]

        guard let playlist = selectedPlaylist else { return }

        cbContPlayback.state = playlist.contPlayback ? .on : .off
        txtPause.integerValue = Int(playlist.pause)

        let songItems = Database.getPlaylistSongs(playlist.plID) as? [PlaylistSongItem] ?? []
        songs = songItems.compactMap { item in
            FileSystemUtils.aSongs.first(where: {
                $0.title == item.title || $0.filePathAsUrl.lastPathComponent == item.fileName
            })
        }

        songTable.reloadData()
    }

    func loadSong(_ index: Int? = nil) {
        if let index = index {
            guard index < songs.count else { return }
            currentSongIndex = index
        } else {
            let selected = songTable.selectedRow
            guard selected >= 0 else { return }
            currentSongIndex = selected
        }

        guard let idx = currentSongIndex else { return }
        playerView?.loadSong(song: songs[idx])
        songTable.reloadData()

        switch Settings.viewAfterSongLoad {
        case 1:
            mainView?.tabView.selectTabViewItem(at: 1)
        case 2:
            mainView?.tabView.selectTabViewItem(at: 2)
        default:
            break
        }
    }

    @IBAction func addNewPlaylist(_ sender: Any) {
        let newDesc = NSLocalizedString("newPlaylist", bundle: Bundle.main, comment: "") as NSString as String
        if let playlist = Playlist(newPlaylistWithDesc: newDesc, withOrder: Int32(playlists.count + 1)) {
            playlists.append(playlist)
            playlistTable.reloadData()
            songTable.reloadData()
        }
    }

    @IBAction func deletePlaylist(_ sender: Any) {
        let index = playlistTable.selectedRow
        guard index >= 0 else { return }

        Database.deletePlaylist(playlists[index].plID)
        playlists.remove(at: index)
        songs = []
        currentSongIndex = nil

        playlistTable.selectRowIndexes(IndexSet(integer: -1), byExtendingSelection: false)
        playlistTable.reloadData()
        songTable.reloadData()
    }

    @IBAction func onEndEditingPlaylist(_ sender: NSTextField) {
        let row = playlistTable.row(for: sender)
        guard row >= 0 else { return }
        playlists[row].description = sender.stringValue
        playlistTable.reloadData()
    }

    @IBAction func handleDoubleClickSong(_ sender: Any) {
        loadSong()
    }

    @IBAction func handleAddRemovePlaylist(_ sender: Any) {
        guard let segCont = sender as? NSSegmentedControl else { return }
        switch segCont.selectedSegment {
        case 0:
            addNewPlaylist(sender)
        case 1:
            deletePlaylist(sender)
        default:
            break
        }
    }

    @IBAction func handleRemoveSong(_ sender: Any) {
        let index = songTable.selectedRow
        guard index >= 0, let playlist = selectedPlaylist else { return }

        let song = songs[index]
        let removed = Database.removeSong(
            fromPlaylist: playlist.plID,
            withTitle:    song.getValueAsString("title"),
            withDuration: Int32(song.duration),
            withFileName: song.getValueAsString("fileName")
        )

        if removed {
            songs.remove(at: index)
            songTable.reloadData()
        }
    }

    @IBAction func handleStartPlaylist(_ sender: Any) {
        guard selectedPlaylist != nil, !songs.isEmpty else { return }
        if currentSongIndex == nil {
            loadSong(0)
        }
        PlayerAudioEngine.shared.play()
        playingPlaylistID = (selectedPlaylist?.plID).map { Int($0) }
        playlistTable.reloadData()

        NotificationCenter.default.removeObserver(self,
            name: PlayerAudioEngine.NotificationNames.songFinished,
            object: nil
        )
        NotificationCenter.default.addObserver(self,
            selector: #selector(songFinished),
            name: PlayerAudioEngine.NotificationNames.songFinished,
            object: nil
        )
    }

    @IBAction func handleStopPlaylist(_ sender: Any?) {
        PlayerAudioEngine.shared.stop()
        currentSongIndex = nil
        playingPlaylistID = nil
        songTable.reloadData()
        playlistTable.reloadData()

        NotificationCenter.default.removeObserver(self,
            name: PlayerAudioEngine.NotificationNames.songFinished,
            object: nil
        )
    }

    @IBAction func changeContPlayback(_ sender: Any) {
        txtPause.isEnabled = !songs.isEmpty && cbContPlayback.state == .on
        selectedPlaylist?.contPlayback = cbContPlayback.state == .on
    }

    @IBAction func handlePauseChange(_ sender: Any) {
        selectedPlaylist?.pause = Int32(txtPause.integerValue)
    }

    @objc func songFinished() {
        DispatchQueue.main.async {
            guard self.selectedPlaylist != nil, let idx = self.currentSongIndex else { return }
            if idx < self.songs.count - 1 {
                self.loadSong(idx + 1)
                if self.cbContPlayback.state == .on {
                    delayWithSeconds(Double(self.txtPause.integerValue)) {
                        PlayerAudioEngine.shared.play()
                    }
                }
            } else {
                self.handleStopPlaylist(nil)
            }
        }
    }
}

extension PlaylistViewController: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn,
              let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: nil) as? NSTableCellView,
              let textField = cell.textField
        else { return nil }

        if tableView == playlistTable {
            textField.stringValue = playlists[row].description as String? ?? ""
            applyRowHighlight(active: playingPlaylistID == Int(playlists[row].plID), to: cell, textField: textField)
        } else {
            textField.stringValue = songs[row].getValueAsString(tableColumn.identifier.rawValue)
            applyRowHighlight(active: currentSongIndex == row, to: cell, textField: textField)
        }

        if Settings.songTableMonoFont {
            textField.font = NSFont(name: Settings.monoFontName, size: 14)
        } else {
            textField.font = NSFont.systemFont(ofSize: 14)
        }

        return cell
    }

    private func applyRowHighlight(active: Bool, to cell: NSTableCellView, textField: NSTextField) {
        cell.wantsLayer = true
        textField.drawsBackground = false
        textField.textColor = .controlTextColor

        if active && Settings.positionHighlight {
            cell.layer?.backgroundColor = Settings.positionHighlightTextOnly
                ? NSColor.clear.cgColor
                : Settings.positionHighlightColor.cgColor
            textField.textColor = Settings.positionTextColor
        } else {
            cell.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        CGFloat(round(14.0 * 1.7))
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView == playlistTable ? playlists.count : songs.count
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if notification.object as? NSTableView == playlistTable {
            loadPlaylist()
        }
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        guard tableView == songTable else { return nil }
        return PasteboardWriter(path: songs[row].getValueAsString("path"), at: row)
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard tableView == songTable, dropOperation == .above else { return [] }

        if let source = info.draggingSource as? NSTableView, source === tableView {
            tableView.draggingDestinationFeedbackStyle = .gap
        } else {
            tableView.draggingDestinationFeedbackStyle = .regular
        }
        return .move
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView == songTable, let playlist = selectedPlaylist else { return false }
        guard let items = info.draggingPasteboard.pasteboardItems else { return false }

        var newIndex = row

        for item in items {
            guard let sPath = item.string(forType: .string),
                  let oldIndex = item.propertyList(forType: .tableRowIndex) as? Int,
                  let song = FileSystemUtils.aSongs.first(where: { $0.getValueAsString("path") == sPath })
            else { continue }

            if oldIndex >= 0 {
                if newIndex > oldIndex {
                    newIndex -= 1
                }
                songs.remove(at: oldIndex)
                songs.insert(song, at: newIndex)

                if currentSongIndex == oldIndex {
                    currentSongIndex = newIndex
                } else if let idx = currentSongIndex {
                    if oldIndex <= idx && idx <= newIndex {
                        currentSongIndex = idx - 1
                    } else if oldIndex >= idx && idx >= newIndex {
                        currentSongIndex = idx + 1
                    }
                }

                tableView.beginUpdates()
                tableView.moveRow(at: oldIndex, to: newIndex)
                tableView.endUpdates()
            } else {
                songs.insert(song, at: newIndex)
                Database.addSong(
                    toPlaylist:   playlist.plID,
                    withTitle:    song.getValueAsString("title"),
                    withDuration: Int32(song.duration),
                    withFileName: song.getValueAsString("fileName"),
                    withOrder:    0
                )
            }

            for (count, song) in songs.enumerated() {
                Database.updateSongOrder(
                    inPlaylist:   playlist.plID,
                    withTitle:    song.getValueAsString("title"),
                    withDuration: Int32(song.duration),
                    withFileName: song.getValueAsString("fileName"),
                    withOrder:    Int32(count + 1)
                )
            }
        }

        songTable.reloadData()
        return true
    }
}

extension PlaylistViewController: TableViewDelegate {
    func rowSelected() {
        loadSong()
    }

    func rightClicked() {
        // Do nothing
    }
}

extension PlaylistViewController: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard playingPlaylistID != nil else { return true }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("playlistCloseTitle", bundle: .main, comment: "")
        alert.informativeText = NSLocalizedString("playlistCloseMessage", bundle: .main, comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("playlistCloseConfirm", bundle: .main, comment: ""))
        alert.addButton(withTitle: NSLocalizedString("playlistCloseCancel", bundle: .main, comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            handleStopPlaylist(nil)
            return true
        }
        return false
    }
}
