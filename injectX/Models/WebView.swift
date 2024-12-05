//
//  WebView.swift
//  injectX
//
//  Created by BliZzard on 2024/12/5.
//

import Foundation
import WebKit
import SwiftUI

// WebView 实现
struct WebView: NSViewRepresentable {
    var htmlURL: String
    @Binding var isLoading: Bool
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        loadAndParseXML(webView)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
    
    // 添加一个日期格式化的辅助函数
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z" // 解析原始格式
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter.string(from: date)
        }
        return dateString // 如果解析失败，返回原始字符串
    }

    private func loadAndParseXML(_ webView: WKWebView) {
        guard let url = URL(string: htmlURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            
            var releases: [ReleaseInfo] = []
            
            do {
                let xmlDoc = try XMLDocument(data: data, options: .documentTidyXML)
                if let items = try xmlDoc.nodes(forXPath: "//item") as? [XMLElement] {
                    for item in items {
                        let version = item.elements(forName: "sparkle:version").first?.stringValue ?? ""
                        let shortVersion = item.elements(forName: "sparkle:shortVersionString").first?.stringValue ?? ""
                        let dateString = item.elements(forName: "pubDate").first?.stringValue ?? ""
                        let description = item.elements(forName: "description").first?.stringValue ?? ""
                        
                        // 格式化日期
                        let formattedDate = formatDate(dateString)
                        
                        // 清理描述中的 CDATA 和 HTML 标签
                        let cleanDescription = description
                            .replacingOccurrences(of: "<![CDATA[", with: "")
                            .replacingOccurrences(of: "]]>", with: "")
                        
                        releases.append(ReleaseInfo(
                            version: version,
                            shortVersion: shortVersion,
                            date: formattedDate, // 使用格式化后的日期
                            description: cleanDescription
                        ))
                    }
                    
                    // 生成 HTML
                    let html = formatReleasesToHTML(releases)
                    
                    DispatchQueue.main.async {
                        webView.loadHTMLString(html, baseURL: nil)
                    }
                }
            } catch {
                print("Error parsing XML: \(error)")
                DispatchQueue.main.async {
                    let errorHTML = """
                    <!DOCTYPE html>
                    <html>
                    <body>
                        <h1>Error loading release notes</h1>
                        <p>Failed to load or parse the release notes. Please try again later.</p>
                    </body>
                    </html>
                    """
                    webView.loadHTMLString(errorHTML, baseURL: nil)
                }
            }
        }.resume()
    }

    private func formatReleasesToHTML(_ releases: [ReleaseInfo]) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    margin: 0;
                    padding: 30px;
                    background-color: #f8f9fa;
                    color: #2c3e50;
                }
                
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                }
                
                .release {
                    background-color: white;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.05);
                    margin-bottom: 25px;
                    padding: 25px;
                    transition: transform 0.2s ease;
                }
                
                .release:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                }
                
                .version {
                    font-size: 24px;
                    font-weight: 600;
                    color: #1a73e8;
                    margin-bottom: 8px;
                }
                
                .date {
                    color: #666;
                    font-size: 14px;
                    margin-bottom: 15px;
                    padding-bottom: 15px;
                    border-bottom: 1px solid #eee;
                }
                
                .description {
                    color: #444;
                    font-size: 15px;
                    line-height: 1.7;
                }
                
                ul {
                    margin: 15px 0;
                    padding-left: 20px;
                }
                
                li {
                    margin: 8px 0;
                    position: relative;
                }
                
                li::before {
                    content: '•';
                    color: #1a73e8;
                    font-weight: bold;
                    position: absolute;
                    left: -15px;
                }
                
                code {
                    background-color: #f6f8fa;
                    border-radius: 4px;
                    padding: 2px 6px;
                    font-family: Monaco, monospace;
                    font-size: 0.9em;
                }
                
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #1a1a1a;
                        color: #e0e0e0;
                    }
                    
                    .release {
                        background-color: #2d2d2d;
                        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
                    }
                    
                    .version {
                        color: #4a9eff;
                    }
                    
                    .date {
                        color: #999;
                        border-bottom-color: #444;
                    }
                    
                    .description {
                        color: #ccc;
                    }
                    
                    code {
                        background-color: #333;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                \(releases.map { release in """
                    <div class="release">
                        <div class="version">Version \(release.shortVersion) (\(release.version))</div>
                        <div class="date">\(release.date)</div>
                        <div class="description">\(release.description)</div>
                    </div>
                """
                }.joined(separator: "\n"))
            </div>
        </body>
        </html>
        """
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}
