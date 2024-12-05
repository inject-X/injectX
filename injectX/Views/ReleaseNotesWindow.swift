//
//  ReleaseNotesWindow.swift
//  injectX
//
//  Created by BliZzard on 2024/12/5.
//

import Foundation
import SwiftUI

// ReleaseNotesWindow 视图
struct ReleaseNotesWindow: View {
    let xmlURL = "https://raw.githubusercontent.com/inject-X/injectX/refs/heads/main/appcast.xml"
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            WebView(htmlURL: xmlURL, isLoading: $isLoading)
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .padding()
    }
}
