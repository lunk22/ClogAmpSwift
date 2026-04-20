//
//  Tools.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//

import Foundation
import Cocoa
import WebKit
import UserNotifications

// Keep a strong reference so the window isn't deallocated while open.
private var _pdfPreviewWindowController: PDFPreviewWindowController?

// Held alive during async PDF generation.
private var _pdfGenerator: MultiPagePDFGenerator?

@MainActor public func createPDF(htmlString: String, fileName: String = "Export", closure: @escaping (_ savePdfUrl: URL) -> ()) {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("pdf")

    let generator = MultiPagePDFGenerator(html: htmlString, outputURL: tempURL) { result in
        _pdfGenerator = nil
        switch result {
        case .success:
            DispatchQueue.main.async {
                let previewController = PDFPreviewWindowController(tempURL: tempURL, fileName: fileName) { savedURL in
                    closure(savedURL)
                }
                _pdfPreviewWindowController = previewController
                previewController.showWindow(nil)
            }
        case .failure:
            break
        }
    }
    _pdfGenerator = generator
    generator.generate()
}

public func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, qos: .default) {
        closure()
    }
}

// MARK: - Multi-page text PDF via WKWebView.printOperationWithPrintInfo

// WKWebView.printOperationWithPrintInfo(_:) produces a real NSPrintOperation
// that renders text as vectors — unlike NSPrintOperation(view:) which tries to
// draw the WKWebView as a generic NSView and gets blank output.

@MainActor
private class MultiPagePDFGenerator: NSObject, WKNavigationDelegate {
    private let html: String
    private let outputURL: URL
    private let completion: (Result<Void, Error>) -> Void

    private var webView: WKWebView?
    private var offscreenWindow: NSWindow?

    // A4 in points
    private let pageWidth:  CGFloat = 595
    private let pageHeight: CGFloat = 842
    private let margin:     CGFloat = 16

    init(html: String, outputURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        self.html = html
        self.outputURL = outputURL
        self.completion = completion
    }

    func generate() {
        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        wv.navigationDelegate = self
        self.webView = wv

        // Must be in a window so the web process performs real layout.
        let win = NSWindow(
            contentRect: NSRect(x: -10000, y: -10000, width: pageWidth, height: pageHeight),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.contentView = wv
        win.orderBack(nil)
        self.offscreenWindow = win

        let marginCSS = "<style>body { margin: \(Int(margin))pt; }</style>"
        wv.loadHTMLString(marginCSS + html, baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Small delay so WKWebView finishes its internal layout pass.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.runPrintOperation(webView: webView)
        }
    }

    private func runPrintOperation(webView: WKWebView) {
        let printInfo = NSPrintInfo()
        printInfo.paperSize    = NSSize(width: pageWidth, height: pageHeight)
        printInfo.topMargin    = margin
        printInfo.bottomMargin = margin
        printInfo.leftMargin   = margin
        printInfo.rightMargin  = margin
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered   = false
        printInfo.horizontalPagination   = .fit
        printInfo.verticalPagination     = .automatic
        printInfo.jobDisposition         = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = outputURL

        // WKWebView-specific API — renders actual text/vector content.
        let op = webView.printOperation(with: printInfo)
        op.showsPrintPanel    = false
        op.showsProgressPanel = false

        // op.run() must not be called on the main thread — it starts a modal
        // run loop internally and triggers EXC_BREAKPOINT if called from main.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = op.run()
            DispatchQueue.main.async {
                self?.finish(with: success ? .success(()) : .failure(NSError(domain: "PDF", code: 1)))
            }
        }
    }

    private func finish(with result: Result<Void, Error>) {
        webView?.navigationDelegate = nil
        offscreenWindow?.orderOut(nil)
        webView = nil
        offscreenWindow = nil
        completion(result)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(with: .failure(error))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(with: .failure(error))
    }
}
