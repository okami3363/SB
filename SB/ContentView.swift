import SwiftUI
import WebKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isKeyboardVisible = false
    @State private var loadError = false
    @State private var saveFeedback: Bool?
    @State private var showBottomButtons = false
    @State private var hideButtonsTask: DispatchWorkItem?

    private let targetURL = URL(string: "https://www.ero-labs.com/zh/cloud_game.html?id=47&connect_type=1&connection_id=28")!

    var navBackground: Color {
        colorScheme == .dark ? .black : Color(.systemGray6)
    }

    var refreshButtonColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private func revealBottomButtons() {
        hideButtonsTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            showBottomButtons = true
        }
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.25)) {
                showBottomButtons = false
            }
        }
        hideButtonsTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }

    var body: some View {
        ZStack {
            WebView(url: targetURL, loadError: $loadError)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 60)
                Spacer()
            }
            .ignoresSafeArea(.container, edges: .top)

            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .top) {
                    Spacer()
                    HStack {
                        Button(action: {
                            SharedWebViewProvider.shared.takeScreenshot(topMaskHeight: 60, bottomMaskHeight: 80) { image in
                                guard let image else { return }
                                SharedWebViewProvider.shared.saveToPhotos(image) { success in
                                    withAnimation { saveFeedback = success }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { saveFeedback = nil }
                                    }
                                }
                            }
                            revealBottomButtons()
                        }) {
                            Image(systemName: "camera")
                                .padding()
                                .foregroundColor(.white)
                        }
                        Button(action: {
                            let webView = SharedWebViewProvider.shared.webView
                            if webView.url != nil {
                                webView.reload()
                            } else {
                                let request = URLRequest(url: targetURL)
                                SharedWebViewProvider.shared.webView.load(request)
                            }
                            revealBottomButtons()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .padding()
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(showBottomButtons ? 1 : 0)
                    .allowsHitTesting(showBottomButtons)
                }
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .contentShape(Rectangle())
                .onTapGesture {
                    revealBottomButtons()
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)

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

            // 儲存結果回饋
            if let success = saveFeedback {
                VStack(spacing: 8) {
                    Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(success ? .green : .red)
                    Text(success ? "已儲存" : "儲存失敗")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
                .transition(.opacity)
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

