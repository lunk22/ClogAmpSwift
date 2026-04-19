//
//  ViewController.swift
//  ClogAmpSwift
//
//  Created by Pascal Roessel on 12.04.18.
//  Copyright © 2018 Pascal Roessel. All rights reserved.
//

import AppKit

class MainView: NSViewController {
    
    var aSongs = [Song]()
    
    weak var playerDelegate: PlayerDelegate?
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.aSongs = FileSystemUtils.readFolderContentsAsSong(sPath: "/Users/pascal/Clogging/musik")
        self.sortSongs(by: "title")
        
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear() {
        self.playerDelegate = self.childViewControllers[0] as! PlayerView
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func sortSongs(by: String){
        self.aSongs.sort(by: { $0.getValueAsString(by).uppercased() < $1.getValueAsString(by).uppercased() })
    }
    
    //UI Selectors
    @IBAction func songSelected(_ sender: NSTableView) {
        if sender.selectedRow >= 0 {
            self.playerDelegate?.loadSong(song: aSongs[sender.selectedRow])
        }
    }
    
}

extension MainView: NSTableViewDelegate, NSTableViewDataSource {
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let value = self.aSongs[row].getValueAsString(tableColumn!.identifier.rawValue)
        return value
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.aSongs.count
    }
}
