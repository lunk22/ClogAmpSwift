//
//  PositionTableViewController.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 31.01.19.
//

import AppKit
import WebKit
import PDFKit

class PositionTableViewController: NSViewController {
    
    //MARK: Properties
    var fontSize            = 0
    var rowHeight : CGFloat = 1.0
    var visible             = false
    var currentPosition     = -1
    
    var loopCount           = 0
    var loopPos             = -1
    var loopTimerArmedAt    = -1.0          // playback time when the loop timer was last armed
    var loopTimerArmedWallTime = Date()     // wall clock time when the loop timer was last armed

    var loopTimer: Timer?
    
    weak var mainView: MainViewController?
    
    //MARK: Outlets
    @IBOutlet weak var positionTable: TableView!
    @IBOutlet weak var loopStepper: NSStepper!
    @IBOutlet weak var lblLoopCount: NSTextField!
    @IBOutlet weak var cbAutoscroll: NSButton!
    
    //MARK: Overrides
    override func viewDidLoad() {

        self.positionTable.selectionDelegate = self
        self.positionTable.delegate          = self
        self.positionTable.dataSource        = self

        self.updateBeatsColumnVisibility()
        self.lblLoopCount.stringValue = "\(self.loopStepper.intValue)"
        self.loopStepper.frameCenterRotation = -90
        
        self.fontSize = Settings.positionTableFontSize
        
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

        NotificationCenter.default.addObserver(forName: PlayerAudioEngine.NotificationNames.stopped, object: nil, queue: nil) { _ in
            DispatchQueue.main.async(qos: .default) {
                self.currentPosition = -1
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
        beatsColumn.isHidden = !Settings.positionTableShowBeats
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

                var highlightTime = currentTime
                if Settings.highlightPositionOffset && Settings.playPositionOffsetValue != 0 {
                    switch Settings.playPositionOffset {
                    case 1: // beats
                        if song.bpm > 0 {
                            highlightTime += Double(Settings.playPositionOffsetValue * -1) * 60.0 / Double(song.bpm)
                        }
                    case 2: // seconds
                        highlightTime += Double(Settings.playPositionOffsetValue * -1)
                    default:
                        break
                    }
                }

                for position in positions {
                    if(Double(position.time / 1000) <= highlightTime){
                        currentPosition = positions.firstIndex(where: {
                            return $0 === position
                        }) ?? -1
                    }
                }
                
                if currentPosition > -1 && self.cbAutoscroll.state == NSControl.StateValue.on {
                    self.positionTable.scrollRowToVisible(row: currentPosition, animated: true)
                }
                
                if(PlayerAudioEngine.shared.isPlaying() && self.currentPosition != currentPosition){
                    if self.loopStepper.intValue > 0 {
                        // Loop is active — don't advance currentPosition, let armLoopTimer handle seeking back
                    } else {
                        self.currentPosition = currentPosition
                        performRefresh()
                    }
                }

                // Re-arm loop timer if the user seeked while looping.
                // If actual playback time differs from expected (armed time + wall time elapsed), a seek occurred.
                if self.loopStepper.intValue > 0, let timer = self.loopTimer, timer.isValid, self.loopTimerArmedAt >= 0 {
                    let wallElapsed = -self.loopTimerArmedWallTime.timeIntervalSinceNow
                    let expectedTime = self.loopTimerArmedAt + wallElapsed
                    if abs(currentTime - expectedTime) > 0.8 {
                        self.armLoopTimer(loopPos: self.loopPos, fromTime: currentTime)
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
            var seekTime = Float64(oPosition.time) / 1000.0

            if let song = PlayerAudioEngine.shared.song, Settings.playPositionOffsetValue != 0 {
                switch Settings.playPositionOffset {
                case 1: // beats
                    if song.bpm > 0 {
                        seekTime += Double(Settings.playPositionOffsetValue) * 60.0 / Double(song.bpm)
                    }
                case 2: // seconds
                    seekTime += Double(Settings.playPositionOffsetValue)
                default:
                    break
                }
                seekTime = max(0, seekTime)
            }

            PlayerAudioEngine.shared.seek(seconds: seekTime)
            if Settings.playPositionOnSelection && !(PlayerAudioEngine.shared.isPlaying()){
                PlayerAudioEngine.shared.play()
            }
        }
    }

    func armLoopTimer(loopPos: Int, fromTime: Double? = nil) {
        guard loopStepper.intValue > 0 else { return }
        guard let song = PlayerAudioEngine.shared.song else { return }

        let positions = song.getPositions()
        guard loopPos >= 0 && loopPos < positions.count else { return }

        // The looped position ends when the next position starts (or at end of song)
        let nextPosTime: Double
        if loopPos + 1 < positions.count {
            nextPosTime = Double(positions[loopPos + 1].time) / 1000.0
        } else {
            nextPosTime = PlayerAudioEngine.shared.getDuration()
        }

        // fromTime is the actual playback start point (seek target or current time after manual seek)
        // If not provided, compute it from the position + offset as normal
        let startTime: Double
        if let fromTime {
            startTime = fromTime
        } else {
            let positionTime = Double(positions[loopPos].time) / 1000.0
            var seekTime = positionTime
            if Settings.playPositionOffsetValue != 0 {
                switch Settings.playPositionOffset {
                case 1:
                    if song.bpm > 0 {
                        seekTime += Double(Settings.playPositionOffsetValue) * 60.0 / Double(song.bpm)
                    }
                case 2:
                    seekTime += Double(Settings.playPositionOffsetValue)
                default:
                    break
                }
                seekTime = max(0, seekTime)
            }
            startTime = seekTime
        }

        // Timer fires when remaining position duration + loopDelay has elapsed
        let loopInterval = max(0, nextPosTime - startTime) + Settings.loopDelay

        self.loopPos = loopPos
        self.loopTimerArmedAt = startTime
        self.loopTimerArmedWallTime = Date()

        loopTimer?.invalidate()
        loopTimer = Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: false) { [weak self] _ in
            guard let self, self.loopStepper.intValue > 0, PlayerAudioEngine.shared.isPlaying() else { return }

            self.loopCount += 1
            self.handlePositionSelected(loopPos)
            self.armLoopTimer(loopPos: loopPos)

            if self.loopCount >= Int(self.loopStepper.intValue) {
                self.loopStepper.intValue = 0
                self.lblLoopCount.stringValue = "0"
                self.loopTimer?.invalidate()
                self.loopTimer = nil
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
        self.armLoopTimer(loopPos: self.positionTable.selectedRow)
    }
    
    @IBAction func handleAddPosition(_ sender: NSButton) {
        if let song = PlayerAudioEngine.shared.song {
            var currentTime = PlayerAudioEngine.shared.getCurrentTime() //Seconds

            switch Settings.addPositionBehavior {
                case 1: // Adjust by beats
                    if song.bpm > 0 {
                        let secPerBeat = Double(60)/Double(song.bpm)
                        let offset = secPerBeat * Double(Settings.addPositionOffset)
                        currentTime += offset
                    }
                    break
                case 2: // Adjust by seconds
                    currentTime += Double(Settings.addPositionOffset)
                    break
                default: // No adjustments
                    currentTime = currentTime * 1
            }
            
            if currentTime < 0 {
                currentTime = 0
            }

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
        openDialog.title = NSLocalizedString("importPositions", bundle: Bundle.main, comment: "")
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
            saveDialog.title = NSLocalizedString("exportPositions", bundle: Bundle.main, comment: "")
            saveDialog.showsResizeIndicator    = true
            saveDialog.showsHiddenFiles        = false
            saveDialog.canCreateDirectories    = true
            saveDialog.allowedContentTypes     = [.init(filenameExtension: "infoexport")!]
            saveDialog.allowsOtherFileTypes    = false
            saveDialog.nameFieldStringValue    = song.title
            
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

                try? xmlData.write(to: saveDialog.url!)
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
                    if PlayerAudioEngine.shared.song?.bpm == 0 { self.refreshTable(single: true); return } // Song has no BPM. Reset
                    if !text.isInteger() || text.asInteger() < 0 { self.refreshTable(single: true); return } // not an int or negative int? just refresh to get the old value
                    if text.asInteger() == position.beats { return } // no change?
                    
                    switch Settings.beatsChangeBehavior {
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
    
    @IBAction func handleLoopStepperChanged(_ sender: NSStepper) {
        self.loopCount = 0
        self.loopTimerArmedAt = -1.0
        self.loopTimer?.invalidate()
        self.loopTimer = nil
        self.lblLoopCount.stringValue = "\(sender.intValue)"
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

            let font          = Settings.pdfFontFamily
            let titleSize     = Settings.pdfTitleSize
            let artistSize    = Settings.pdfArtistSize
            let subheaderSize = Settings.pdfSubheaderSize
            let nameSize      = Settings.pdfPositionNameSize
            let commentSize   = Settings.pdfCommentSize
            let cellPadding   = Settings.pdfCellPadding
            let headerSpacing = "<div style='display: block; margin-bottom: \(Settings.pdfHeaderSpacing)rem'></div>"

            var sPdfHtml        = ""
            sPdfHtml = sPdfHtml + "<style>"
            sPdfHtml = sPdfHtml + "  div { display:inline; font-family: '\(font)'; }"
            sPdfHtml = sPdfHtml + "  table, td { font-family: '\(font)'; border: 0px solid black; border-collapse: collapse; }"
            sPdfHtml = sPdfHtml + "  td { padding: \(cellPadding)rem; vertical-align: top; }"
            sPdfHtml = sPdfHtml + "  .center {  display: table; margin-right: auto; margin-left: auto; }"
            sPdfHtml = sPdfHtml + "  .bold {  font-weight: bold; }"
            sPdfHtml = sPdfHtml + "  .nowrap {  white-space: nowrap; }"
            sPdfHtml = sPdfHtml + "</style>"

            sPdfHtml = sPdfHtml + "<div class='center'>"
            sPdfHtml = sPdfHtml + "  <div style='font-size: \(titleSize)rem'>\(song.title)</div>&nbsp;<div style='font-size: \(artistSize)rem'>\(song.artist)</div>"
            sPdfHtml = sPdfHtml + "</div>"
            sPdfHtml = sPdfHtml + "<div class='center' style='font-size: \(subheaderSize)rem'>"
            sPdfHtml = sPdfHtml + "  \(song.getValueAsString("duration"))"

            if song.getValueAsString("level") != "" {
                sPdfHtml = sPdfHtml + " &ndash; \(song.level)"
            }

            if sWait != "" {
                sPdfHtml = sPdfHtml + " &ndash; \(sWait)"
            }

            sPdfHtml = sPdfHtml + "</div>"
            sPdfHtml = sPdfHtml + headerSpacing

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
                comment = comment.replacingOccurrences(of: "\n", with: "<br/>")

                sPdfHtml = sPdfHtml + "    <tr>"
                sPdfHtml = sPdfHtml + "      <td class='bold nowrap' style='font-size: \(nameSize)rem'>\(position.name)</td>"
                sPdfHtml = sPdfHtml + "      <td style='font-size: \(commentSize)rem'>\(comment)</td>"
                sPdfHtml = sPdfHtml + "    </tr>"
            }

            sPdfHtml = sPdfHtml + " </table>"

            let suggestedName = song.title.isEmpty ? song.getValueAsString("fileName") : song.title
            createPDF(htmlString: sPdfHtml, fileName: suggestedName) { _ in }
        }
    }
    
//    func previewPdf(_ url: URL) {
//        // create an empty view controller
//        let controller = NSViewController()
//        controller.view = NSView(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(600), height: CGFloat(750)))
//        
//        let popover = NSPopover()
//        popover.contentViewController = controller
//        popover.contentSize = controller.view.frame.size
//        
//        popover.behavior = .transient
//        popover.animates = true
//        
//        let pdfDocument = PDFDocument(url: url)
//        let pdfView = PDFView(frame: controller.view.frame)
//        pdfView.document = pdfDocument
//        pdfView.autoScales = true
//        
//        
//        controller.view.addSubview(pdfView)
//        popover.show(relativeTo: self.view.bounds, of: self.view, preferredEdge: NSRectEdge.maxY)
//    }
    
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

extension PositionTableViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func tableViewColumnDidResize(_ notification: Notification) {
        self.positionTable.sizeLastColumnToFit()
        self.positionTable.reloadData()
    }
    
    func tableView(_ tableView: NSTableView, sizeToFitWidthOfColumn column: Int) -> CGFloat {
        func dermineMaxWidth(for column: String) -> CGFloat {
            if let song = PlayerAudioEngine.shared.song {
                if song.getPositions().count > 0 {
                    var maxLength: CGFloat = 0.0
                    song.getPositions().forEach { position in
                        let rect = NSMakeRect(0, 0, CGFLOAT_MAX, CGFLOAT_MAX)
                        let cell = NSCell()
                        
                        cell.wraps = false
                        
                        if Settings.positionTableMonoFont {
                            cell.font = NSFont.init(name: Settings.monoFontName, size: CGFloat(self.fontSize))
                        } else {
                            cell.font = NSFont(name: Settings.proportionalFontName, size: CGFloat(self.fontSize)) ?? NSFont.systemFont(ofSize: CGFloat(self.fontSize))
                        }
                        
                        cell.stringValue = position.getValueAsString(column)
                        let size = cell.cellSize(forBounds: rect)
                        
                        if size.width > maxLength {
                            maxLength = size.width
                        }
                    }
                    return maxLength
                }
            }
            
            return 0.0
        }
        var maxWidth = 0.0
        switch tableView.tableColumns[column].identifier.rawValue {
            case "beats":
                // Beats are center aligned, so a little more extra space is needed since it's shared before and after the value
                maxWidth = dermineMaxWidth(for: tableView.tableColumns[column].identifier.rawValue) * 1.3
            default:
                // Add 10% to not glue them together
                maxWidth = dermineMaxWidth(for: tableView.tableColumns[column].identifier.rawValue) * 1.075
        }
        
        return maxWidth
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

                if Settings.positionHighlight && !PlayerAudioEngine.shared.isStopped() {
                    if(self.currentPosition == row){
                        if(!Settings.positionHighlightTextOnly) {
                            textField.drawsBackground = true
                            textField.backgroundColor = Settings.positionHighlightColor
                        }
                        textField.textColor = Settings.positionTextColor
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

            if Settings.positionTableMonoFont {
                textField.font = NSFont.init(name: Settings.monoFontName, size: CGFloat(self.fontSize))
            } else {
                textField.font = NSFont(name: Settings.proportionalFontName, size: CGFloat(self.fontSize)) ?? NSFont.systemFont(ofSize: CGFloat(self.fontSize))
            }

            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let font: NSFont
        if Settings.positionTableMonoFont {
            font = NSFont(name: Settings.monoFontName, size: CGFloat(self.fontSize))
                ?? NSFont.monospacedSystemFont(ofSize: CGFloat(self.fontSize), weight: .regular)
        } else {
            font = NSFont(name: Settings.proportionalFontName, size: CGFloat(self.fontSize))
                ?? NSFont.systemFont(ofSize: CGFloat(self.fontSize))
        }
        let lineHeight = font.boundingRectForFont.height.rounded(.up)

        guard let song = self.mainView?.playerView?.getSong(), row < song.getPositions().count,
              let column = tableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("comment")),
              column.width > 0 else {
            return lineHeight + 3
        }

        let position = song.getPositions()[row]
        let comment = position.getValueAsString("comment")
        let measure = comment.isEmpty ? position.getValueAsString("time") : comment
        let attrString = NSAttributedString(string: measure, attributes: [.font: font])
        let bounds = attrString.boundingRect(
            with: NSSize(width: column.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        return bounds.height.rounded(.up) + 3
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

extension PositionTableViewController: TableViewDelegate {
    
    func rowSelected() {
        self.handlePositionSelected(self.positionTable.selectedRow)
    }
    
    func rightClicked() {
        // Do nothing
    }
    
}
