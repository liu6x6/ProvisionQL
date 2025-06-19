//
//  PreviewViewController.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import Cocoa
import ProvisionQLCore
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {
    private var hostingController: NSHostingController<ProvisioningPreviewView>?

    override func loadView() {
        let placeholderView = ProvisioningPreviewView(info: nil, fileURL: nil)

        let hostingController = NSHostingController(rootView: placeholderView)
        self.hostingController = hostingController

        view = hostingController.view
        addChild(hostingController)

        preferredContentSize = NSSize(width: 800, height: 600)
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let info = try ProvisioningParser.parse(url)

        let previewView = ProvisioningPreviewView(info: info, fileURL: url)
        hostingController?.rootView = previewView
    }
}
