//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import AppKit

class MainView: NSViewController {
    
    var aSongs         = [Song]()
    var aSongsForTable = [Song]()
    
    weak var playerDelegate: PlayerDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchField: NSTextField!
    
    // Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.aSongs = FileSystemUtils.readFolderContentsAsSong(sPath: "/Users/d043610/private/clogging/Musik")
        self.aSongsForTable = self.aSongs
        self.sortSongs(by: "title")
        
//        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) {
//            self.flagsChanged(with: $0)
//            return $0
//        }

//        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) {
//            self.keyDown(with: $0)
//            return $0
//        }
    }
    
    override func keyDown(with event: NSEvent) {
        let keyPressed = (event.charactersIgnoringModifiers ?? "")
        
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
        }else if(keyPressed == "F"){
//          if(event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.shift]){
            self.searchField.becomeFirstResponder()
//          }
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
    
    func sortSongs(by: String){
        self.aSongsForTable.sort(by: { $0.getValueAsString(by).uppercased() < $1.getValueAsString(by).uppercased() })
        
        //Update the table view to represent the new sort order
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    //UI Selectors
    @IBAction func songSelected(_ sender: NSTableView) {
        if sender.selectedRow >= 0 {
            self.playerDelegate?.loadSong(song: self.aSongsForTable[sender.selectedRow])
        }
    }
    
}

extension MainView: NSTableViewDelegate, NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if(self.aSongsForTable.count < (row - 1)){ return "" }

        let value = self.aSongsForTable[row].getValueAsString(tableColumn!.identifier.rawValue)
        return value
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.aSongsForTable.count
    }
}

extension MainView: NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let value = textField.stringValue.lowercased()
        
//        let imageObject = questionImageObjects.filter{ $0.imageUUID == imageUUID }.first
        if(value != ""){
            self.aSongsForTable = self.aSongs.filter{
                return $0.title.lowercased().contains(value)
            }
        }else{
            self.aSongsForTable = self.aSongs
        }
        
        
        //Update the table view to represent the new sort order
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
}
