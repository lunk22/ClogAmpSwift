//
//  PositionXmlParser.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 19.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

import Foundation

class PositionXmlParser : NSObject {
    
    var currentElement: String = ""
    var name: String = ""
    var comment: String = ""
    var jump: String = ""
    var time: String = ""
    
    var position: Position?
    
    var song: Song?
}

extension PositionXmlParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        self.currentElement = elementName
        
        if elementName == "position" {
            self.position = nil
            self.position = Position()
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if string.contains("\n"){
            return
        }
        
        switch self.currentElement {
        case "name":
            self.position?.name = "\(self.position?.name ?? "")\(string)"
        case "comment":
            self.position?.comment = "\(self.position?.comment ?? "")\(string)"
        case "jump":
            self.position?.jumpTo = string
        case "milliseconds":
            if(Int(string)! > 0){
                self.position?.time = UInt(string)!
            } else {
                self.position?.time = 0
            }
        default:
            return
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "position" {
            self.song?.addPosition(self.position!)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        //...
    }
    
}
