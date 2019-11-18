//
//  HistoryTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit
import PDFKit

class HistoryTableView: ViewController {
    
    //Properties
    var historyItems: [SongHistoryItem]?
    
    //Outlets
    @IBOutlet weak var historyTable: TableView!
    
    //Actions
    @IBAction func printList(_ sender: Any) {
        self.createPDF()
    }
    
    //Overrides
    override func viewDidLoad() {

        self.historyTable.delegate          = self
        self.historyTable.dataSource        = self

        historyItems = Database.getSongHistory(nil, to: nil) as? [SongHistoryItem]
        self.historyTable.reloadData()
        
        super.viewDidLoad()
    }
    
    func createPDF() {
        if self.historyTable.selectedRow < 0 { return }
        
        let header1 = NSLocalizedString("songTitle", bundle: Bundle.main, comment: "") as NSString as String
        let header2 = NSLocalizedString("songArtist", bundle: Bundle.main, comment: "") as NSString as String
        let header3 = NSLocalizedString("songDate", bundle: Bundle.main, comment: "") as NSString as String
        
        var sPdfHtml        = ""
        sPdfHtml = sPdfHtml + "<style>"
        sPdfHtml = sPdfHtml + " th { text-align: left; }"
        sPdfHtml = sPdfHtml + " table, th, td { border: 1px solid black; border-collapse: collapse; }"
        sPdfHtml = sPdfHtml + "</style>"
        sPdfHtml = sPdfHtml + "<br/>"
        sPdfHtml = sPdfHtml + "<br/>"
        sPdfHtml = sPdfHtml + "<br/>"
        sPdfHtml = sPdfHtml + "<br/>"
        sPdfHtml = sPdfHtml + "<br/>"
        sPdfHtml = sPdfHtml + "<table style=\"width:100%\">"
        sPdfHtml = sPdfHtml + " <tr>"
        sPdfHtml = sPdfHtml + "     <th>\(header1)</th>"
        sPdfHtml = sPdfHtml + "     <th>\(header2)</th>"
        sPdfHtml = sPdfHtml + "     <th>\(header3)</th>"
        sPdfHtml = sPdfHtml + " </tr>"
        
        for index in self.historyTable.selectedRowIndexes {
            if self.historyItems != nil && self.historyItems!.count > index {
                sPdfHtml = sPdfHtml + " <tr>"
                sPdfHtml = sPdfHtml + "     <td>\(self.historyItems![index].title ?? "")</td>"
                sPdfHtml = sPdfHtml + "     <td>\(self.historyItems![index].artist ?? "")</td>"
                sPdfHtml = sPdfHtml + "     <td>\(self.historyItems![index].date ?? "")</td>"
                sPdfHtml = sPdfHtml + " </tr>"
            }
        }
        sPdfHtml = sPdfHtml + "</table>"
        
        CreatePDF(htmlString: sPdfHtml)
    }
}

extension HistoryTableView: NSTableViewDelegate, NSTableViewDataSource {

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let cell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as? NSTableCellView {
        
            let textField = cell.textField!
            
            switch tableColumn!.identifier.rawValue {
                case "title":
                    textField.stringValue = self.historyItems?[row].title ?? ""
                case "artist":
                    textField.stringValue = self.historyItems?[row].artist ?? ""
                case "file":
                    textField.stringValue = self.historyItems?[row].file ?? ""
                case "date":
                    textField.stringValue = self.historyItems?[row].date ?? ""
                default:
                    textField.stringValue = ""
            }
            
            return cell
        }
        
        return nil
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.historyItems?.count ?? 0
    }
    
}
