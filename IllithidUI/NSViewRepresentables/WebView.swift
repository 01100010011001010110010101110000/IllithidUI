//
// WebView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/13/2020
//

import Combine
import SwiftUI
import WebKit

struct WebView: View {
  @ObservedObject fileprivate var webView: _WebView

  private let configuration: WKWebViewConfiguration = .init()

  init(url: URL) {
    webView = .init(url: url, configuration: .init())
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.websiteDataStore = .nonPersistent() // Web views are "private"
  }

  var body: some View {
    _WebViewRepresentable(view: webView)
  }
}

final private class _WebViewRepresentable: NSViewRepresentable {
  let view: _WebView

  init(view: _WebView) {
    self.view = view
  }

  func makeNSView(context: NSViewRepresentableContext<_WebViewRepresentable>) -> _WebView {
    view
  }

  func updateNSView(_ nsView: _WebView, context: NSViewRepresentableContext<_WebViewRepresentable>) {}

  static func dismantleNSView(_ nsView: _WebView, coordinator: ()) {
    nsView.load(URLRequest(url: URL(string:"about:blank")!))
    nsView.cancel()
  }
}

final private class _WebView: WKWebView, ObservableObject {
  @Published var pageTitle: String? = nil
  @Published var loadProgress: Double = .zero

  private var cancelBag: [AnyCancellable] = []

  convenience init(url: URL, configuration: WKWebViewConfiguration) {
    self.init(frame: .zero, configuration: configuration)
    self.load(URLRequest(url: url))

    cancelBag.append(self.publisher(for: \.title)
      .receive(on: RunLoop.main)
      .assign(to: \.pageTitle, on: self))
    cancelBag.append(self.publisher(for: \.title)
      .receive(on: RunLoop.main)
      .sink(receiveValue: { [weak self] title in
        self?.window?.tab.title = title ?? (self?.window?.title ?? "")
      }))
    cancelBag.append(self.publisher(for: \.estimatedProgress)
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
    WebView(url: URL(string: "https://reddit.com")! )
  }
}
