import SwiftUI
import WebKit

// 共用的 WebKit 資源池，讓 cookie / session / 快取可被重用
private final class SharedWebKit {

    static func makeConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        // 偏好設定
        let prefs = WKPreferences()
        prefs.javaScriptCanOpenWindowsAutomatically = false
        config.preferences = prefs

        // 媒體播放（依需求調整）
        config.allowsInlineMediaPlayback = true
        if #available(iOS 14.0, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
            config.limitsNavigationsToAppBoundDomains = false
        }

        // 使用預設資料儲存（支援快取 / cookie）
        config.websiteDataStore = .default()

        return config
    }
}

// 可重用的單一 WKWebView 提供者
final class SharedWebViewProvider {
    static let shared = SharedWebViewProvider()

    let webView: WKWebView

    private init() {
        let configuration = SharedWebKit.makeConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)

        // 視覺與互動優化
        webView.scrollView.decelerationRate = .normal
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isMultipleTouchEnabled = true
        if #available(iOS 15.0, *) {
            webView.pageZoom = 1.0 // Restore content scale to 100%
        }
        // 關閉滾動與縮放
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        // 嘗試關閉手勢縮放（pinch）
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}

extension SharedWebViewProvider {
    /// 輕量暖機：若尚未載入任何頁面，先載入一個輕量頁面以建立連線/快取
    func warmupIfNeeded(with url: URL) {
        // 僅在目前尚未有任何已載入 URL 時執行
        guard webView.url == nil else { return }
        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 30
        )
        webView.load(request)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = SharedWebViewProvider.shared.webView
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 僅在 URL 不同時才載入，避免每次 SwiftUI 更新都 reload
        if uiView.url != url {
            let request = URLRequest(
                url: url,
                cachePolicy: .returnCacheDataElseLoad, // 先用快取，無快取再走網路
                timeoutInterval: 30
            )
            uiView.load(request)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    }
}
