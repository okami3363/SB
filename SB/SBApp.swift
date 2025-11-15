//
//  SBApp.swift
//  SB
//
//  Created by 黃崑展 on 2025/11/8.
//

import SwiftUI

@main
struct SBApp: App {
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
