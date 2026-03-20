import UIKit
import WebKit
import SafariServices

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!
    var progressBar: UIProgressView!
    var refreshControl: UIRefreshControl!

    let websiteURL = URL(string: "https://softprosolutions.com/edupro_mobile/index")!
    let allowedDomains: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#080b12")
        setupWebView()
        setupProgressBar()
        setupRefreshControl()
        loadWebsite()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    func setupProgressBar() {
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = UIColor(hex: "#3d7fff")
        view.addSubview(progressBar)
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 3)
        ])
    }

    func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor(hex: "#3d7fff")
        refreshControl.addTarget(self, action: #selector(reloadPage), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
    }
    @objc func reloadPage() { webView.reload(); refreshControl.endRefreshing() }

    func loadWebsite() {
        if Reachability.isConnected() {
            webView.load(URLRequest(url: websiteURL))
        } else {
            if let path = Bundle.main.path(forResource: "offline", ofType: "html") {
                webView.loadFileURL(URL(fileURLWithPath: path), allowingReadAccessTo: URL(fileURLWithPath: path))
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressBar.progress = Float(webView.estimatedProgress)
            progressBar.isHidden = webView.estimatedProgress >= 1
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        let scheme = url.scheme != nil ? url.scheme! : ""
        if scheme == "tel" || scheme == "mailto" || scheme == "sms" {
            UIApplication.shared.open(url); decisionHandler(.cancel); return
        }
        if !allowedDomains.isEmpty, let host = url.host {
            if !allowedDomains.contains(where: { host.contains($0) }) {
                present(SFSafariViewController(url: url), animated: true)
                decisionHandler(.cancel); return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if let path = Bundle.main.path(forResource: "offline", ofType: "html") {
            webView.loadFileURL(URL(fileURLWithPath: path), allowingReadAccessTo: URL(fileURLWithPath: path))
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var n: UInt64 = 0; Scanner(string: h).scanHexInt64(&n)
        self.init(red: CGFloat((n>>16)&0xFF)/255, green: CGFloat((n>>8)&0xFF)/255, blue: CGFloat(n&0xFF)/255, alpha: 1)
    }
}

struct Reachability {
    static func isConnected() -> Bool {
        let sc = SCNetworkReachabilityCreateWithName(nil, "www.apple.com")
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(sc!, &flags)
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }
}
import SystemConfiguration
