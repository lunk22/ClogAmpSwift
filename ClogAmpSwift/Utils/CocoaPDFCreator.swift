import Cocoa
import WebKit
import PDFKit

public func CreatePDF(htmlString: String, fileName: String = "Export") {
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
    
//    let webView = WKWebView()
//    webView.loadHTMLString(htmlString, baseURL: nil)
//    
//    delayWithSeconds(0.5) {
//        let config = WKPDFConfiguration()
//        config.rect = .init(origin: .zero, size: .init(width: 210.0, height: 297.0))
//        webView.createPDF() { result in
//            switch result {
//                case .success(let data):
//                    let pdf = PDFDocument(data: data)
//                    let printOperation = pdf?.printOperation(for: nil, scalingMode: .pageScaleToFit, autoRotate: false)
//                    printOperation?.showsPrintPanel = true
//                    printOperation?.showsProgressPanel = true
//                    printOperation?.jobTitle = fileName
//                    printOperation?.run()
//                    break
//                case .failure(_):
//                    break
//            }
//        }
//    }
    
}
