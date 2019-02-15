//
//  HistoryTableView.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import AppKit

class HistoryTableView: ViewController {
    
    //Properties
    var historyItems: [SongHistoryItem]?
    
    //Outlets
    @IBOutlet weak var historyTable: TableView!
        
    //Overrides
    override func viewDidLoad() {
        
//        self.historyTable.selectionDelegate = self
        self.historyTable.delegate          = self
        self.historyTable.dataSource        = self
        
//        self.fontSize = UserDefaults.standard.integer(forKey: "positionTableFontSize")
//        if(self.fontSize == 0){
//            self.fontSize = 12
//        }

        historyItems = Database.getSongHistory(nil, to: nil) as? [SongHistoryItem]
        self.historyTable.reloadData()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 'at' h:mm a" // superset of OP's format
        let str = dateFormatter.string(from: Date())
        print(str)
        super.viewDidLoad()
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
