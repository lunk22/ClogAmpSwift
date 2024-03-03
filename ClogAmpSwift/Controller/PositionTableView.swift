//
//  PositionTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//  MIT License
//

import AppKit
import WebKit

class PositionTableView: NSViewController, WKNavigationDelegate {
    
    //MARK: Properties
    var fontSize            = 0
    var rowHeight : CGFloat = 1.0
    var visible             = false
    var currentPosition     = -1
    
    var loopCount           = 0
    
    var loopTimer: Timer?
    
    weak var mainView: MainView?
    
    //MARK: Outlets
    @IBOutlet weak var positionTable: TableView!
    @IBOutlet weak var cbLoop: NSButton!
    @IBOutlet weak var txtLoopTimes: NSTextField!
    @IBOutlet weak var cbAutoscroll: NSButton!
    
    //MARK: Overrides
    override func viewDidLoad() {
        
        self.positionTable.selectionDelegate = self
        self.positionTable.delegate          = self
        self.positionTable.dataSource        = self
        
        self.updateBeatsColumnVisibility()
        
        self.fontSize = AppPreferences.positionTableFontSize
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("monoChanged"), object: nil, queue: nil){ _ in
            DispatchQueue.main.async(qos: .default) {
                self.positionTable.reloadData()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("showBeats"), object: nil, queue: nil){ _ in
            DispatchQueue.main.async(qos: .default) {
                self.updateBeatsColumnVisibility()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Song.NotificationNames.bpmChanged, object: nil, queue: nil) { _ in
            DispatchQueue.main.async(qos: .default) {
                self.refreshTable(single: true)
            }
        }
        
        self.positionTable.enclosingScrollView?.becomeFirstResponder()
        
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
        
        if(positionIndex < self.mainView?.playerView?.currentSong?.getPositions().count ?? 0){
            let indexSet = IndexSet(integer: positionIndex)
            self.positionTable.selectRowIndexes(indexSet, byExtendingSelection: false)
        }
        
        //Always use this one method to perform a position selection
        self.handleSelectPosition(nil)
    }
    
    //MARK: Custom Methods
    func updateBeatsColumnVisibility() {
        let beatsColumnIndex = self.positionTable.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "beats"))
        let beatsColumn = self.positionTable.tableColumns[beatsColumnIndex]
        beatsColumn.isHidden = !AppPreferences.positionTableShowBeats
    }
    
    func refreshTable(single: Bool = false) {
        func performRefresh() {
            let selRow = self.positionTable.selectedRow
            self.positionTable.layoutSubtreeIfNeeded()
            self.positionTable.invalidateIntrinsicContentSize()
            self.positionTable.reloadData()
            self.positionTable.selectRowIndexes([selRow], byExtendingSelection: false)
        }
        
        if let song = PlayerAudioEngine.shared.song {
            song.sortPositions()
        }
        
        if(!single){
            //Not visible => no refresh
            if(!self.visible){
                return
            }
            
            //No positions => no refresh
            if let song = PlayerAudioEngine.shared.song {
                if(song.getPositions().count < 1){
                    return
                }
            
                var currentPosition = -1
                let currentTime = PlayerAudioEngine.shared.getCurrentTime()
                let positions = song.getPositions()
                for position in positions {
                    if(Double(position.time / 1000) <= currentTime){
                        currentPosition = positions.firstIndex(where: {
                            return $0 === position
                        }) ?? -1
                    }
                }
                
                if currentPosition > -1 && self.cbAutoscroll.state == NSControl.StateValue.on {
                    self.positionTable.scrollRowToVisible(row: currentPosition, animated: true)
                }
                
                if(PlayerAudioEngine.shared.isPlaying() && self.currentPosition != currentPosition){
                    if self.cbLoop.state == NSControl.StateValue.on {
                        if !(self.loopTimer?.isValid ?? false) {
                            let loopPos = self.currentPosition
                            self.loopTimer = Timer.scheduledTimer(withTimeInterval: AppPreferences.loopDelay, repeats: false, block: {
                                _ in
                                self.loopCount += 1
                                
                                if self.txtLoopTimes.integerValue != 0 && self.loopCount >= self.txtLoopTimes.integerValue {
                                    self.cbLoop.state = NSControl.StateValue.off
                                }
                                
                                self.handlePositionSelected(loopPos)
                            })
                        }
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
    
    func handlePositionSelected(_ index: Int) {
        //Check the index is in range
        if(index == -1 || PlayerAudioEngine.shared.song?.getPositions().count ?? -1 <= index){
            return
        }
        
        if let oPosition = PlayerAudioEngine.shared.song?.getPositions()[index] {
            PlayerAudioEngine.shared.seek(seconds: Float64(oPosition.time / 1000))
            if AppPreferences.playPositionOnSelection && !(PlayerAudioEngine.shared.isPlaying()){
                PlayerAudioEngine.shared.play()
            }
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
        self.loopTimer?.invalidate()
        self.loopTimer = nil
        self.currentPosition = self.positionTable.selectedRow
        self.refreshTable(single: true)
        self.handlePositionSelected(self.positionTable.selectedRow)
    }
    
    @IBAction func handleAddPosition(_ sender: NSButton) {
        if let song = PlayerAudioEngine.shared.song {
            var currentTime = PlayerAudioEngine.shared.getCurrentTime() //Seconds
            currentTime *= 1000 //Milliseconds
            song.addPosition( Position( name: "Name", comment: "", time: UInt(lround(currentTime)), new: true) )
            self.refreshTable(single: true)
            self.mainView?.songTableView?.refreshTable()
        }
    }
    
    @IBAction func handleRemovePosition(_ sender: NSButton) {
        if self.positionTable.selectedRow < 0 {
            return
        }

        if let song = self.mainView?.playerView?.currentSong {
            song.removePosition(at: self.positionTable.selectedRow)
            self.refreshTable(single: true)
            self.mainView?.songTableView?.refreshTable()
        }
    }
    
    @IBAction func handleIncreaseTextSize(_ sender: NSButton) {
        self.fontSize += 3
        self.refreshTable(single: true)
        
        UserDefaults.standard.set(self.fontSize, forKey: "positionTableFontSize")
    }
    
    @IBAction func handleDecreaseTextSize(_ sender: NSButton) {
        self.fontSize -= 3
        self.refreshTable(single: true)
        
        UserDefaults.standard.set(self.fontSize, forKey: "positionTableFontSize")
    }
    
    @IBAction func handleSetTime(_ sender: NSButton) {
        let posIndex = self.positionTable.selectedRow
        if posIndex < 0 {
            return
        }
        
        if let song = PlayerAudioEngine.shared.song {
            song.getPositions()[posIndex].time = UInt(lround(PlayerAudioEngine.shared.getCurrentTime() * 1000))
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
        openDialog.allowedContentTypes     = [.init(filenameExtension: "infoexport")!]
        openDialog.allowsOtherFileTypes    = false
        
        if openDialog.runModal() == NSApplication.ModalResponse.OK {
            let xmlParser = XMLParser(contentsOf: openDialog.url!)
            let posParser = PositionXmlParser()
            posParser.song = self.mainView?.playerView?.currentSong
            xmlParser?.delegate = posParser
            if xmlParser?.parse() ?? false {
                self.refreshTable(single: true)
                self.mainView?.songTableView?.refreshTable()
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
            saveDialog.allowedContentTypes     = [.init(filenameExtension: "infoexport")!]
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
                
                for position in song.getPositions() {
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
        
        var text = sender.stringValue
        let identifier = oCol.identifier.rawValue
        
        if let song = PlayerAudioEngine.shared.song {
            if !song.hasPositions || song.getPositions().count <= iRow {
                return
            }
            
            let position = song.getPositions()[iRow]
            
            switch identifier {
                case "name":
                    if position.name != text {
                        position.name = text
                    }
                case "time":
                    if text == "" { text = "0:00:000" } // text empty? reset to 0:00:000
                    if text.range(of: "^[0-9]*:[0-9]{0,2}:[0-9]{0,3}$", options: .regularExpression, range: nil, locale: nil) != nil {
                        let parts    = text.components(separatedBy: ":")
                        
                        let iPart0   = Int(parts[0]) ?? 0
                        let min      = Int(iPart0 * 60 * 1000)
                        
                        let iPart1   = Int(parts[1]) ?? 0
                        let sec      = Int(iPart1 * 1000)
                        
                        let msec     = Int(parts[2]) ?? 0
                        
                        let time     = UInt(Int(min+sec+msec))
                        
                        if time > (song.duration * 1000) { self.refreshTable(single: true); return }
                        
                        if position.time != time {
                            position.time = time
                            self.refreshTable(single: true)
                        }
                    }else{
                        self.refreshTable(single: true)
                    }
                case "comment":
                    if position.comment != text {
                        position.comment = text
                        self.refreshTable(single: true)
                    }
                case "jumpTo":
                    if position.jumpTo != text {
                        position.jumpTo = text
                    }
                case "beats":
                    // Guard Clauses
                    if !text.isInteger() || text.asInteger() < 0 { self.refreshTable(single: true); return } // not an int or negative int? just refresh to get the old value
                    if text.asInteger() == position.beats { return } // no change?
                    
                    switch AppPreferences.beatsChangeBehaviour {
                        case 0: // Adjust Following
                            return updateBeatsByAdjusting(rowIndex: iRow, beats: Int(text)!)
                        case 1: // Move all following
                            return updateBeatsByMoving(rowIndex: iRow, beats: Int(text)!, refresh: true)
                        default:
                            return
                    }
                default:
                    return
            }
        }
    }
    
    @IBAction func handleLoopChanged(_ sender: NSButton) {
        self.loopCount = 0
        self.loopTimer?.invalidate()
        self.loopTimer = nil
    }
    
    @IBAction func handleRefreshList(_ sender: Any) {
        if let song = self.mainView?.playerView?.getSong() {
            song.readBasicInfo()
            song.loadPositions(true)
            
            self.mainView?.songTableView?.refreshTable()
            self.refreshTable(single: true)
        }
    }
    
    @IBAction func printList(_ sender: Any) {
        if let song = self.mainView?.playerView?.getSong() {
            var sWait = ""
            if song.waitBeats > 0 {
                let sLocWait = (NSLocalizedString("waitBeats", bundle: Bundle.main, comment: "") as NSString as String)
                sWait = String.localizedStringWithFormat(sLocWait, song.waitBeats)
            }
            
            var sPdfHtml        = ""
            sPdfHtml = sPdfHtml + "<style>"
            //sPdfHtml = sPdfHtml + "  table { font-size: 125%; }"
            sPdfHtml = sPdfHtml + "  div { display:inline; font-family: Arial; }"
            sPdfHtml = sPdfHtml + "  table, td { font-family: Arial; border: 0px solid black; border-collapse: collapse; }"
            sPdfHtml = sPdfHtml + "  td { padding: 0.75rem; vertical-align: top; }"
            sPdfHtml = sPdfHtml + "  .center {  display: table; margin-right: auto; margin-left: auto; }"
            sPdfHtml = sPdfHtml + "  .bold {  font-weight: bold; }"
            sPdfHtml = sPdfHtml + "  .nowrap {  white-space: nowrap; }"
            sPdfHtml = sPdfHtml + "</style>"

            sPdfHtml = sPdfHtml + "<div class='center'>"
            sPdfHtml = sPdfHtml + "  <div style='font-size: 2.5rem'>\(song.title)</div>&nbsp;<div style='font-size: 1.2rem'>\(song.artist)</div>"
            sPdfHtml = sPdfHtml + "</div>"
            sPdfHtml = sPdfHtml + "<div class='center'>"
            sPdfHtml = sPdfHtml + "  \(song.getValueAsString("duration"))"
            
            if song.getValueAsString("level") != "" {
                sPdfHtml = sPdfHtml + " &ndash; \(song.level)"
            }
            
            if sWait != "" {
                sPdfHtml = sPdfHtml + " &ndash; \(sWait)"
            }
            
            sPdfHtml = sPdfHtml + "</div>"
            sPdfHtml = sPdfHtml + "<br/>"
            sPdfHtml = sPdfHtml + "<br/>"
            sPdfHtml = sPdfHtml + "<br/>"

            sPdfHtml = sPdfHtml + " <table>"
            
            
            for position in song.getPositions() {
                var comment = position.comment
                comment = comment.replacingOccurrences(of: "- ", with: "- <wbr/>")
                comment = comment.replacingOccurrences(of: "– ", with: "– <wbr/>")
                comment = comment.replacingOccurrences(of: " (", with: " <wbr/>(")
                comment = comment.replacingOccurrences(of: ") ", with: ") <wbr/>")
                comment = comment.replacingOccurrences(of: " [", with: " <wbr/>[")
                comment = comment.replacingOccurrences(of: "] ", with: "] <wbr/>")
                comment = comment.replacingOccurrences(of: " ", with: "&nbsp;")
                comment = comment.replacingOccurrences(of: "", with: "<br/>")
                
                sPdfHtml = sPdfHtml + "    <tr>"
                sPdfHtml = sPdfHtml + "      <td class='bold nowrap'>\(position.name)</td>"
                sPdfHtml = sPdfHtml + "      <td>\(comment)</td>"
                sPdfHtml = sPdfHtml + "    </tr>"
            }
            
            sPdfHtml = sPdfHtml + " </table>"
            
            CreatePDF(htmlString: sPdfHtml, fileName: song.title)
        }
    }
    
    func updateBeatsByAdjusting(rowIndex: Int, beats: Int) {
        if let song = PlayerAudioEngine.shared.song {
            let position = song.getPositions()[rowIndex]
            var nextPosition: Position
            
            let durationForBeats = Double(beats) / song.beatsPerMS
            var newCalculatedTime = position.time + UInt(lround(durationForBeats))
            
            if newCalculatedTime > (song.duration * 1000) { self.refreshTable(single: true); return }
            
            // beats manually changed => alter next position(s) so the current one has the requested beats
            if song.getPositions().count > rowIndex+1 {
                nextPosition = song.getPositions()[rowIndex+1]
                
            } else {
                // no following position
                nextPosition = Position(name: "", comment: "", time: 0, new: true)
                song.addPosition(nextPosition)
            }
            
            nextPosition.time = newCalculatedTime
            
            // adjust all later positions as well, if no time is left for them and positions would trade places
            for (index, adjustPosition) in song.getPositions().enumerated() {
                if index < rowIndex + 1 { continue }
                
                if adjustPosition.time <= newCalculatedTime {
                    newCalculatedTime += 1
                    adjustPosition.time = newCalculatedTime
                }
            }
            
            song.calculatePositionBeats()
            
            self.refreshTable(single: true)
        }
    }
    
    func updateBeatsByMoving(rowIndex: Int, beats: Int, refresh: Bool) {
        if let song = PlayerAudioEngine.shared.song {
            let position = song.getPositions()[rowIndex]
            var nextPosition: Position?
            var nextIsNew: Bool = false
            
            let durationForBeats = Double(beats) / song.beatsPerMS
            if durationForBeats < 0 { return }
            var newCalculatedTime = position.time + UInt(lround(durationForBeats))
            
            if newCalculatedTime > (song.duration * 1000) {
                newCalculatedTime = UInt(song.duration) * 1000
            } else {
                
            }
            
            // beats manually changed => alter next position(s) so the current one has the requested beats
            if song.getPositions().count > rowIndex+1 {
                nextPosition = song.getPositions()[rowIndex+1]
            } else if newCalculatedTime < (song.duration * 1000) {
                // no following position
                nextPosition = Position(name: "", comment: "", time: 0, new: true)
                song.addPosition(nextPosition!)
                nextIsNew = true
            }
            
            if nextPosition != nil {
                nextPosition!.time = newCalculatedTime
            }
            
            if nextPosition != nil && !nextIsNew {
                updateBeatsByMoving(rowIndex: rowIndex+1, beats: nextPosition!.beats, refresh: false)
            }

            if refresh {
                song.calculatePositionBeats()
                self.refreshTable(single: true)
            }
        }
    }
}

extension PositionTableView: NSTableViewDataSource, NSTableViewDelegate {
    
    func tableViewColumnDidResize(_ notification: Notification) {
        self.positionTable.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
            let textField = cell.textField!
            textField.drawsBackground = false

            if let song = PlayerAudioEngine.shared.song {
                if song.getPositions().count <= row {
                    return nil
                }
                
                textField.backgroundColor = NSColor.controlColor
                textField.textColor       = NSColor.controlTextColor

                if !PlayerAudioEngine.shared.isStopped() {
                    if(self.currentPosition == row){
                        textField.drawsBackground = true
                        textField.backgroundColor = NSColor.systemOrange
                        textField.textColor       = NSColor.black
                    }
                }

                if(tableColumn!.identifier.rawValue == "number"){
                    textField.stringValue = "\(row + 1)"
                }else{
                    textField.stringValue = song.getPositions()[row].getValueAsString(tableColumn!.identifier.rawValue)
                }
            }else{
                textField.stringValue = ""
            }

            if AppPreferences.positionTableMonoFont {
                textField.font = NSFont.init(name: "B612-Regular", size: CGFloat(self.fontSize))
            } else {
                textField.font = NSFont.systemFont(ofSize: CGFloat(self.fontSize))
            }

            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        var heightOfRow: CGFloat = 100.0
        
        if let song = self.mainView?.playerView?.getSong() {
            
            if song.getPositions().count <= row {
                return heightOfRow
            }
            
            let string = song.getPositions()[row].getValueAsString("comment")
            if let tableColumn = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "comment")){
                let rect = NSMakeRect(0, 0, tableColumn.width, CGFLOAT_MAX)
                let textField = NSTextField()
                let cell = textField.cell!
                cell.wraps = true
                
                if AppPreferences.positionTableMonoFont {
                    cell.font = NSFont.init(name: "B612-Regular", size: CGFloat(self.fontSize))
                } else {
                    cell.font = NSFont.systemFont(ofSize: CGFloat(self.fontSize))
                }
                
                cell.stringValue = string
                let size = cell.cellSize(forBounds: rect)
                heightOfRow = size.height
            }
            
        }
        
        return heightOfRow
        
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let song = self.mainView?.playerView?.getSong() {
            return song.getPositions().count
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
        self.handlePositionSelected(self.positionTable.selectedRow)
    }
    
}
