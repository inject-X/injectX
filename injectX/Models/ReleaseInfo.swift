//
//  ReleaseInfo.swift
//  injectX
//
//  Created by BliZzard on 2024/12/5.
//

import Foundation

// 创建一个结构体来保存版本信息
struct ReleaseInfo: Identifiable {
    let id = UUID()
    let version: String
    let shortVersion: String
    let date: String
    let description: String
}
