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
            Button("Parse APK") {
               let file = "/Users/spxt666/Downloads/Android/shizuku-v13.6.0.r1086.2650830c-release.apk"
               let url = URL(fileURLWithPath: file)
               if let app = try? AppArchiveParser.parse(url) {
                   print("Version: \(app.version)")
                   print("Build: \(app.buildNumber)")
               }
            }
        }
        .padding()
    }


}

#Preview {
    ContentView()
}
