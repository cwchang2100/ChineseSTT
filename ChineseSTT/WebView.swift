//
//  WebView.swift
//  ChineseSTT
//
//  Created by Chih-Wei Chang on 2026/11/25.
//

import Foundation
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {

    let webView: WKWebView

    func makeUIView(
        context: Context
    ) -> WKWebView {

        return webView
    }

    func updateUIView(
        _ uiView: WKWebView,
        context: Context
    ) {
        // No update required.
    }
}
