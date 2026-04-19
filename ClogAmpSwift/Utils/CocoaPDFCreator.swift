import Cocoa
import WebKit

public func CreatePDF(htmlString: String, fileName: String = "Export") {
    let webView = WebView()
    webView.mainFrame.loadHTMLString(htmlString, baseURL: nil)
    let when = DispatchTime.now() + 1
    DispatchQueue.main.asyncAfter(deadline: when) {
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
