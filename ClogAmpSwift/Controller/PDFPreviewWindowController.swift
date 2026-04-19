//
//  PDFPreviewWindowController.swift
//  ClogAmpSwift
//

import AppKit
import PDFKit
import UserNotifications

class PDFPreviewWindowController: NSWindowController {

    private let tempURL: URL
    private let fileName: String
    private let onSave: (URL) -> Void

    init(tempURL: URL, fileName: String, onSave: @escaping (URL) -> Void) {
        self.tempURL = tempURL
        self.fileName = fileName
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 900),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileName
        window.center()

        super.init(window: window)

        buildUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    private func buildUI() {
        guard let window = self.window else { return }

        let pdfView = PDFView(frame: .zero)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.autoScales = true
        if let doc = PDFDocument(url: tempURL) {
            pdfView.document = doc
            if let firstPage = doc.page(at: 0) {
                pdfView.go(to: CGRect(x: 0, y: Int.max, width: 0, height: 0), on: firstPage)
            }
        }

        let saveButton = NSButton(title: "Save…", target: self, action: #selector(handleSave))
        saveButton.keyEquivalent = "\r"
        let closeButton = NSButton(title: "Close", target: self, action: #selector(handleClose))

        let buttonStack = NSStackView(views: [closeButton, saveButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pdfView)
        container.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            buttonStack.topAnchor.constraint(equalTo: pdfView.bottomAnchor, constant: 8),
            buttonStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        window.contentView = container
    }

    @objc private func handleSave() {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = fileName

        guard let window = self.window else { return }
        savePanel.beginSheetModal(for: window) { [weak self] result in
            guard let self = self, result == .OK, let destURL = savePanel.url else { return }
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: self.tempURL, to: destURL)
            } catch {
                let alert = NSAlert(error: error)
                alert.beginSheetModal(for: window)
                return
            }

            Task {
                let allowed = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                if allowed == true {
                    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    let content = UNMutableNotificationContent()
                    content.body = "\(self.fileName).pdf successfully created"
                    content.sound = .default
                    content.userInfo = ["pdfPath": destURL.path]
                    let request = UNNotificationRequest(identifier: "ClogAmpMac", content: content, trigger: nil)
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                    try? await UNUserNotificationCenter.current().add(request)
                }
                await MainActor.run {
                    self.onSave(destURL)
                    self.close()
                }
            }
        }
    }

    @objc private func handleClose() {
        close()
    }

    override func close() {
        try? FileManager.default.removeItem(at: tempURL)
        super.close()
    }
}
