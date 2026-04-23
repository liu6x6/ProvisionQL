//
//  ContentView.swift
//  ProvisionQL
//
//  Created by Evgeny Aleksandrov

import SwiftUI
import ProvisionQLCore


struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Button("Test APK") {
            let file = "/Users/spxt666/Downloads/Android/shizuku-v13.6.0.r1086.2650830c-release.apk"
            let url = URL(fileURLWithPath: file)
             let app = try? AppArchiveParser.parseAPK( url)

            let fileType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType

            print(app?.name)
            print(fileType)
            }
        }
        .padding()
    }


}

#Preview {
    ContentView()
}
