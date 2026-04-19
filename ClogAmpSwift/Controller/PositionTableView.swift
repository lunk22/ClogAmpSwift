//
//  PositionTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class PositionTableView: NSViewController {
    
    var fontSize        = 0
    var visible         = false
    var currentPosition = -1
    
    weak var mainView: MainView?
    
    //Outlets
    @IBOutlet weak var positionTable: TableView!
    
    //Overrides
    override func viewDidLoad() {
        
        self.positionTable.selectionDelegate = self
        
        self.fontSize = UserDefaults.standard.integer(forKey: "positionTableFontSize")
        if(self.fontSize == 0){
            self.fontSize = 12
        }
        
        super.viewDidLoad()
    }
    override func keyDown(with event: NSEvent) {
        var positionIndex = -1
        
        switch(event.keyCode){
            case 18: // 1
                positionIndex = 0
            case 19: // 2
                positionIndex = 1
            case 20: // 3
                positionIndex = 2
            case 21: // 4
                positionIndex = 3
            case 23: // 5
                positionIndex = 4
            case 22: // 6
                positionIndex = 5
            case 26: // 7
                positionIndex = 6
            case 28: // 8
                positionIndex = 7
            case 25: // 9
                positionIndex = 8
            case 29: // 0
                positionIndex = 9
            case 36: // Enter
                positionIndex = self.positionTable.selectedRow
            default:
                self.mainView?.keyDown(with: event)
                return
        }
        
        if(event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.shift]){
            positionIndex += 10
        }
        
        self.mainView?.playerView?.handlePositionSelected(positionIndex)
    }
    
    func refreshTable(single: Bool = false) {
        func performRefresh() {
            let selRow = self.positionTable.selectedRow
            self.positionTable.reloadData()
            self.positionTable.selectRowIndexes([selRow], byExtendingSelection: false)
        }
        
        if(!single){
            //Not visible => no refresh
            if(!self.visible){
                return
            }
            
            //No positions => no refresh
            if let song = self.mainView?.playerView?.getSong() {
                if(song.positions.count < 1){
                    return
                }
            
                var currentPosition = -1
                let currentTime = self.mainView?.playerView?.avAudioPlayer?.currentTime ?? 0
                
                for position in song.positions {
                    if(Double(position.time / 1000) <= currentTime){
                        currentPosition = song.positions.firstIndex(where: {
                            return $0 === position
                        }) ?? -1
                    }
                }
                
                if(self.currentPosition != currentPosition){
                    self.currentPosition = currentPosition
                    performRefresh()
                }
            }
        }else{
            //Single Update
            performRefresh()
        }
        
        
    }
    
    //UI Selectors
    @IBAction func handleSelectPosition(_ sender: NSTableView) {
        self.mainView?.playerView?.handlePositionSelected(sender.selectedRow)
    }
    
    @IBAction func handleIncreaseTextSize(_ sender: NSButton) {
        self.fontSize += 1
        self.refreshTable(single: true)
        
        UserDefaults.standard.set(self.fontSize, forKey: "positionTableFontSize")
    }
    @IBAction func handleDecreaseTextSize(_ sender: NSButton) {
        self.fontSize -= 1
        self.refreshTable(single: true)
        
        UserDefaults.standard.set(self.fontSize, forKey: "positionTableFontSize")
    }
}

extension PositionTableView: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            let fontDescriptor = textField.font!.fontDescriptor
            
            if let song = self.mainView?.playerView?.getSong() {
                
                textField.drawsBackground = false
                textField.backgroundColor = NSColor.controlColor
                textField.textColor       = NSColor.controlTextColor
                
                if(self.mainView?.playerView?.avAudioPlayer?.isPlaying ?? false){
//                    var currentPosition = -1
//                    let currentTime = self.mainView?.playerView?.avAudioPlayer?.currentTime ?? 0
//
//                    for position in song.positions {
//                        if(Double(position.time / 1000) <= currentTime){
//                            currentPosition = song.positions.firstIndex(where: {
//                                return $0 === position
//                            }) ?? -1
//                        }
//                    }
                    
                    if(self.currentPosition == row){
                        textField.drawsBackground = true
                        textField.backgroundColor = NSColor.systemOrange
                        textField.textColor       = NSColor.black
                    }
                }
                
                if(tableColumn!.identifier.rawValue == "number"){
                    textField.stringValue = "\(row + 1)"
                }else{
                    textField.stringValue = song.positions[row].getValueAsString(tableColumn!.identifier.rawValue)
                }
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

extension PositionTableView: TableViewDelegate {
    
    func rowSelected() {
        print("Row selected")
    }
    
}
