//
//  SBApp.swift
//  SB
//
//  Created by 黃崑展 on 2025/11/8.
//

import SwiftUI

@main
struct SBApp: App {

    init() {
        // DNS 預解析：App 啟動時提前解析遊戲伺服器網域
        prefetchDNS(hosts: ["www.ero-labs.com"])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 全域：App 使用期間防止裝置進入待機
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    // 恢復待機行為（App 結束或視窗關閉時）
                    UIApplication.shared.isIdleTimerDisabled = false
                }
        }
    }
}

/// 透過建立臨時連線觸發系統 DNS 快取
private func prefetchDNS(hosts: [String]) {
    for host in hosts {
        let url = URL(string: "https://\(host)")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
}
