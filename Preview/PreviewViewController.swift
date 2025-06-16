//
//  PreviewViewController.swift
//  Preview
//
//  Created by Evgeny Aleksandrov

import Cocoa
import Quartz
import SwiftUI

struct PreviewContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text("Provisioning Profile")
                .font(.largeTitle)
                .fontWeight(.semibold)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    private var hostingController: NSHostingController<PreviewContentView>?

    override func loadView() {
        let contentView = PreviewContentView()
        let hostingController = NSHostingController(rootView: contentView)
        self.hostingController = hostingController

        view = hostingController.view
        addChild(hostingController)

        preferredContentSize = NSSize(width: 400, height: 300)
    }

    func preparePreviewOfFile(at url: URL) async throws {
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.

        // Perform any setup necessary in order to prepare the view.

        // Quick Look will display a loading spinner until this returns.
    }
}
