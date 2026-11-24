//
//  WebViewController.swift
//  ChineseSTT
//
//  Created by Chih-Wei Chang on 2026/11/25.
//

import Foundation
import WebKit
import Combine

@MainActor
class WebViewController: ObservableObject {

    let webView: WKWebView

    @Published var errorMessage: String = ""

    init() {

        let configuration = WKWebViewConfiguration()

        configuration.defaultWebpagePreferences
            .allowsContentJavaScript = true

        webView = WKWebView(
            frame: .zero,
            configuration: configuration
        )
    }

    // Load a web page
    func loadURL(_ urlString: String) {

        guard let url = URL(string: urlString) else {
            return
        }

        webView.load(URLRequest(url: url))
    }

    // Reload current web page
    func reload() {
        webView.reload()
    }

    // Go back
    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    // Insert text into an HTML field
    func insertText(
        _ text: String,
        selector: String
    ) async {

        let javascript = """
            const element = document.querySelector(selector);

            if (!element) {
                return false;
            }

            if (element.isContentEditable) {
                element.textContent = text;
            } else if (
                element instanceof HTMLInputElement ||
                element instanceof HTMLTextAreaElement
            ) {
                const prototype =
                    element instanceof HTMLTextAreaElement
                    ? HTMLTextAreaElement.prototype
                    : HTMLInputElement.prototype;

                const setter = Object.getOwnPropertyDescriptor(
                    prototype, 'value'
                ).set;

                setter.call(element, text);
            } else {
                return false;
            }

            element.dispatchEvent(
                new Event('input', { bubbles: true })
            );

            element.dispatchEvent(
                new Event('change', { bubbles: true })
            );

            return true;
            """

        do {

            errorMessage = ""

            let result = try await webView.callAsyncJavaScript(
                javascript,
                arguments: [
                    "text": text,
                    "selector": selector
                ],
                in: nil,
                contentWorld: .page
            )

            if result as? Bool == true {
                print("[WEB] Text inserted successfully")
            } else {
                errorMessage = "Target HTML field not found."
            }

        } catch {
            errorMessage = error.localizedDescription
            print("[WEB ERROR] \(error)")
        }
    }
    
    func loadLocalHTML() {

        guard let url = Bundle.main.url(
            forResource: "test",
            withExtension: "html",
            //subdirectory: "Resources"
        ) else {
            return
        }

        webView.loadFileURL(
            url,
            allowingReadAccessTo:
                url.deletingLastPathComponent()
        )
    }
}
