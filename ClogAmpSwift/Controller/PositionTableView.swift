//
//  PositionTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit

class PositionTableView: NSViewController {
    
    //MARK: Properties
    var fontSize        = 0
    var visible         = false
    var currentPosition = -1
    
    var loopCount       = 0
    
    weak var mainView: MainView?
    
    //MARK: Outlets
    @IBOutlet weak var positionTable: TableView!
    @IBOutlet weak var cbLoop: NSButton!
    @IBOutlet weak var txtLoopTimes: NSTextField!
    
    //MARK: Overrides
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
        
        if(positionIndex < self.mainView?.playerView?.currentSong?.positions.count ?? 0){
            let indexSet = IndexSet(integer: positionIndex)
            self.positionTable.selectRowIndexes(indexSet, byExtendingSelection: false)
        }
        
        //Always use this one method to perform a position selection
        self.handleSelectPosition(nil)
    }
    
    //MARK: Custom Methods
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
                    if self.cbLoop.state == NSControl.StateValue.on {
                        self.loopCount += 1
                        
                        if self.txtLoopTimes.integerValue != 0 && self.loopCount >= self.txtLoopTimes.integerValue {
                            self.cbLoop.state = NSControl.StateValue.off
                        }
                        
                        self.mainView?.playerView?.handlePositionSelected(self.currentPosition)
                    }else{
                        self.cbLoop.state = NSControl.StateValue.off
                        self.currentPosition = currentPosition
                        performRefresh()
                    }
                }
            }
        }else{
            //Single Update
            performRefresh()
        }
    }
    
    //MARK: UI Selectors
    @IBAction func handleSelectPosition(_ sender: NSTableView?) {
        /*
         Position selected:
         - reset loop count
         - remembered selected position as the current one
         - refresh once to get rid of the orange highlight for a potentially old row
           => refreshTable evaluates currentPosition. If it fits the current time, no update is triggered => old highligt would stay
        */
        self.loopCount = 0
        self.currentPosition = self.positionTable.selectedRow
        self.refreshTable(single: true)
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
        if self.positionTable.selectedRow < 0 {
            return
        }

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
    
    @IBAction func importFromXml(_ sender: NSButton) {
        let openDialog = NSOpenPanel();
        openDialog.title                   = "Import Positions"
        openDialog.showsResizeIndicator    = true
        openDialog.showsHiddenFiles        = false
        openDialog.canCreateDirectories    = false
        openDialog.canChooseDirectories    = false
        openDialog.canChooseFiles          = true
        openDialog.allowedFileTypes        = ["infoexport"]
        openDialog.allowsOtherFileTypes    = false
        
        if openDialog.runModal() == NSApplication.ModalResponse.OK {
            let xmlParser = XMLParser(contentsOf: openDialog.url!)
            let posParser = PositionXmlParser()
            posParser.song = self.mainView?.playerView?.currentSong
            xmlParser?.delegate = posParser
            if xmlParser?.parse() ?? false {
                self.refreshTable(single: true)
            }
        }
    }
    
    @IBAction func exportToXml(_ sender: NSButton) {
        if let song = self.mainView?.playerView?.currentSong {
            let saveDialog = NSSavePanel()
            saveDialog.title                   = "Export Positions"
            saveDialog.showsResizeIndicator    = true
            saveDialog.showsHiddenFiles        = false
            saveDialog.canCreateDirectories    = true
            saveDialog.allowedFileTypes        = ["infoexport"]
            saveDialog.allowsOtherFileTypes    = false
            
            if saveDialog.runModal() == NSApplication.ModalResponse.OK {
                //OK, save the positions to the desired file
                
                let xmlDoc = XMLDocument(kind: XMLNode.Kind.document)
                let xmlRoot = XMLElement(name: "mediafile")
                let xmlPositionList = XMLElement(name: "positionlist")
                
                xmlDoc.version           = "1.0"
                xmlDoc.characterEncoding = "UTF-8"
                xmlDoc.isStandalone      = true
                xmlDoc.setRootElement(xmlRoot)
                
                xmlRoot.addChild(xmlPositionList)
                
                for position in song.positions {
                    let xmlPosition = XMLElement(name: "position")
                    xmlPositionList.addChild(xmlPosition)

                    let xmlJump = XMLElement(name: "jump", stringValue: "-1")
                    xmlPosition.addChild(xmlJump)
                    
                    let xmlTime = XMLElement(name: "milliseconds", stringValue: "\(position.time)")
                    xmlPosition.addChild(xmlTime)
                    
                    let xmlComment = XMLElement(name: "comment", stringValue: position.comment)
                    xmlPosition.addChild(xmlComment)
                    
                    let xmlName = XMLElement(name: "name", stringValue: position.name)
                    xmlPosition.addChild(xmlName)
                }
                
                let xmlData = xmlDoc.xmlData(options: XMLNode.Options.nodePrettyPrint)
                
                try! xmlData.write(to: saveDialog.url!)
            }
        }
    }
    
    @IBAction func onEndEditing(_ sender: NSTextField) {
        let iRow = self.positionTable.row(for: sender)
        let iCol = self.positionTable.column(for: sender)
        let oCol = self.positionTable.tableColumns[iCol]
        
        if iRow < 0 {
            return
        }
        
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
    
    @IBAction func handleLoopChanged(_ sender: NSButton) {
//        if sender.state == NSControl.StateValue.on {
            self.loopCount = 0
//        }
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
    
    //Don't ask why, but this function prevents the cells from switching to edit mode on a single click in a non-selected row
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return nil;
    }
}

extension PositionTableView: TableViewDelegate {
    
    func rowSelected() {
        self.mainView?.playerView?.handlePositionSelected(self.positionTable.selectedRow)
    }
    
}
