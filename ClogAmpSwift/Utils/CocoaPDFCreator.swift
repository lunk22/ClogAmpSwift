import Cocoa
import WebKit
import PDFKit

public func CreatePDF(htmlString: String, fileName: String = "Export") {
//////// OLD
    DispatchQueue.main.async {
            let webView = WebView()
            webView.mainFrame.loadHTMLString(htmlString, baseURL: nil)
            delayWithSeconds(0.1) {
                let printOpts: [NSPrintInfo.AttributeKey : AnyObject] = [NSPrintInfo.AttributeKey.jobDisposition : NSPrintInfo.JobDisposition.preview as AnyObject]
                let printInfo: NSPrintInfo = NSPrintInfo(dictionary: printOpts)
                printInfo.paperSize = NSMakeSize(595, 842)
                printInfo.topMargin = 10.0
                printInfo.leftMargin = 10.0
                printInfo.rightMargin = 10.0
                printInfo.bottomMargin = 10.0
                let printOp: NSPrintOperation = NSPrintOperation(view: webView.mainFrame.frameView.documentView, printInfo: printInfo)
                printOp.showsPrintPanel = true
                printOp.showsProgressPanel = true
                printOp.jobTitle = fileName
                printOp.run()
            }

    }

////////// NEW
//////    let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
////    let printOpts: [NSPrintInfo.AttributeKey: Any] = [
//////        NSPrintInfo.AttributeKey.jobDisposition: NSPrintInfo.JobDisposition.save,
//////        NSPrintInfo.AttributeKey.jobSavingURL: directoryURL
////    ]
//    let printInfo = NSPrintInfo(/*dictionary: printOpts*/)
////    printInfo.horizontalPagination = NSPrintInfo.PaginationMode.automatic
////    printInfo.verticalPagination = NSPrintInfo.PaginationMode.automatic
//    printInfo.topMargin = 0.0
//    printInfo.leftMargin = 0.0
//    printInfo.rightMargin = 0.0
//    printInfo.bottomMargin = 0.0
//    
//    let pageWidth = 595.2 - 30
//    let pageHeight = 841.8 - 30
////    NSAttributedString.DocumentReadingOptionKey()
//    let view = NSView(frame: NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
////    let unescapedHtml = htmlString.replacingOccurrences(of: "\'", with: "'")
//    if let htmlData = htmlString.replacingOccurrences(of: "\'", with: "'").data(using: String.Encoding.utf8) {
//        if let attrStr = NSAttributedString(
//            html: htmlData,
//            options: [.documentType: NSAttributedString.DocumentType.html],
//            documentAttributes: nil)
//        {
//            let frameRect = NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
//            let textField = NSTextField(frame: frameRect)
//            textField.attributedStringValue = attrStr
//            view.addSubview(textField)
//            
//            let printOperation = NSPrintOperation(view: view, printInfo: printInfo)
//            printOperation.showsPrintPanel = true
//            printOperation.showsProgressPanel = false
//            printOperation.run()
//        }
//    }
}
