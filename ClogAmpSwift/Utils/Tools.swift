//
//  Tools.swift
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//

import Foundation
import Cocoa
import HtmlToPdf
import UserNotifications
//import CryptoKit

// Keep a strong reference so the window isn't deallocated while open.
private var _pdfPreviewWindowController: PDFPreviewWindowController?

public func createPDF(htmlString: String, fileName: String = "Export", closure: @escaping (_ savePdfUrl: URL) -> ()) {
    Task {
        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("pdf")
            try await htmlString.print(to: tempURL)

            await MainActor.run {
                let previewController = PDFPreviewWindowController(tempURL: tempURL, fileName: fileName) { savedURL in
                    closure(savedURL)
                }
                _pdfPreviewWindowController = previewController
                previewController.showWindow(nil)
            }
        } catch {
            // generation failed — nothing to show
        }
    }
}

public func delayWithSeconds(_ seconds: Double, closure: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, qos: .default) {
        closure()
    }
}
