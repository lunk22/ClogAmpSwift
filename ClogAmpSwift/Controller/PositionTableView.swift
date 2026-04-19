//
//  PositionTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class PositionTableView: NSViewController {
    
    var fontSize       = 12
    
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
    
    @IBAction func handleIncreaseTextSize(_ sender: NSButton) {
        self.fontSize += 1
        self.positionTable.reloadData()
    }
    @IBAction func handleDecreaseTextSize(_ sender: NSButton) {
        self.fontSize -= 1
        self.positionTable.reloadData()
    }
}

extension PositionTableView: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            let fontDescriptor = textField.font!.fontDescriptor
            
            if(tableColumn!.identifier.rawValue == "number"){
                textField.stringValue = "\(row + 1)"
            }else if let song = self.mainView?.playerView?.getSong() {
                textField.stringValue = song.positions[row].getValueAsString(tableColumn!.identifier.rawValue)
            }else{
                textField.stringValue = ""
            }
            textField.font = NSFont.init(descriptor: fontDescriptor, size: CGFloat(self.fontSize))// .systemFont(ofSize: CGFloat(self.fontSize))
            textField.sizeToFit()
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(self.fontSize + 3)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let song = self.mainView?.playerView?.getSong() {
            return song.positions.count
        }else{
            return 0
        }
    }
}
