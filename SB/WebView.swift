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

        // 注入 JS：停用長按選取、右鍵選單、文字選取等干擾遊戲的行為
        let gameOptimizeJS = """
        document.addEventListener('contextmenu', function(e) { e.preventDefault(); });
        document.addEventListener('selectstart', function(e) { e.preventDefault(); });
        document.documentElement.style.webkitUserSelect = 'none';
        document.documentElement.style.webkitTouchCallout = 'none';
        """
        let userScript = WKUserScript(
            source: gameOptimizeJS,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(userScript)

        return config
    }

    /// 編譯並加入廣告/追蹤器攔截規則到 WebView configuration
    static func applyContentBlocker(to configuration: WKWebViewConfiguration, completion: @escaping () -> Void) {
        // 攔截規則：阻擋常見廣告、追蹤器、分析腳本的網域
        let rules = """
        [
            {
                "trigger": { "url-filter": ".*", "resource-type": ["popup"] },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*googlesyndication\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*doubleclick\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*google-analytics\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*googletagmanager\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*googletagservices\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*adservice\\\\.google\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*facebook\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*facebook\\\\.com/tr" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*connect\\\\.facebook\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*ads-twitter\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*analytics\\\\.twitter\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*scorecardresearch\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*amazon-adsystem\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*adnxs\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*rubiconproject\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*pubmatic\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*moatads\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*hotjar\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*clarity\\\\.ms" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*criteo\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*outbrain\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*taboola\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*quantserve\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*adsrvr\\\\.org" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*demdex\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*omtrdc\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*mixpanel\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*segment\\\\.io" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*segment\\\\.com/analytics" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*newrelic\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*nr-data\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*sentry\\\\.io" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*popads\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*popcash\\\\.net" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*propellerads\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*exoclick\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*juicyads\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*trafficjunky\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*adcolony\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*unity3d\\\\.com/ads" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*unityads\\\\.unity3d\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*applovin\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*vungle\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*chartboost\\\\.com" },
                "action": { "type": "block" }
            },
            {
                "trigger": { "url-filter": ".*inmobi\\\\.com" },
                "action": { "type": "block" }
            }
        ]
        """

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "ContentBlocker",
            encodedContentRuleList: rules
        ) { ruleList, error in
            if let ruleList = ruleList {
                configuration.userContentController.add(ruleList)
            }
            completion()
        }
    }
}

// 可重用的單一 WKWebView 提供者
final class SharedWebViewProvider {
    static let shared = SharedWebViewProvider()

    let webView: WKWebView
    /// 攔截規則就緒後要執行的載入閉包
    private var pendingLoad: (() -> Void)?
    private var contentBlockerReady = false

    private init() {
        let configuration = SharedWebKit.makeConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)

        // 非同步載入廣告/追蹤器攔截規則
        SharedWebKit.applyContentBlocker(to: configuration) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.contentBlockerReady = true
                // 規則就緒後，執行等待中的載入
                self.pendingLoad?()
                self.pendingLoad = nil
            }
        }

        // 視覺與互動優化
        webView.scrollView.decelerationRate = .normal
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isMultipleTouchEnabled = true
        if #available(iOS 15.0, *) {
            webView.pageZoom = 1.0
        }
        // 關閉滾動與縮放
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    /// 確保攔截規則就緒後才載入頁面
    func loadWhenReady(url: URL) {
        let load = { [weak self] in
            let request = URLRequest(url: url)
            self?.webView.load(request)
        }
        if contentBlockerReady {
            load()
        } else {
            pendingLoad = load
        }
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
            SharedWebViewProvider.shared.loadWhenReady(url: url)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    }
}
