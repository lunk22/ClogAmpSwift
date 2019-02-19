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
        self.positionTable.delegate          = self
        self.positionTable.dataSource        = self
        
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
        
        if(positionIndex < self.mainView?.playerView?.currentSong?.positions.count ?? 0){
            let indexSet = IndexSet(integer: positionIndex)
            self.positionTable.selectRowIndexes(indexSet, byExtendingSelection: false)
        }
    }
    
    func refreshTable(single: Bool = false) {
        func performRefresh() {
            let selRow = self.positionTable.selectedRow
            self.positionTable.reloadData()
            self.positionTable.selectRowIndexes([selRow], byExtendingSelection: false)
        }
        
        if let song = self.mainView?.playerView?.getSong() {
            song.sortPositions()
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
                let currentTime = self.mainView?.playerView?.avPlayer?.getCurrentTime() ?? -1
                
                for position in song.positions {
                    if(Double(position.time / 1000) <= currentTime){
                        currentPosition = song.positions.firstIndex(where: {
                            return $0 === position
                        }) ?? -1
                    }
                }
                
                if((self.mainView?.playerView?.avPlayer?.isPlaying() ?? false ) && self.currentPosition != currentPosition){
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
        self.mainView?.playerView?.handlePositionSelected(self.positionTable.selectedRow)
    }
    @IBAction func handleAddPosition(_ sender: NSButton) {
        if let song = self.mainView?.playerView?.currentSong {
            var currentTime = self.mainView?.playerView?.avPlayer?.getCurrentTime() ?? 0 //Seconds
            currentTime *= 1000 //Milliseconds
            song.positions.append( Position( name: "Name", comment: "", time: UInt(lround(currentTime)) ) )
            song.positionsChanged = true
            self.refreshTable(single: true)
        }
    }
    @IBAction func handleRemovePosition(_ sender: NSButton) {
        if let song = self.mainView?.playerView?.currentSong {
            song.positions.remove(at: self.positionTable.selectedRow)
            song.positionsChanged = true
            self.refreshTable(single: true)
        }
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
    @IBAction func handleSetTime(_ sender: NSButton) {
        let posIndex = self.positionTable.selectedRow
        if posIndex < 0 {
            return
        }
        
        if let song = self.mainView?.playerView?.currentSong {
            song.positions[posIndex].time = UInt(lround((self.mainView?.playerView?.avPlayer?.getCurrentTime() ?? 0) * 1000))
            song.positionsChanged = true
            self.refreshTable(single: true)
        }
    }
    @IBAction func onEndEditing(_ sender: NSTextField) {
        let iRow = self.positionTable.row(for: sender)
        let iCol = self.positionTable.column(for: sender)
        let oCol = self.positionTable.tableColumns[iCol]
        
        let text = sender.stringValue
        let identifier = oCol.identifier.rawValue
        
        if let song = self.mainView?.playerView?.currentSong {
            let position = song.positions[iRow]
            
            switch identifier {
            case "name":
                if position.name != text {
                    position.name = text
                    song.positionsChanged = true
                }
            case "time":
                if text.range(of: "[0-9]+:[0-9][0-9]:[0-9][0-9][0-9]", options: .regularExpression, range: nil, locale: nil) != nil {
                    let parts    = text.components(separatedBy: ":")
                    
                    let iPart0   = Int(parts[0]) ?? 0
                    let min      = Int(iPart0 * 60 * 1000)
                    
                    let iPart1   = Int(parts[1]) ?? 0
                    let sec      = Int(iPart1 * 1000)
                    
                    let msec     = Int(parts[2]) ?? 0
                    
                    let time     = UInt(Int(min+sec+msec))
                    
                    if position.time != time {
                        position.time = time
                        song.positionsChanged = true
                        self.refreshTable(single: true)
                    }
                }else{
                    self.refreshTable(single: true)
                }
            case "comment":
                if position.comment != text {
                    position.comment = text
                    song.positionsChanged = true
                }
            case "jumpTo":
                if position.jumpTo != text {
                    position.jumpTo = text
                    song.positionsChanged = true
                }
            default:
                return
            }
        }
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
                
                if(self.mainView?.playerView?.avPlayer?.isPlaying() ?? false){                    
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
        self.mainView?.playerView?.handlePositionSelected(self.positionTable.selectedRow)
    }
    
}
