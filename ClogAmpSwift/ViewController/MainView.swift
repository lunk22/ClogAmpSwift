//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  MIT License
//

import AppKit

class MainView: NSViewController {
    
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    weak var playerDelegate: PlayerDelegate?
    
    @IBOutlet weak var songTable: NSTableView!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var directoryLabel: NSTextField!
    @IBOutlet weak var positionTable: NSTableView!
    
    // Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func keyDown(with event: NSEvent) {
        let keyPressed = (event.characters ?? "").lowercased()

        if(keyPressed == "+"){
            self.playerDelegate!.increaseSpeed()
        }else if(keyPressed == "-"){
            self.playerDelegate!.decreaseSpeed()
        }else if(keyPressed == "p"){
            self.playerDelegate!.play()
        }else if(keyPressed == "s"){
            self.playerDelegate!.stop()
        }else if(keyPressed == " "){
            self.playerDelegate!.pause()
        }else if(keyPressed == "f"){
          if(event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.shift]){
            self.searchField.becomeFirstResponder()
          }
        }else{
            self.interpretKeyEvents([event])
        }

    }
    
    override func viewDidAppear() {
        self.playerDelegate = self.children[0] as! PlayerView
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setMusicDirectory(_ dir: String){
        DispatchQueue.main.async{
            self.aSongs = FileSystemUtils.readFolderContentsAsSong(sPath: dir)
            
            if(self.aSongs.count > 0){
                self.aSongs[0].loadPositions(true)
                
                self.aSongsForTable = self.aSongs
                
                self.sortSongs(by: "title") //refreshs the UI
            }
            
            self.directoryLabel.stringValue = dir;
        }
    }
    
    func sortSongs(by: String){
        self.aSongsForTable.sort(by: { $0.getValueAsString(by).uppercased() < $1.getValueAsString(by).uppercased() })
        
        //Update the table view to represent the new sort order
        DispatchQueue.main.async{
            self.songTable.reloadData()
        }
    }
    
    //UI Selectors
    @IBAction func handleSongSelected(_ sender: NSTableView) {
        if sender.selectedRow >= 0 {
            self.playerDelegate?.loadSong(song: self.aSongsForTable[sender.selectedRow])
            
            DispatchQueue.main.async{
                self.positionTable.reloadData()
            }
        }
    }
    
    
    @IBAction func handleSelectMusicDirectory(_ sender: Any) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose a folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["txt"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url { // Pathname of the file
                self.setMusicDirectory(result.path)
            }
        }
    }
    
    @IBAction func handleSelectPosition(_ sender: NSTableView) {
        self.playerDelegate?.handlePositionSelected(sender.selectedRow)
    }
}

extension MainView: NSTableViewDelegate, NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if(tableView == self.songTable){
            if(self.aSongsForTable.count < (row - 1)){ return "" }
            
            return self.aSongsForTable[row].getValueAsString(tableColumn!.identifier.rawValue)
        }else{
            if(tableColumn!.identifier.rawValue == "number"){
                return row + 1
            }else if let song = self.playerDelegate?.getSong() {
                return song.positions[row].getValueAsString(tableColumn!.identifier.rawValue)
            }else{
                return ""
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if(tableView == self.songTable){
            return self.aSongsForTable.count
        }else{
            if let song = self.playerDelegate?.getSong() {
                return song.positions.count
            }else{
                return 0
            }
        }
    }
}

extension MainView: NSTextFieldDelegate {
    //For the search field

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let value = textField.stringValue.lowercased()
        
//        let imageObject = questionImageObjects.filter{ $0.imageUUID == imageUUID }.first
        if(value != ""){
            self.aSongsForTable = self.aSongs.filter{
                return
                    $0.getValueAsString("title").lowercased().contains(value) ||
                    $0.getValueAsString("artist").lowercased().contains(value) ||
                    $0.getValueAsString("level").lowercased().contains(value) ||
                    $0.getValueAsString("path").lowercased().contains(value)
            }
        }else{
            self.aSongsForTable = self.aSongs
        }
        
        
        //Update the table view to represent the new sort order
        DispatchQueue.main.async{
            self.songTable.reloadData()
        }
    }
    
}
