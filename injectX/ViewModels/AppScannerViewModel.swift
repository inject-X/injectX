//
//  AppScannerViewModel.swift
//  injectX
//
//  Created by injectX on 2024/10/30.
//

import SwiftUI

@MainActor
class AppScannerViewModel: ObservableObject {
    @Published private(set) var apps: [AppInfo] = []
    @Published var searchText: String = ""
    @Published var isScanning = false
    @Published var selectedAppId: UUID?
    
    var selectedApp: AppInfo? {
        guard let selectedAppId = selectedAppId else { return nil }
        return apps.first { $0.id == selectedAppId }
    }
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func scanApps() {
        Task {
            await MainActor.run {
                        self.isScanning = true
                    }
            var newApps: [AppInfo] = []
            
            let fileManager = FileManager.default
            let applicationPaths = [
                "/Applications",
            ]
            
            for path in applicationPaths {
                guard let contents = try? fileManager.contentsOfDirectory(
                    at: URL(fileURLWithPath: path),
                    includingPropertiesForKeys: nil
                ) else { continue }
                
                let appURLs = contents.filter { $0.pathExtension == "app" }
                
                for url in appURLs {
                    if let appInfo = await loadAppInfo(from: url) {
                        newApps.append(appInfo)
                    }
                }
            }
            
            newApps.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            
            await MainActor.run {
                self.apps = newApps
                self.isScanning = false
            }
        }
    }
    
    private func loadAppInfo(from url: URL) async -> AppInfo? {
        guard let bundle = Bundle(url: url),
              let bundleIdentifier = bundle.bundleIdentifier,
              let bundleShortVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
              let bundleVersion = bundle.infoDictionary?["CFBundleVersion"] as? String
        else { return nil }
        
        let name = getLocalizedName(for: bundle)
//        var injected = false
        var canInject = false
        var supportVersion: String?
        var supportArch: [String]?
        var source: String?
//        var license: String?
        
        let injectHelper = InjectHelper()
        
        if let config = injectHelper.getConfig() {
            if let appConfig = config[bundleIdentifier] {
                canInject = injectHelper.canInject(bundleIdentifier, bundleShortVersion, bundleVersion)
                supportVersion = ((appConfig["bundleShortVersion"] as? String) ?? "") + " (" + ((appConfig["bundleVersion"] as? String) ?? "") + ")"
                supportArch = appConfig["arch"] as? [String]
                source = appConfig["source"] as? String
//                license = appConfig["license"] as? String
            } else {
                return nil
            }
        }
        
        let injected = injectHelper.injected(bundleIdentifier, url)
        InjectionStateManager.shared.setInjected(
            bundleId: bundleIdentifier,
            injected: injected
        )
        
        return AppInfo(
            name: name,
            bundleShortVersion: bundleShortVersion,
            bundleVersion: bundleVersion,
            bundleIdentifier: bundleIdentifier,
            path: url.path,
//            injected: injected,
            canInject: canInject,
            supportVersion: supportVersion ?? "",
            supportArch: supportArch ?? [],
            source: source ?? ""
//            license: license ?? ""
        )
    }
    
    private func getLocalizedName(for bundle: Bundle) -> String {
        let preferredLanguages = Bundle.main.preferredLocalizations
        
        for language in preferredLanguages {
            if let localizedInfoPlistPath = bundle.path(forResource: "InfoPlist", ofType: "strings", inDirectory: nil, forLocalization: language),
               let localizedDict = NSDictionary(contentsOfFile: localizedInfoPlistPath) as? [String: String] {
                if let localizedName = localizedDict["CFBundleDisplayName"] ?? localizedDict["CFBundleName"] {
                    return localizedName
                }
            }
        }
        
        if let infoPlistPath = bundle.url(forResource: "Info", withExtension: "plist"),
           let infoDictionary = NSDictionary(contentsOf: infoPlistPath) as? [String: Any] {
            if let displayName = infoDictionary["CFBundleDisplayName"] as? String {
                return displayName
            } else if let bundleName = infoDictionary["CFBundleName"] as? String {
                return bundleName
            }
        }
        
        let fallbackName = bundle.bundleURL.deletingPathExtension().lastPathComponent
        return fallbackName
    }
}
