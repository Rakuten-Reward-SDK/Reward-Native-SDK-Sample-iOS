//
//  JSExtension.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 12/11/24.
//

import RakutenRewardNativeSDK
import SwiftUI
import UIKit
import WebKit

struct JSExtensionVCView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> JSExtensionVC {
        let jsExtensionVC = JSExtensionVC()
        return jsExtensionVC
    }
    
    func updateUIViewController(_ uiViewController: JSExtensionVC, context: Context) {
        
    }
}

class JSExtensionVC: UIViewController {
    
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let contentController = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        RewardJS.shared.setupWebView(
            appcode: AppConstant.appcode,
            domain: AppConstant.jsExtensionTestDomain,
            config: config) { _ in
        }
        
        webView = WKWebView(frame: .zero, configuration: config)
        view.addSubview(webView)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        
        let urlString = AppConstant.jsTestPageUrl
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        webView?.load(request)
    }
}
