//
// WebView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Combine
import SwiftUI
import WebKit

struct WebView: View {
  @ObservedObject fileprivate var webView: _WebView

  init(url: URL) {
    webView = .init(url: url, configuration: Self.makeConfiguration())
  }

  init(html: String, relativeTo baseUrl: URL?) {
    webView = .init(html: html, relativeTo: baseUrl, configuration: Self.makeConfiguration())
  }

  private static func makeConfiguration() -> WKWebViewConfiguration {
    let configuration: WKWebViewConfiguration = .init()
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.websiteDataStore = .nonPersistent() // Web views are "private"
    return configuration
  }

  var body: some View {
    _WebViewRepresentable(view: webView)
  }
}

private final class _WebViewRepresentable: NSViewRepresentable {
  let view: _WebView

  init(view: _WebView) {
    self.view = view
  }

  func makeNSView(context _: NSViewRepresentableContext<_WebViewRepresentable>) -> _WebView {
    view
  }

  func updateNSView(_: _WebView, context _: NSViewRepresentableContext<_WebViewRepresentable>) {}

  static func dismantleNSView(_ nsView: _WebView, coordinator _: ()) {
    nsView.load(URLRequest(url: URL(string: "about:blank")!))
    nsView.cancel()
  }
}

private final class _WebView: WKWebView, ObservableObject {
  @Published var pageTitle: String? = nil
  @Published var loadProgress: Double = .zero

  private var cancelBag: [AnyCancellable] = []

  convenience init(html: String, relativeTo baseUrl: URL?, configuration: WKWebViewConfiguration) {
    self.init(frame: .zero, configuration: configuration)
    loadHTMLString(html, baseURL: baseUrl)
    observe()
  }

  convenience init(url: URL, configuration: WKWebViewConfiguration) {
    self.init(frame: .zero, configuration: configuration)
    load(URLRequest(url: url))
    observe()
  }

  private func observe() {
    cancelBag.append(publisher(for: \.title)
      .receive(on: RunLoop.main)
      .assign(to: \.pageTitle, on: self))
    cancelBag.append(publisher(for: \.title)
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] title in
        self?.window?.tab.title = title ?? (self?.window?.title ?? "")
      }))
    cancelBag.append(publisher(for: \.estimatedProgress)
      .receive(on: RunLoop.main)
      .assign(to: \.loadProgress, on: self))
  }

  func cancel() {
    while !cancelBag.isEmpty {
      cancelBag.popLast()?.cancel()
    }
  }
}

struct WebView_Previews: PreviewProvider {
  static var previews: some View {
    WebView(url: URL(string: "https://reddit.com")!)
  }
}
