import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isKeyboardVisible = false
    @State private var loadError = false

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
                    // 置頂：將頁面捲動到最上方
                    let js = """
                    window.scrollTo(0, 0);
                    document.documentElement.scrollTop = 0;
                    document.body.scrollTop = 0;
                    document.querySelectorAll('*').forEach(function(el) {
                        if (el.scrollTop > 0) { el.scrollTop = 0; }
                    });
                    """
                    SharedWebViewProvider.shared.webView.evaluateJavaScript(js, completionHandler: nil)
                }) {
                    Image(systemName: "arrow.up.to.line")
                        .padding()
                        .foregroundColor(refreshButtonColor)
                }
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
                WebView(url: targetURL, loadError: $loadError)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .ignoresSafeArea(.keyboard)

                if loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("載入失敗")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Button(action: {
                            loadError = false
                            SharedWebViewProvider.shared.loadWhenReady(url: targetURL)
                        }) {
                            Text("重試")
                                .font(.body)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }

                if !isKeyboardVisible {
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            .frame(height: 81)
                            .frame(maxWidth: .infinity)
                    }
                    .ignoresSafeArea(.container, edges: .bottom)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            // 確保攔截規則就緒後才載入頁面
            SharedWebViewProvider.shared.loadWhenReady(url: targetURL)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                isKeyboardVisible = false
            }
            // 鍵盤收起後自動置頂
            let js = """
            window.scrollTo(0, 0);
            document.documentElement.scrollTop = 0;
            document.body.scrollTop = 0;
            document.querySelectorAll('*').forEach(function(el) {
                if (el.scrollTop > 0) { el.scrollTop = 0; }
            });
            """
            SharedWebViewProvider.shared.webView.evaluateJavaScript(js, completionHandler: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            // 記憶體不足時清除 WebView 快取，釋放資源
            WKWebsiteDataStore.default().removeData(
                ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
                modifiedSince: .distantPast
            ) {}
        }
        .statusBarHidden(true)
    }
}

#Preview {
    ContentView()
}

