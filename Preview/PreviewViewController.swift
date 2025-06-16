//
//  PreviewViewController.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {

    override func loadView() {
        let view = NSView()
        view.wantsLayer = true

        let label = NSTextField(labelWithString: "Hello World")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 24)
        label.textColor = .labelColor
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        self.view = view
    }

    func preparePreviewOfFile(at url: URL) async throws {
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

        // Perform any setup necessary in order to prepare the view.

        // Quick Look will display a loading spinner until this returns.
    }
}
