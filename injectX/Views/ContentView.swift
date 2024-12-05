//
//  ContentView.swift
//  injectX
//
//  Created by injectX on 2024/10/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppScannerViewModel()
    @State private var leftPanelWidth: CGFloat = 280
    @State private var showRootPasswordWindow = false
    @State private var hasRootPassword = false
    
    let passwordManager = PasswordManager()
    
    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        
                        TextField("Search Apps", text: $viewModel.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    
                    HStack(spacing: 8) {
                        Button(action: { viewModel.scanApps() }) {
                            Image(systemName: "arrow.clockwise")
                                .frame(width: 16, height: 16)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.isScanning)
                        
                        Button(action: {
                            if hasRootPassword {
                                showRootPasswordWindow = true
                            } else {
                                showRootPasswordWindow.toggle()
                            }
                        }) {
                            Image(systemName: hasRootPassword ? "lock.open" : "lock.fill")
                                .frame(width: 16, height: 16)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
                
                List(selection: $viewModel.selectedAppId) {
                    if viewModel.isScanning {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.0)
                                    .controlSize(.regular)
                                Text("Scanning Applications...")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 13))
                            }
                            .padding(.vertical, 300)  // 通过增加垂直内边距来调整位置
                            Spacer()
                        }
                    } else {
                        ForEach(viewModel.filteredApps) { app in
                            AppInfoRowView(app: app)
                                .tag(app.id)
                        }
                    }
                }
            }
            .frame(width: leftPanelWidth)
            .background(Color(NSColor.windowBackgroundColor))
            
            Group {
                if let selectedApp = viewModel.selectedApp {
                    AppDetailView(app: selectedApp, hasRootPassword: $hasRootPassword)
                } else {
                    AppHomePageView()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 1050, height: 800)
        .onAppear {
            viewModel.scanApps()
            
            if passwordManager.getPassword(forKey: "Admin") == nil {
                showRootPasswordWindow = true
                hasRootPassword = false
            } else {
                hasRootPassword = true
            }
        }
        .sheet(isPresented: $showRootPasswordWindow) {
            PasswordView {
                hasRootPassword = true
            }
        }
    }
}
