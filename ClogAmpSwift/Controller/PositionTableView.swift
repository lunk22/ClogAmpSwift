//
//  PositionTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class PositionTableView: NSViewController {
    
    weak var mainView: MainView?
    
    //Outlets
    @IBOutlet weak var positionTable: NSTableView!
    
    //Overrides
    override func keyDown(with event: NSEvent) {
        self.mainView?.keyDown(with: event)
    }
    
    //UI Selectors
    @IBAction func handleSelectPosition(_ sender: NSTableView) {
        self.mainView?.playerView?.handlePositionSelected(sender.selectedRow)
    }
}

extension PositionTableView: NSTableViewDelegate, NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if(tableColumn!.identifier.rawValue == "number"){
            return row + 1
        }else if let song = self.mainView?.playerView?.getSong() {
            return song.positions[row].getValueAsString(tableColumn!.identifier.rawValue)
        }else{
            return ""
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let song = self.mainView?.playerView?.getSong() {
            return song.positions.count
        }else{
            return 0
        }
    }
}
