import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let targetURL = URL(string: "https://www.ero-labs.com/zh/cloud_game.html?id=47&connect_type=1&connection_id=28")!

    var navBackground: Color {
        colorScheme == .dark ? .black : Color(.systemGray6)
    }

    var refreshButtonColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        VStack(spacing: 0) {
            // 自訂 Nav 區塊
            HStack {
                Text("")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button(action: {
                    // 刷新：若已有頁面則 reload，否則載入 targetURL
                    let webView = SharedWebViewProvider.shared.webView
                    if webView.url != nil {
                        webView.reload()
                    } else {
                        let request = URLRequest(url: targetURL)
                        SharedWebViewProvider.shared.webView.load(request)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding()
                        .foregroundColor(refreshButtonColor)
                }
                .padding(.trailing, 0)
            }
            .frame(height: 56)
            .background(navBackground)

            // WebView 內容 + 底部覆蓋層（更明確貼齊螢幕底部）
            ZStack {
                WebView(url: targetURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)

                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                        .frame(height: 81)
                        .frame(maxWidth: .infinity)
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .onAppear {
            // 預載以加速首屏
            let request = URLRequest(url: targetURL)
            SharedWebViewProvider.shared.webView.load(request)
        }
        // 不加任何 ignoresSafeArea，畫面會自動依附安全範圍
    }
}

#Preview {
    ContentView()
}

